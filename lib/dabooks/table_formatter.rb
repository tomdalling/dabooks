module Dabooks
  class TableFormatter
    Column = Struct.new(
      :width, # integer (characters)
      :align, # :left, :center, :right
      :padding, # String
    )

    def initialize(column_infos)
      @columns = column_infos.map do |info|
        Column.new.tap do |col|
          col.width = info[:width] || 5
          col.align = info[:align] || :left
          col.padding = info[:padding] || ' '
        end
      end
    end

    def print_row(row, io=$stdout)
      raise ArgumentError unless row.size == @columns.size
      @columns.zip(row).each do |(col, value)|
        io.write(format(col, value) + ' ')
      end
      io.write("\n")
    end

    def format(column, value)
      value = value.to_s

      value = begin
        case column.align
        when :left then value.ljust(column.width, column.padding)
        when :right then value.rjust(column.width, column.padding)
        when :center
          pad_count = column.width - value.length
          if pad_count > 0
            left = (pad_count / 2).floor
            right = pad_count - left
            left*column.padding + value + right*column.padding
          else
            value
          end
        else fail("Unrecoginised alignment: #{column.align}")
        end
      end

      value[0, column.width] # truncates if necessary
    end

    def self.print_rows(rows, io, column_infos)
      auto_width_cols = column_infos.each_with_index.map do |info, idx|
        defaults = { width: rows.map{ |r| r[idx].to_s.length }.max }
        defaults.merge(info)
      end

      table = new(auto_width_cols)
      rows.each{ |r| table.print_row(r, io) }
    end
  end
end
