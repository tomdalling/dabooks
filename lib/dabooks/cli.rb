require 'trollop'

module Dabooks::CLI
  extend self

  def run(argv=ARGV)
    if argv.empty?
      print_subcommands
    else
      run_subcommand(argv.shift, argv)
    end
  end

  def run_subcommand(subcommand_name, args)
    subcommand = begin
      const_get("#{subcommand_name.to_s.capitalize}Command")
    rescue NameError
      puts "Unknown subcommand: #{subcommand_name}"
      exit 1
    end

    opts = Trollop.with_standard_exception_handling(subcommand::OPTIONS) do
      subcommand::OPTIONS.parse(args)
    end
    subcommand.new(opts, args).run
  end

  def print_subcommands
    puts 'Available subcommands:'
    parent_module = Dabooks::CLI
    parent_module.constants.each do |const_sym|
      const = parent_module.const_get(const_sym)
      if const.is_a?(Module) && const.name.end_with?('Command')
        _, _, subcommand_module_name = const.name.rpartition('::')
        subcommand = subcommand_module_name.gsub(/Command\Z/, '').downcase
        puts "    #{subcommand}"
      end
    end
  end
end

Dir.glob(File.dirname(__FILE__) + '/cli/*.rb').each do |filename|
  require 'dabooks/cli/' + File.basename(filename, '.rb')
end
