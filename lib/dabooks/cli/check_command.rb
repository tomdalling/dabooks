module Dabooks
class CLI::CheckCommand
  OPTIONS = Trollop::Parser.new do
    banner <<-EOS
Usage:
  dabooks check [options] <filename>
EOS
  end

  def initialize(opts, argv)
    @opts = opts
    @argv = argv
  end

  def run
    problem_count = @argv.map{ |file| check(file) }.reduce(:+)
    exit problem_count > 0 ? 1 : 0
  end

  def check(file)
    transaction_set = File.open(file, 'r') { |f| Dabooks::Parser.parse(f) }
    formatter = Formatter.new(transaction_set)
    last_date = nil
    problem_count = 0

    transaction_set.transactions.each do |trans|
      problems = problems_for(trans)
      if last_date && trans.date < last_date
        problems << 'is dated before the previous transaction'
      end

      print_problems(formatter, trans, problems) if problems.size > 0

      last_date = trans.date
      problem_count += problems.size
    end

    problem_count
  end

  def problems_for(transaction)
    problems = []
    problems << 'unbalanced' unless transaction.balanced?
    problems << 'missing entries' unless transaction.entries.size >= 2
    problems << 'too many placeholders' if has_multiple_placeholders(transaction)
    problems
  end

  def print_problems(formatter, trans, problems)
    print "\n"
    puts '='*80
    formatter.write_transaction(trans, $stdout)
    print "\n"
    problems.each do |p|
      puts " - #{p}"
    end
    print "\n"
  end

  def has_multiple_placeholders(transaction)
    transaction.entries.select{ |e| e.amount.is_a?(PlaceholderAmount) }.size > 1
  end

end
end
