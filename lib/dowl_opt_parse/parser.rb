require 'dowl_opt_parse/coercers'

module DowlOptParse
  class Parser
    BUILTIN_COERCERS = {
      integer: IntegerCoercer,
      float: FloatCoercer,
      string: StringCoercer,
      bool: BoolCoercer,
    }

    class Error < StandardError; end

    def initialize(schema, argv)
      @schema = schema
      @argv = argv

      check_all_option_flags!
    end

    def call
      result = Result.new

      while @argv.size > 0
        result.merge!(parse_next!)
      end

      result = apply_defaults(result)
      check_required_arguments!(result)

      result
    end

    def check_all_option_flags!
      @schema.each do |key, config|
        short = config[:short]
        long = config[:long]

        unless short || long
          raise Error, "Option #{key.inspect} must provide a :short or :long flag"
        end

        if short && (short.size != 2 || !short.start_with?('-'))
          raise Error, "Option #{key.inspect} has invalid short flag: #{short.inspect}"
        end

        if long && (long.size < 3 || !long.start_with?('--'))
          raise Error, "Option #{key.inspect} has invalid long flag: #{long.inspect}"
        end
      end
    end

    def check_required_arguments!(result)
      @schema.each do |key, config|
        if config[:required] && !result.options.has_key?(key)
          flags = [config[:long], config[:short]].compact.join(", ")
          raise Error, "Required flag is missing: #{flags}"
        end
      end
    end

    def parse_next!
      a = @argv.first

      case
      when a == '-' then parse_free_argument!
      when a == '--' then parse_remaining_args_as_free_args!
      when a.start_with?('--') then parse_long_flag!
      when a.start_with?('-') then parse_short_flag!
      else parse_free_argument!
      end
    end

    def take_next_arg!
      if @argv.empty?
        raise Error, "Expected more command line arguments than were given"
      end
      @argv.shift
    end

    def apply_defaults(result)
      @schema.each do |key, config|
        if config.has_key?(:default)
          result.options[key] ||= config.fetch(:default)
        end
      end

      result
    end

    def parse_long_flag!
      parse_option!(take_next_arg!)
    end

    def parse_short_flag!
      flags = take_next_arg![1..-1]
      result = Result.new
      flags.chars.each do |ch|
        result.merge!(parse_option!('-' + ch))
      end
      result
    end

    def parse_free_argument!
      Result.new({}, [take_next_arg!])
    end

    def parse_remaining_args_as_free_args!
      if take_next_arg! != '--'
        fail("This should be called with '--' as the next argv element")
      end

      result = Result.new
      until @argv.empty?
        result.merge!(parse_free_argument!)
      end

      result
    end

    def lookup_opt(flag)
      @schema.each do |key, config|
        if flag == config[:short] || flag == config[:long]
          return key, config
        end
      end

      raise Error, "Unrecognised flag: #{flag}"
    end

    def parse_option!(flag)
      key, conf = lookup_opt(flag)

      value =
        if conf.has_key?(:argument)
          parse_option_argument!(flag, conf.fetch(:argument))
        else
          true
        end

      Result.new(key => value)
    end

    def parse_option_argument!(flag, argument_type)
      if @argv.empty?
        raise Error, "Required argument missing for flag: #{flag}"
      end

      coercer = BUILTIN_COERCERS.fetch(argument_type) do
        fail "Unrecognised argument type for flag #{flag}: #{argument_type.inspect}"
      end

      arg = take_next_arg!
      begin
        coercer.call(arg)
      rescue CoercionError => ex
        raise Error, "Value for flag #{flag} #{ex.message}: #{arg}"
      end
    end
  end
end

