module Dabooks
class CLI::BalanceCommand
  DETAILS = {
    description: 'Shows balances for all accounts.',
    usage: 'dabooks balance [options] <filename>',
    schema: {
      filter: {
        long: '--filter',
        short: '-f',
        argument: :string,
        doc: 'Transaction filter',
        default: '',
      }
    }
  }

  def initialize(cli)
    @cli = cli
  end

  def options
    @cli.options
  end

  def run
    filter = Filter.from_dsl(@cli.options[:filter])
    @cli.free_args.each{ |file| balance(file, filter) }
  end

  def balance(file, filter)
    transaction_set = transaction_set_for(file)
    all_balances = Hash.new{ |h,k| h[k] = Amount.new(0) }

    transaction_set.each do |trans|
      if filter.include?(trans)
        trans.normalized_entries.each do |entry|
          all_balances[entry.account] += entry.amount
        end
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
          '    '*acc.depth + acc.last_component,
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

  def transaction_set_for(path)
    File.open(path, 'r') { |f| Dabooks::Parser.parse(f) }
  rescue Errno::ENOENT
    $stderr.puts("File not found: #{path}")
    abort
  end

end
end
