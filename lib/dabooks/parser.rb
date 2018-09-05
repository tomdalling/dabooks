module Dabooks
  class Parser
    Error = Class.new(StandardError)

    def self.parse(io)
      Parser.new(io).transaction_set
    end

    def initialize(io)
      @io = io
      @line_no = 0
      @line = ''
      @ungotten_lines = []
    end

    def transaction_set
      transactions = []
      while t = next_transaction
        transactions << t
      end
      return TransactionSet.new(transactions: transactions)
    end

    private

      def next_transaction
        header_line = next_line
        return nil unless header_line

        date_str, _, description = header_line.partition(/\s+/)
        date = parse_date(date_str)
        entries = parse_entries

        Transaction.new(
          date: date,
          description: description,
          entries: entries,
        )
      end

      def next_line
        return @ungotten_lines.pop if @ungotten_lines.size > 0

        loop do
          return nil if @io.eof?

          @line = @io.readline.chomp
          @line_no += 1

          line = @line.split('#').first || '' # remove comments
          line = line.rstrip # remove whitespace on the end

          error 'Found a tab character (not allowed)' if line.include?("\t")

          return line unless line == ''
        end
      end

      def unget_line(line)
        @ungotten_lines << line
      end

      def parse_date(str)
        Date.iso8601(str)
      rescue ArgumentError
        error 'Invalid date', str
      end

      def parse_entries
        entries = []
        while e = parse_entry
          entries << e
        end
        entries
      end

      def parse_entry
        line = next_line
        return nil unless line

        unless line.start_with?(' ')
          # not an entry. accidentally read off the end of the transaction
          unget_line(line)
          return nil
        end

        account_name, _, amount_str = line.rpartition(/\s+/)
        Entry.new(
          account: parse_account(account_name.strip),
          amount: parse_amount(amount_str),
        )
      end

      def parse_account(name)
        Account[name]
      end

      def parse_amount(amount)
        # $____ or ____
        return Amount.unfixed if amount.strip =~ /^\$?_+$/

        split_idx = amount.index(/[0-9\-.]/)
        error 'Invalid amount', amount unless split_idx
        #currency = amount[0, split_idx]
        number = amount[split_idx, amount.length - split_idx]

        error 'Invalid amount', amount unless number.count('.') <= 1
        number << '.00' if number.count('.') == 0
        number.gsub!(/,/, '') #ignore commas
        dollars, _, cents = number.partition('.')
        sign = dollars.start_with?('-') ? -1 : 1

        fail if cents.size != 2
        cents = cents.gsub(/^0+/, '')
        cents = '0' if cents == ''

        Amount[Integer(dollars)*100 + sign*Integer(cents)]
      end

      def error(msg, related_text=nil)
        rt = related_text ? ' ' + related_text.inspect : ''
        raise Error, "#{msg}#{rt} -- line #{@line_no}: #{@line}"
      end
  end
end
