# coding: utf-8

require 'thread'
require 'thread/pool'
require "db/configuration"
require "db/migrate/table_builder"
require "models/stock"
require "models/rate"
require 'config/quandl_configuration'
require 'httpclient'
require 'zip'
require "stringio"

module StockDB
  class Importer

    TSE_CODE = 'TSE'
    TSE_CODE_URL = 'https://www.quandl.com/api/v3/databases/TSE/codes'
    NIKKEI_CODE = 'NIKKEI'

    WORKER_COUNTS = 5
    RETRIEVE_COUNT = 500

    def initialize
      @pool = Thread.pool(WORKER_COUNTS)
    end

    def import
      import_nikkei
      import_all_stocks
    end

    def import_all_stocks
      fetch_stocks do |stock_info|
        @pool.process { import_rates(stock_info) }
      end
      @pool.shutdown
    end

    def import_nikkei
      import_rates({
        'dataset_code'=>'INDEX-Nikkei-Index',
        'name'=>'The Nikkei Stock Average'
      }, NIKKEI_CODE)
    end

    private

    def fetch_stocks
      client = HTTPClient.new
      res = client.get("#{TSE_CODE_URL}?api_key=#{Quandl::ApiConfig.api_key}",
        :follow_redirect => true)
      Zip::InputStream.open(StringIO.new(res.body, 'r+')) do |io|
        io.get_next_entry
        io.read.each_line do |line|
          next unless line =~ %r{TSE/([^,]+),\"?([^\"]+)}
          yield 'dataset_code'=>$1, 'name'=>$2.strip
        end
      end
    end

    def import_rates(stock_info, database_code = TSE_CODE)
      puts "import #{stock_info['dataset_code']} #{stock_info['name']}"
      ActiveRecord::Base.transaction do
        stock = find_or_create_stock(stock_info)
        fetch_rate(stock, database_code).each do |rate_info|
          find_or_create_rate(stock.id, rate_info)
        end
      end
    rescue
      puts '*** import failed.'
      puts $!
    end

    def fetch_rate(stock, database_code = TSE_CODE)
      retry_five_times do
        data = Quandl::Dataset.get("#{database_code}/#{stock.code}")
          .data(params: { rows: RETRIEVE_COUNT })
      end || []
    end

    def retry_five_times
      5.times do |i|
        begin
          return yield
        rescue
          puts "** retry #{i}"
          puts $!
        end
      end
      return nil
    end

    def find_or_create_stock(stok_info)
      code = stok_info['dataset_code']
      Stock.find_or_create_by(code: code) do |stock|
        stock.name = stok_info['name']
      end
    end

    def find_or_create_rate(stock_id, rate_info)
      return unless valid_rate?(rate_info)
      #puts "  #{rate_info['date']} #{rate_info['open']} #{rate_info['close']}"
      attributes = { stock_id:stock_id, date: rate_info['date'] }
      Rate.find_or_create_by(attributes) do |rate|
        rate.open   = rate_info['open']  || rate_info['open_price']
        rate.close  = rate_info['close'] || rate_info['close_price']
        rate.high   = rate_info['high']  || rate_info['high_price']
        rate.low    = rate_info['low']   || rate_info['low_price']
        rate.volume = rate_info['volume'].to_i || 0
      end
    end

    def valid_rate?(rate_info)
      ( rate_info['open']     || rate_info['open_price'] )  \
      && ( rate_info['close'] || rate_info['close_price'] ) \
      && ( rate_info['high']  || rate_info['high_price'] )  \
      && ( rate_info['low']   || rate_info['low_price'] )   \
      && rate_info['date']
    end

  end
end

StockDB::TableBuilder.new.build_tables
StockDB::Importer.new.import
