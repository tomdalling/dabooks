module Dabooks

  class Formatter
    include Adamantium

    def initialize(transaction_set)
      @transaction_set = transaction_set
    end

    def write_to(io)
      @transaction_set.transactions.each do |trans|
        write_transaction(trans, io)
        io.write("\n")
      end
    end

    def write_transaction(transaction, io)
      io.puts(format_transaction_header(transaction))
      transaction.entries.each do |entry|
        io.puts(format_entry(entry))
      end
    end

    def max_account_width
      @transaction_set.transactions.flat_map do |trans|
        trans.entries.map { |entry| format_account(entry.account).length }
      end.max
    end
    memoize :max_account_width

    def max_amount_width
      @transaction_set.transactions.flat_map do |trans|
        trans.entries.map { |entry| format_amount(entry.amount).length }
      end.max
    end
    memoize :max_amount_width

    def format_transaction_header(transaction)
      "#{transaction.date} #{transaction.description}"
    end

    def format_entry(entry)
      account = format_account(entry.account).ljust(max_account_width, ' ')
      amount = ('$' + format_amount(entry.amount)).rjust(max_amount_width, ' ')
      "  #{account}  #{amount}"
    end

    def format_account(*args)
      self.class.format_account(*args)
    end

    def format_amount(*args)
      self.class.format_amount(*args)
    end

    def self.format_account(account)
      account.name
    end

    def self.format_amount(amount)
      return '_____' unless amount.fixed?

      sign = amount.cents >= 0 ? '' : '-'
      cents = (amount.cents.abs % 100).to_s.rjust(2, '0')
      dollars = (amount.cents.abs / 100).floor.to_s
      commad_dollars = dollars
        .chars
        .reverse
        .each_slice(3)
        .map{ |slice| slice.join }
        .join(',')
        .reverse

      "#{sign}#{commad_dollars}.#{cents}"
    end
  end

end
