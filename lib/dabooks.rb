require 'stringio'
require 'date'
require 'adamantium'

require 'dabooks/filter'
require 'dabooks/formatter'
require 'dabooks/table_formatter'
require 'dabooks/parser'

module Dabooks
  class Amount
    include Adamantium
    attr_reader :cents

    def initialize(cents=nil)
      @cents = cents ? Integer(cents) : nil
    end

    def +(other)
      transform { @cents += other.cents }
    end

    def -(other)
      transform { @cents -= other.cents }
    end

    def -@
      transform { @cents = -@cents }
    end

    def hash
      cents.hash
    end

    def eql?(other)
      other.is_a?(self.class) && cents == other.cents
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

    def self.[](*args)
      new(*args)
    end

    def self.unfixed
      new
    end
  end

  class Account
    include Adamantium
    attr_reader :name

    def initialize(name)
      @name = name
    end

    def self.[](*args)
      new(*args)
    end

    def hash
      name.hash
    end

    def depth
      name.count(':')
    end

    def parent
      if name.include?(':')
        parent_name, _, _ = name.rpartition(':')
        Account.new(parent_name)
      else
        nil
      end
    end

    def last_component
      @name.rpartition(':').last
    end

    def eql?(other)
      other.is_a?(self.class) && other.name == name
    end

    def ==(other)
      eql?(other)
    end

    def <=>(other)
      name <=> other.name
    end

    def inspect
      "<Account #{@name.inspect}>"
    end
  end

  class Entry
    include Adamantium
    attr_reader :account, :amount

    def initialize(account, amount)
      @account = account
      @amount = amount
    end

    def inspect
      "<Entry #{@account.inspect} #{@amount.inspect}>"
    end
  end

  class Transaction
    include Adamantium
    attr_reader :date, :entries, :description

    def initialize(date, description, entries)
      @date = date
      @description = description
      @entries = entries
    end

    def balance
      Amount.new(
        if fixed?
          entries.map(&:amount).map(&:cents).reduce(0, :+)
        else
          0
        end
      )
    end
    memoize :balance

    def balanced?
      balance.cents == 0
    end
    memoize :balanced?

    def fixed?
      entries.map(&:amount).all?(&:fixed?)
    end
    memoize :fixed?

    def fixed_balance
      Amount.new(
        entries
          .map(&:amount)
          .select(&:fixed?)
          .map(&:cents)
          .reduce(0, :+)
      )
    end
    memoize :fixed_balance

    def normalized_entries
      return entries if fixed?

      entries.map do |e|
        e.amount.fixed? ? e : Entry.new(e.account, -fixed_balance)
      end
    end
    memoize :normalized_entries
  end

  class TransactionSet
    include Adamantium
    include Enumerable
    attr_reader :transactions

    def initialize(transactions)
      @transactions = transactions
    end

    def each
      @transactions.each{ |t| yield t }
    end
  end

end
