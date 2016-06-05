module DowlOptParse
  class Formatter
    def initialize(schema)
      @schema = schema
    end

    def call
      formatted_options.join("\n")
    end

    def formatted_options
      @schema.map do |_, config|
        flags = [config[:long], config[:short]].compact
        flags_line = "#{flags.join(', ')} #{config[:argument]}".strip
        doc_line = (config[:doc] || "").each_line.map{ |line| "    #{line.strip}" }
        [flags_line, doc_line].join("\n").strip
      end
    end
  end
end

