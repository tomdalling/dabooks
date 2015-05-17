module Dabooks

  class Formatter
    include Adamantium

    def initialize(transaction_set)
      @transaction_set = transaction_set
    end

    def write_to(io)
      @transaction_set.transactions.each do |trans|
        write_transaction(trans)
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
      amount = format_amount(entry.amount).rjust(max_amount_width, ' ')
      "#{account}  $#{amount}"
    end

    def format_account(account)
      account.name
    end

    def format_amount(amount)
      if amount.is_a? PlaceholderAmount
        "__.__"
      else
        sign = amount.cents >= 0 ? '' : '-'
        dollars = (amount.cents.abs / 100).floor.to_s
        cents = (amount.cents.abs % 100).to_s.rjust(2, '0')
        "#{sign}#{dollars}.#{cents}"
      end
    end
  end

end
