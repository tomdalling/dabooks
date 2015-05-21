module Dabooks
class CLI::GraphCommand
  OPTIONS = Trollop::Parser.new do
    banner <<-EOS
Usage:
  dabooks graph [options] <account> <filename>
EOS
  end

  def initialize(opts, argv)
    @opts = opts
    @argv = argv
  end

  def run
    target_account = Account[@argv.shift]
    balance = Amount.new(0)
    points = []

    @argv.each do |file|
      transaction_set = File.open(file, 'r') { |f| Dabooks::Parser.parse(f) }
      transaction_set.each do |trans|
        trans.normalized_entries.each do |entry|
          if entry.account == target_account
            balance += entry.amount
            points << [trans.date, balance]
          end
        end
      end
    end

    points.sort_by!(&:first)
    graph(points)
  end

  def graph(points)
    x_min, x_max = points.map(&:first).minmax
    y_min, y_max = points.map(&:last).minmax
    gutter_width = [y_min, y_max].map{ |x| Formatter.format_amount(x).length }.max

    data_rows = 20
    data_cols = 80
    data = quantize(points, data_cols, x_min, x_max, y_min, y_max, data_rows)

    # graph rows
    data_rows.downto(1) do |row|
      gutter = begin
        case
        when row == data_rows then Formatter.format_amount(y_max)
        when row == 1 then Formatter.format_amount(y_min)
        else ''
        end
      end
      print gutter.rjust(gutter_width, ' ')
      print "\u2551"
      data.each { |value| print (value >= row ?  "\u2588" : ' ') }
      print "\u2551\n"
    end

    # x axis labels
    print ' '*gutter_width + "\u2560" + "\u2550"*data_cols + "\u2563\n"
    left_date = x_min.to_s
    right_date = x_max.to_s
    print ' '*gutter_width + "\u2551" + left_date + right_date.rjust(data_cols - left_date.length, ' ') + "\u2551\n"
  end

  def quantize(points, x_buckets, x_min, x_max, y_min, y_max, y_scale)
    x_buckets.times.map do |idx|
      lower = x_lerp(idx.to_f / x_buckets, x_min, x_max)
      upper = x_lerp((idx+1).to_f / x_buckets, x_min, x_max)
      value = bucket_value(points, lower, upper)
      scale_amount(value, y_min, y_max, y_scale)
    end
  end

  def x_lerp(factor, min, max)
    return min if factor <= 0
    return max if factor >= 1

    min_s = min.to_time.to_i
    max_s = max.to_time.to_i
    secs = factor * (max_s - min_s)
    time = Time.at(min_s + secs)
    Date.new(time.year, time.month, time.day)
  end

  def scale_amount(value, min, max, y_scale)
    factor = (value - min).cents.to_f / (max - min).cents.to_f
    factor * y_scale
  end

  def bucket_value(points, lower_bound, upper_bound)
    lower_value = points.reverse_each.find{ |(date, _)| date <= lower_bound }.last
    upper_value = points.find{ |(date, _)| date >= upper_bound }.last
    lower_value + Amount[((upper_value - lower_value).cents / 2.0).floor]
  end

end
end
