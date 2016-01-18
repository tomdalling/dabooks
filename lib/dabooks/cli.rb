require 'trollop'

module Dabooks::CLI
  extend self

  def run(argv=ARGV)
    argv = ['help'] if argv.empty?
    run_subcommand(argv.shift, argv)
  end

  def run_subcommand(subcommand_name, args)
    subcommand = subcommand_class(subcommand_name)
    unless subcommand
      puts("Unknown subcommand: #{subcommand_name}")
      exit(1)
    end

    Trollop.with_standard_exception_handling(subcommand::OPTIONS) do
      opts = subcommand::OPTIONS.parse(args)
      subcommand.new(opts, args).run
    end
  end

  def subcommand_class(subcommand_name)
    const_get("#{subcommand_name.to_s.capitalize}Command")
  rescue NameError
    nil
  end

end

Dir.glob(File.dirname(__FILE__) + '/cli/*.rb').each do |filename|
  require 'dabooks/cli/' + File.basename(filename, '.rb')
end
