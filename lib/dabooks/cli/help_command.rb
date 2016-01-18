module Dabooks
  class CLI::HelpCommand
    OPTIONS = Trollop::Parser.new do
      banner <<-EOS.dedent
        Displays a list of subcommands, or help for a specific subcommand.

        Usage:
          dabooks help [subcommand]
      EOS
    end

    def initialize(opts, argv)
      @opts = opts
      @argv = argv
    end

    def run
      case @argv.size
      when 0 then print_subcommands
      when 1 then print_help_for_command(@argv.last)
      else puts('Command not specified correctly')
      end
    end

    def print_subcommands
      puts
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

      puts <<-EOS.dedent

        For help with a specific command, type:
            dabooks help <command>
      EOS
      puts
    end

    def print_help_for_command(subcommand_name)
      cmd_class = Dabooks::CLI.subcommand_class(subcommand_name)
      unless cmd_class
        puts("Subcommand does not exist: #{subcommand_name}")
        exit(1)
      end

      cmd_class::OPTIONS.educate
    end

  end
end
