require 'ox'

module Dabooks
class CLI::SuncorpCommand
  DETAILS = {
    description: <<~EOS,
      Converts OFX files from Suncorp into Dabooks format.

      The names of the OFX files should match the 'X' in 'assets:suncorp:X'.
      Check `bin/fetch_suncorp.rb` for fetching the OFX files.
    EOS
    usage: 'dabooks suncorp <ofx_file>+',
    schema: {},
  }

  def initialize(cli)
    @argv = cli.free_args
  end

  def run
    if @argv.empty?
      puts("Didn't specify any OFX files")
      exit(1)
    end

    transactions = @argv.flat_map do |file|
      xform(parse(file), account_for_file(file))
    end
    transactions.sort_by!(&:date)
    print_ts(TransactionSet.new(transactions))
  end

  def account_for_file(file)
    acc_name = File.basename(file, File.extname(file))
    Account["assets:suncorp:#{acc_name}"]
  end

  def parse(file)
    doc = Ox.parse(File.read(file))
    doc.locate('OFX/BANKMSGSRSV1/STMTTRNRS/STMTRS/BANKTRANLIST/STMTTRN').map(&method(:parse_transaction))
  end

  def parse_transaction(trans)
    {
      date: parse_date(trans.locate('DTPOSTED').first.text),
      description: trans.locate('MEMO/^CData').first.value,
      amount: parse_amount(trans.locate('TRNAMT').first.text),
    }
  end

  def parse_date(str)
    Date.strptime(str, '%Y%m%d')
  end

  def parse_amount(str)
    negative = (str[0] == '-')
    cents_str = str.gsub(/\./, '').gsub(/\A-?0*/, '')
    cents = Integer(cents_str)
    negative ? -cents : cents
  end

  def xform(transactions, account)
    transactions.map{ |t| xform_transaction(t, account) }
  end

  def xform_transaction(trans, account)
    Transaction.new(
      date: trans[:date],
      description: trans[:description],
      entries: [
        Entry.new(account: account, amount: Amount[trans[:amount]]),
        Entry.new(account: Account['-----'], amount: Amount.unfixed)
      ]
    )
  end

  def print_ts(transaction_set)
    f = Formatter.new(transaction_set)
    f.write_to($stdout)
  end

end
end
