# coding: utf-8

require 'importer_base'

module StockDB
  class StockLendingImporter

    JSF_URL = 'http://www.jsf.co.jp/de/stock/dlcsv.php'
    WORKER_COUNTS = 3

    include ImporterBase

    def initialize
      @client = HTTPClient.new
    end

    def import(start_date, end_date)
      pool = Thread.pool(WORKER_COUNTS)
      each_weekday(start_date, end_date) do |date|
        pool.process { import_data(date) }
      end
      pool.shutdown
    end

    private

    def import_data(date)
      puts "import #{date}"
      data = retry_five_times do
        merge_data(fetch_csv(date, 'pcsl'), fetch_csv(date, 'balance'))
      end
      return unless data
      stocks = import_stocks(data)
      ActiveRecord::Base.transaction do
        data.values.each do |stock_lending|
          import_stock_lendings(date, stock_lending, stocks)
        end
      end
    rescue
      puts '*** import failed.'
      puts $!
    end

    def fetch_csv(date, target)
      url = "#{JSF_URL}?target=#{target}&date=#{date.strftime("%Y-%m-%d")}"
      res = @client.get(url, :follow_redirect => true)
      return nil if res.status == 404
      raise("#{res.status} #{res.body.to_s}") unless res.status == 200 # for retry
      res.body
    end

    def import_stocks(data)
      data.values.each_with_object({}) do |d, r|
        r[d['dataset_code']] = find_or_create_stock(d)
      end
    end

    def import_stock_lendings(date, info, stocks)
      stock = stocks[info['dataset_code']]
      attributes = { stock_id:stock.id, date: date }
      StockLending.find_or_create_by(attributes) do |lending|
        info.keys.each do |k|
          next if k == "name" || k == "dataset_code"
          lending.send("#{k}=", info[k])
        end
      end
    end

    def merge_data(pcsl, balance)
      return nil if pcsl.nil? || balance.nil?
      map = pcsl.lines.each_with_object({}) do |line, r|
        steps = line.encode("UTF-8", "Shift_JIS").split(',')
        next unless steps[0] =~ /\d+/
        r[steps[2]] = {
          'dataset_code'  => steps[2],
          'name'          => steps[3],
          'balance_price' => steps[5].to_i,
          'exceeded'      => steps[6].to_i,
          'highest_negative_interest_per_diem' => steps[7].to_f,
          'negative_interest_per_diem' => steps[8] =~ /[\d\.\-]+/ ? steps[8].to_f : nil,
          'lending_days'  => steps[9] =~ /[\d\.\-]+/ ? steps[9].to_i : nil,
          'negative_interest_per_diem_yesterday' => steps[10] =~ /[\d\.\-]+/ ? steps[10].to_f : nil,
          'remarks'       => steps[11],
          'regulation'    => steps[12]
        }
      end
      balance.lines.each_with_object(map) do |line, r|
        steps = line.encode("UTF-8", "Shift_JIS").split(',')
        next unless steps[1] =~ /\d+/
        (r[steps[2]] || r[steps[2]] = {}).merge!({
          'dataset_code'      => steps[2],
          'name'              => steps[3],
          'loan_new'          => steps[5].to_i,
          'loan_repayment'    => steps[6].to_i,
          'loan_balance'      => steps[7].to_i,
          'lending_new'       => steps[8].to_i,
          'lending_repayment' => steps[9].to_i,
          'lending_balance'   => steps[10].to_i
        })
      end
    end

  end
end

StockDB::TableBuilder.new.build_tables
StockDB::StockLendingImporter.new.import(Date.parse(ARGV[0]), Date.parse(ARGV[1]))
