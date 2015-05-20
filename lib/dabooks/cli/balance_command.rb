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

    transaction_set.each do |trans|
      trans.normalized_entries.each do |entry|
        all_balances[entry.account] += entry.amount
      end
    end

    # apply balances to parents
    all_balances.dup.each do |account, balance|
      while account = account.parent
        all_balances[account] += balance
      end
    end

    lines = all_balances
      .to_a
      .reject{ |(_, bal)| bal.zero? }
      .sort_by(&:first)
      .map do |(acc, bal)|
        [
          '  '*acc.depth + Formatter.format_account(acc),
          Formatter.format_amount(bal),
        ]
      end

    puts file
    TableFormatter.print_rows(lines, $stdout, [
      { align: :left, padding: '.' },
      { align: :right },
    ])
    print "\n"
  end

end
end
