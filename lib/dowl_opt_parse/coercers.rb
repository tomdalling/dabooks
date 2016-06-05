module DowlOptParse
  class CoercionError < StandardError; end

  module IntegerCoercer
    def self.call(value)
      Kernel.Integer(value)
    rescue ArgumentError
      raise CoercionError, 'is not an integer'
    end
  end

  module FloatCoercer
    def self.call(value)
      Kernel.Float(value)
    rescue ArgumentError
      raise CoercionError, 'is not a float'
    end
  end

  module StringCoercer
    def self.call(value)
      Kernel.String(value)
    end
  end

  module BoolCoercer
    TRUTHY_STRINGS = ['yes', 'y', 'true']
    FALSEY_STRINGS = ['no', 'n', 'false']
    def self.call(value)
      lower_value = value.downcase
      return true if TRUTHY_STRINGS.include?(lower_value)
      return false if FALSEY_STRINGS.include?(lower_value)
      raise CoercionError, 'is not a bool'
    end
  end

end
