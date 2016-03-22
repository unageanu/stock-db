# coding: utf-8

require "db/configuration"

module StockDB

  class TableBuilder

    def build_tables
      build_stocks_table unless connection.table_exists? 'stocks'
      build_rates_table  unless connection.table_exists? 'rates'
    end

    def build_stocks_table
      create_table :stocks do |t|
        t.column :code       , :integer
        t.column :name       , :string

        t.index :code, unique: true
      end
    end

    def build_rates_table
      create_table :rates do |t|
        t.column :stock_id, :integer, null:false
        t.column :date    , :date,    null:false
        t.column :open    , :decimal, null:false, precision:15, scale:3
        t.column :close   , :decimal, null:false, precision:15, scale:3
        t.column :high    , :decimal, null:false, precision:15, scale:3
        t.column :low     , :decimal, null:false, precision:15, scale:3
        t.column :volume  , :integer, null:false, default: 0

        t.foreign_key :stocks, on_delete: :cascade, on_update: :cascade
      end
      add_index(:rates, [:stock_id, :date],
        name:'stock_id_date_index', unique: true)
    end

    private

    def create_table(*args, &block)
      ActiveRecord::Migration.create_table(*args, &block)
    end
    def add_index(*args, &block)
      ActiveRecord::Migration.add_index(*args, &block)
    end
    def connection
      ActiveRecord::Base.connection
    end
  end

end
