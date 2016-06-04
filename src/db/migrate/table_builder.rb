# coding: utf-8

require "db/configuration"

module StockDB

  class TableBuilder

    def build_tables
      build_stocks_table unless connection.table_exists? 'stocks'
      build_rates_table  unless connection.table_exists? 'rates'
      build_stock_lendings_table unless connection.table_exists? 'stock_lendings'
    end

    def build_stocks_table
      create_table :stocks do |t|
        t.column :code       , :string
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

    def build_stock_lendings_table
      create_table :stock_lendings do |t|
        t.column :stock_id, :integer, null:false
        t.column :date    , :date,    null:false


        t.column :loan_new,          :integer, null:false #融資新規
        t.column :loan_repayment,    :integer, null:false #融資返済
        t.column :loan_balance,      :integer, null:false #融資残高
        t.column :lending_new,       :integer, null:false #貸株新規
        t.column :lending_repayment, :integer, null:false #貸株返済
        t.column :lending_balance,   :integer, null:false #貸株残高

        t.column :balance_price,   :integer             #貸借値段（円）
        t.column :exceeded,        :integer             #貸株超過株数（株・口）
        t.column :highest_negative_interest_per_diem,
          :decimal, precision:15, scale:3               #最高料率（円）
        t.column :negative_interest_per_diem,
          :decimal, precision:15, scale:3               #当日品貸料率（円）
        t.column :lending_days,    :integer             #当日品貸日数
        t.column :negative_interest_per_diem_yesterday,
          :decimal, precision:15, scale:3               #前日品貸料率（円）

        t.column :remarks,         :string       #備考
        t.column :regulation,      :string       #規制

        t.foreign_key :stocks, on_delete: :cascade, on_update: :cascade
      end
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
