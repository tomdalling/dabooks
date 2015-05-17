module Dabooks
module CLI::CheckCommand
  extend self

  OPTIONS = Trollop::Parser.new do
    banner <<-EOS
Usage:
  dabooks check [options] <filename>

EOS
  end

  def run(opts, argv)
    found_problems = false
    argv.each{ |file| found_problems ||= check(file) }
    exit found_problems ? 1 : 0
  end

  def check(file)
    found_problems = false

    transaction_set = File.open(file, 'r') { |f| Dabooks::Parser.parse(f) }
    formatter = Formatter.new(transaction_set)
    transaction_set.transactions.each do |trans|
      problems = problems_for(trans)
      if problems.size > 0
        found_problems = true

        print "\n"
        puts '='*80
        formatter.write_transaction(trans, $stdout)
        print "\n"
        problems.each do |p|
          puts " - #{p}"
        end
        print "\n"
      end
    end

    found_problems
  end

  def problems_for(transaction)
    problems = []
    problems << 'unbalanced' unless transaction.balanced?
    problems << 'missing entries' unless transaction.entries.size >= 2
    problems << 'too many placeholders' if has_multiple_placeholders(transaction)
    problems
  end

  def has_multiple_placeholders(transaction)
    transaction.entries.select{ |e| e.amount.is_a?(PlaceholderAmount) }.size > 1
  end

end
end
