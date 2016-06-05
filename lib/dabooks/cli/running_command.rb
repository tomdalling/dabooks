module Dabooks
class CLI::RunningCommand
  DETAILS = {
    description: 'Shows a running total for a given account.',
    usage: 'dabooks running <account> <filename>+',
    schema: {},
  }

  def initialize(cli)
    @argv = cli.free_args
  end

  def run
    target_account = Account[@argv.shift]
    balance = Amount.new(0)

    lines = []
    @argv.each do |file|
      transaction_set = File.open(file, 'r') { |f| Dabooks::Parser.parse(f) }
      transaction_set.each do |trans|
        trans.normalized_entries.each do |entry|
          if entry.account == target_account
            balance += entry.amount
            lines << [
              Formatter.format_amount(balance),
              Formatter.format_amount(entry.amount),
              trans.date.to_s,
              trans.description
            ]
          end
        end
      end
    end

    TableFormatter.print_rows(lines, $stdout, [
      {align: :right},
      {align: :right},
      {},
      {}
    ])
  end

end
end
