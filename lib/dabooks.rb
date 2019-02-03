require 'stringio'
require 'date'
require 'dedent'
require 'value_semantics'

require 'dabooks/filter'
require 'dabooks/formatter'
require 'dabooks/table_formatter'
require 'dabooks/parser'

module Dabooks
  class Amount
    include Comparable
    include ValueSemantics.for_attributes {
      cents Either(Integer, nil), coerce: true
    }

    def self.coerce_cents(value)
      if value.is_a?(String)
        Integer(value, 10)
      else
        value
      end
    end

    def +(other)
      with(cents: cents + other.cents)
    end

    def -(other)
      with(cents: cents - other.cents)
    end

    def -@
      with(cents: -cents)
    end

    def <=>(other)
      cents <=> other.cents
    end

    def fixed?
      not @cents.nil?
    end

    def zero?
      @cents == 0
    end

    def inspect
      "<Amount #{@cents.inspect}>"
    end

    def self.[](cents)
      new(cents: cents)
    end

    def self.unfixed
      new(cents: nil)
    end
  end

  class Account
    include ValueSemantics.for_attributes {
      name String
    }

    def self.[](name)
      new(name: name)
    end

    def depth
      name.count(':')
    end

    def parent
      if name.include?(':')
        parent_name, _, _ = name.rpartition(':')
        self.class.new(name: parent_name)
      else
        nil
      end
    end

    def include?(other)
      other.name.start_with?(name)
    end

    def last_component
      name.rpartition(':').last
    end

    def <=>(other)
      name <=> other.name
    end
  end

  class Entry
    include ValueSemantics.for_attributes {
      account Account
      amount Amount
    }
  end

  class Transaction
    include ValueSemantics.for_attributes {
      date Date
      description String
      entries ArrayOf(Entry)
    }

    def balance
      @balance ||=
        if fixed?
          entries.map(&:amount).reduce(Amount[0], :+)
        else
          Amount[0]
        end
    end

    def balanced?
      balance.zero?
    end

    def fixed?
      entries.map(&:amount).all?(&:fixed?)
    end

    def fixed_balance
      @fixed_balance ||= entries
        .map(&:amount)
        .select(&:fixed?)
        .reduce(Amount[0], :+)
    end

    def normalized_entries
      return entries if fixed?

      entries.map do |e|
        if e.amount.fixed?
          e
        else
          Entry.new(account: e.account, amount: -fixed_balance)
        end
      end
    end
  end

  class TransactionSet
    include Enumerable
    include ValueSemantics.for_attributes {
      transactions ArrayOf(Transaction)
    }

    def each(&block)
      transactions.each(&block)
    end
  end

end
