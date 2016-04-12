# coding: utf-8

require 'importer_base'

module StockDB
  class KDBImporter

    KDB_URL = 'http://k-db.com/stocks/'
    WORKER_COUNTS = 3

    include ImporterBase

    def initialize
      @client = HTTPClient.new
      @stock_cache = {}
      @mutex = Mutex.new
    end

    def import(start_date, end_date)
      pool = Thread.pool(WORKER_COUNTS)
      end_date.downto(start_date) do |date|
        next if date.wday == 0 || date.wday == 6
        pool.process { import_data(date) }
      end
      pool.shutdown
    end

    private

    def import_data(date)
      puts "import #{date}"
      data = retry_five_times { fetch_csv(date) }
      return unless data
      stocks = import_stocks(data)
      ActiveRecord::Base.transaction do
        data.each_line do |line|
          import_rates(date, line, stocks)
        end
      end
    rescue
      puts '*** import failed.'
      puts $!
    end

    def fetch_csv(date)
      url = "#{KDB_URL}/#{date.strftime("%Y-%m-%d")}?download=csv"
      res = @client.get(url, :follow_redirect => true)
      return nil if res.status == 404
      return nil unless res.headers['Content-Disposition'] =~ /stocks_#{date.strftime("%Y-%m-%d")}\.csv/
      raise("#{res.status} #{res.body.to_s}") unless res.status == 200 # for retry
      res.body
    end

    def import_stocks(data)
      data.lines.each_with_object({}) do |line, r|
        steps = parse_line(line)
        next unless steps
        stock_info = { 'dataset_code' => steps[0], 'name' => steps[2] }
        r[stock_info['dataset_code']] = find_or_create_stock(stock_info)
      end
    end

    def import_rates(date, line, stocks)
      steps = parse_line(line)
      return unless steps
      return if steps[7].to_i == 0

      stock = stocks[steps[0]]
      find_or_create_rate(stock.id, {
        'date'   => date,
        'open'   => steps[3].to_f,
        'high'   => steps[4].to_f,
        'low'    => steps[5].to_f,
        'close'  => steps[6].to_f,
        'volume' => steps[7].to_i
      })
    end

    def parse_line(line)
      steps = line.encode("UTF-8", "Shift_JIS").split(',')
      return nil if steps.length < 9
      return nil unless steps[0] =~ /(\d+)\-/
      return [$1] + steps[1..-1]
    end

    def find_or_create_stock(stock_info, stock_type='stock')
      @mutex.synchronize do
        code = stock_info['dataset_code']
        return @stock_cache[code] if @stock_cache.include? code
        ActiveRecord::Base.transaction do
          @stock_cache[code] = super
        end
      end
    end

  end
end
