module Dabooks
  class Filter
    def initialize(start_date, end_date)
      @start_date = start_date
      @end_date = end_date
    end

    def include?(transaction)
      return false if @start_date && transaction.date < @start_date
      return false if @end_date && transaction.date > @end_date
      true
    end

    def self.from_dsl(dsl)
      start_date = nil
      end_date = nil

      dsl.split.each_slice(2) do |(keyword, value)|
        case keyword.downcase
        when 'from', 'starting' then start_date = parse_date(value)
        when 'until', 'to', 'ending' then until_date = parse_date(value)
        end
      end

      new(start_date, end_date)
    end

    def self.parse_date(date_string)
      case date_string.downcase
      when 'today' then Date.today
      else Date.iso8601(date_string)
      end
    end
  end
end
