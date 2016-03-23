# coding: utf-8

require 'importer_base'
require 'config/quandl_configuration'
require 'zip'

module StockDB
  class QuandlImporter

    TSE_CODE = 'TSE'
    TSE_CODE_URL = 'https://www.quandl.com/api/v3/databases/TSE/codes'
    NIKKEI_CODE = 'NIKKEI'

    WORKER_COUNTS = 5
    RETRIEVE_COUNT = 500

    include ImporterBase


    def import
      import_nikkei
      import_all_stocks
    end

    def import_all_stocks
      pool = Thread.pool(WORKER_COUNTS)
      fetch_stocks do |stock_info|
        pool.process { import_rates(stock_info) }
      end
      pool.shutdown
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

  end
end

StockDB::TableBuilder.new.build_tables
StockDB::QuandlImporter.new.import
