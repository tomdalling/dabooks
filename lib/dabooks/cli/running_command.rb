module Dabooks
class CLI::RunningCommand
  OPTIONS = Trollop::Parser.new do
    banner <<-EOS
Usage:
  dabooks running [options] <account> <filename>+
EOS
  end

  def initialize(opts, argv)
    @opts = opts
    @argv = argv
  end

  def run
    target_account = Account[@argv.shift]
    balance = Amount.new(0)

    lines = []
    @argv.each do |file|
      transaction_set = File.open(file, 'r') { |f| Dabooks::Parser.parse(f) }
      transaction_set.each do |trans|
        trans.entries.each do |entry|
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
