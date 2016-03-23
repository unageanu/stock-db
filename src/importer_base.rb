# coding: utf-8

require 'thread'
require 'thread/pool'
require "db/configuration"
require "db/migrate/table_builder"
require "models/stock"
require "models/rate"
require 'httpclient'

module StockDB
  module ImporterBase

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
