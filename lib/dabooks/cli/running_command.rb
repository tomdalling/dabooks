require 'csv'

module Dabooks
class CLI::RunningCommand
  DETAILS = {
    description: 'Shows a running total for a given account.',
    usage: 'dabooks running [options] <account> <filename>+',
    schema: {
      csv: {
        long: '--csv',
        short: '-c',
        doc: 'Output in CSV format'
      },
    },
  }

  def initialize(cli)
    @argv = cli.free_args
    @csv = cli.options[:csv]
  end

  def run
    target_account = Account[@argv.shift]
    balance = Amount[0]

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

    if @csv
      output_csv(lines)
    else
      output_cli_text(lines)
    end
  end

  def output_cli_text(lines)
    TableFormatter.print_rows(lines, $stdout, [
      {align: :right},
      {align: :right},
      {},
      {}
    ])
  end

  def output_csv(lines)
    csv = CSV.new($stdout)
    csv << ["Balance", "Amount", "Date", "Description"]
    lines.each { |l| csv << l }
  end

end
end
