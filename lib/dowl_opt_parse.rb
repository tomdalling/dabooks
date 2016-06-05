module DowlOptParse
  Result = Struct.new(:options, :free_args) do
    def initialize(options={}, free_args=[])
      super
    end

    def merge!(other)
      options.merge!(other.options)
      free_args.concat(other.free_args)
    end
  end

  def self.parse(schema, argv)
    Parser.new(schema, argv).call
  end

  def self.format(schema)
    Formatter.new(schema).call
  end
end

require 'dowl_opt_parse/parser'
require 'dowl_opt_parse/formatter'

