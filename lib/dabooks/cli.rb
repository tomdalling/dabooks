require 'trollop'

module Dabooks::CLI
  extend self

  def run(argv=ARGV)
    subcommand_name = argv.shift
    subcommand = begin
      const_get("#{subcommand_name.to_s.capitalize}Command")
    rescue NameError
      puts "Unknown subcommand: #{subcommand_name}"
      exit 1
    end

    opts = Trollop.with_standard_exception_handling(subcommand::OPTIONS) do
      subcommand::OPTIONS.parse(argv)
    end
    subcommand.new(opts, argv).run
  end
end

Dir.glob(File.dirname(__FILE__) + '/cli/*.rb').each do |filename|
  require 'dabooks/cli/' + File.basename(filename, '.rb')
end
