require 'zlib'
require 'ox'

module Dabooks
class CLI::GnucashCommand
  DETAILS = {
    description: 'Converts GnuCash files into dabooks format.',
    usage: 'dabooks gnucash <filename>',
    schema: {},
  }

  def initialize(clargs)
    @argv = clargs.free_args
  end

  def run
    @argv.map{ |file| convert(file) }
  end

  def convert(file)
    doc = parse(file)
    transaction_set = xform(doc)
    print_ts(transaction_set)
  end

  def parse(file)
    doc = Ox.parse(Zlib::GzipReader.open(file).read)
    accounts = doc.locate('gnc-v2/gnc:book/gnc:account').map(&method(:parse_account))
    {
      accounts: Hash[accounts.map{ |a| [a[:guid], a] }],
      transactions: doc.locate('gnc-v2/gnc:book/gnc:transaction').map(&method(:parse_transaction)),
    }
  end

  def parse_account(acc)
    parent = acc.locate('act:parent').first
    {
      name: acc.locate('act:name').first.text,
      type: acc.locate('act:type').first.text,
      guid: acc.locate('act:id').first.text,
      parent_guid: parent && parent.text,
    }
  end

  def parse_transaction(trans)
    {
      date: trans.locate('trn:date-posted/ts:date').first.text,
      description: trans.locate('trn:description').first.text,
      splits: trans.locate('trn:splits/trn:split').map(&method(:parse_split)),
    }
  end

  def parse_split(split)
    {
      account_guid: split.locate('split:account').first.text,
      value:  split.locate('split:value').first.text,
    }
  end

  def xform(doc)
    TransactionSet.new(
      transactions: doc[:transactions]
        .map{ |trans| xform_transaction(trans, doc) }
        .sort_by(&:date)
    )
  end

  def xform_transaction(trans, doc)
    Transaction.new(
      date: xform_date(trans[:date]),
      description: trans[:description],
      entries: trans[:splits].map{ |split| xform_entry(split, doc) },
    )
  end

  def xform_account(guid, doc)
    parts = []
    while account = doc[:accounts][guid]
      parts.unshift(account[:name])
      guid = account[:parent_guid]
    end

    name = if parts.size <= 1
      'root'
    else
      parts
        .drop(1)
        .map{ |s| s.downcase.gsub(/\s/, '_') }
        .join(':')
    end

    Account.new(name)
  end

  def xform_date(date_str)
    ymd = date_str.split(' ').first
    Date.iso8601(ymd)
  end

  def xform_entry(split, doc)
    Entry.new(
      account: xform_account(split[:account_guid], doc),
      amount: xform_amount(split[:value]),
    )
  end

  def xform_amount(str)
    cents, _, denominator = str.partition('/')
    fail unless denominator == '100'
    Amount.new(Integer(cents))
  end

  def print_ts(transaction_set)
    f = Formatter.new(transaction_set)
    f.write_to($stdout)
  end

end
end
