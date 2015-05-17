require 'stringio'
require 'date'
require 'adamantium'

require 'dabooks/formatter'
require 'dabooks/parser'

module Dabooks
  class Amount
    include Adamantium
    attr_reader :cents

    def initialize(cents)
      @cents = Integer(cents)
    end

    def fixed?; true; end
  end

  class PlaceholderAmount
    include Adamantium
    def cents; 0; end
    def fixed?; false; end
  end

  class Account
    include Adamantium
    attr_reader :name

    def initialize(name)
      @name = name
    end
  end

  class Entry
    include Adamantium
    attr_reader :account, :amount

    def initialize(account, amount)
      @account = account
      @amount = amount
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
  end

  class TransactionSet
    include Adamantium
    attr_reader :transactions

    def initialize(transactions)
      @transactions = transactions
    end
  end

end
