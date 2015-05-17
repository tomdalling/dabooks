module Dabooks
class CLI::BalanceCommand
  OPTIONS = Trollop::Parser.new do
    banner <<-EOS
Usage:
  dabooks balance [options] <filename>
EOS
  end

  def initialize(opts, argv)
    @opts = opts
    @argv = argv
  end

  def run
    @argv.each{ |file| balance(file) }
  end

  def balance(file)
    transaction_set = File.open(file, 'r') { |f| Dabooks::Parser.parse(f) }
    all_balances = Hash.new{ |h,k| h[k] = Amount.new(0) }

    transaction_set.transactions.flat_map(&:normalized_entries).each do |entry|
      all_balances[entry.account] += entry.amount
    end

    # apply balances to parents
    all_balances.dup.each do |account, balance|
      while account = account.parent
        all_balances[account] += balance
      end
    end

    lines = all_balances
      .map { |account, balance| [account, balance] }
      .sort_by(&:first)
      .map { |(account, balance)| ['  '*account.depth + Formatter.format_account(account), balance] }

    max_account_width = lines.map(&:first).map(&:length).max

    puts file
    lines.each do |(account_name, balance)|
      print account_name.ljust(max_account_width, ' ')
      print '  '
      print Formatter.format_amount(balance)
      print "\n"
    end
  end

end
end
