module Dabooks
class CLI::CheckCommand
  DETAILS = {
    description: "Checks the integrity of a book file.",
    usage: "dabooks check <filename>",
    schema: {},
  }

  def initialize(cli)
    @argv = cli.free_args
  end

  ResultSummary = Struct.new(:problems, :total) do
    def +(other)
      ResultSummary[problems + other.problems, total + other.total]
    end
  end

  def run
    summary = @argv
      .map{ |file| check(file) }
      .reduce(&:+)

    puts "Found #{summary.problems} problems in #{summary.total} transactions"
    exit summary.problems > 0 ? 1 : 0
  end

  def check(file)
    transaction_set = File.open(file, 'r') { |f| Dabooks::Parser.parse(f) }
    formatter = Formatter.new(transaction_set)
    last_date = nil
    problem_count = 0

    transaction_set.each do |trans|
      problems = problems_for(trans)
      if last_date && trans.date < last_date
        problems << 'is dated before the previous transaction'
      end

      print_problems(formatter, trans, problems) if problems.size > 0

      last_date = trans.date
      problem_count += problems.size
    end

    ResultSummary[problem_count, transaction_set.transactions.size]
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
    formatter.write_transaction(trans, $stdout)
    problems.each do |p|
      puts "  !!! #{p}"
    end
    print "\n"
  end

  def has_multiple_placeholders(transaction)
    transaction.entries.reject{ |e| e.amount.fixed? }.size > 1
  end

end
end
