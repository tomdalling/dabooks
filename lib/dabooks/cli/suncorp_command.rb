require 'ox'

module Dabooks
class CLI::SuncorpCommand
  OPTIONS = Trollop::Parser.new do
    banner <<-EOS.dedent
      Converts OFX files from Suncorp into Dabooks format

      Usage:
        dabooks suncorp [options] <filename+>
    EOS
  end

  def initialize(opts, argv)
    @opts = opts
    @argv = argv
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
    Integer(str.gsub(/\./, '').gsub(/\A0+/, ''))
  end

  def xform(transactions, account)
    transactions.map{ |t| xform_transaction(t, account) }
  end

  def xform_transaction(trans, account)
    Transaction.new(
      trans[:date],
      trans[:description],
      [
        Entry.new(account, Amount[trans[:amount]]),
        Entry.new(Account['-----'], Amount.unfixed)
      ]
    )
  end

  def print_ts(transaction_set)
    f = Formatter.new(transaction_set)
    f.write_to($stdout)
  end

end
end