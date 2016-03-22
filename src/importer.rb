# coding: utf-8

require 'thread/pool'
require "db/configuration"
require "db/migrate/table_builder"
require "models/stock"
require "models/rate"
require 'config/quandl_configuration'

module StockDB
  class Importer

    def import
      fetch_stocks do |stock_info|
        p stock_info
        ActiveRecord::Base.transaction do
          stock = find_or_create_stock(stock_info)
          fetch_rate(stock).each do |rate_info|
            p rate_info
            find_or_create_rate(stock.id, rate_info)
          end
        end
      end
    end

    private

    def fetch_stocks
      page = 1
      loop do
        retry_five_times do
          options = {params: { page: page }}
          stocks = Quandl::Database.get('TSE').datasets(options)
          stocks.each do |stock|
            yield stock
          end
          return if stocks.empty?
        end
        page+=1
      end
    end
    def fetch_rate(stock)
      retry_five_times do
        Quandl::Dataset.get("TSE/#{stock.code}")
          .data(params: { rows: 500 })
      end
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
    end

    def find_or_create_stock(stok_info)
      code = stok_info['dataset_code'].to_i
      Stock.find_or_create_by(code: code) do |stock|
        stock.name = stok_info['name']
      end
    end

    def find_or_create_rate(stock_id, rate_info)
      return unless valid_rate?(rate_info)
      attributes = { stock_id:stock_id, date: rate_info['date'] }
      Rate.find_or_create_by(attributes) do |rate|
        rate.open   = rate_info['open']
        rate.close  = rate_info['close']
        rate.high   = rate_info['high']
        rate.low    = rate_info['low']
        rate.volume = rate_info['volume'].to_i || 0
      end
    end

    def valid_rate?(rate_info)
      rate_info['open'] && rate_info['close'] \
        && rate_info['high'] && rate_info['low'] \
        && rate_info['date']
    end

  end
end

StockDB::TableBuilder.new.build_tables
StockDB::Importer.new.import
