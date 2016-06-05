module Dabooks
  class CLI::HelpCommand
    DETAILS = {
      description: "Displays a list of subcommands, or help for a specific subcommand.",
      usage: "dabooks help [subcommand]",
      schema: {},
    }

    def initialize(cli)
      @subcommand = cli.free_args.first
    end

    def run
      if @subcommand
        print_help_for_command(@subcommand)
      else
        print_subcommands
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

      details = cmd_class::DETAILS
      puts details.fetch(:description)
      puts
      puts "Usage:"
      puts "  #{details.fetch(:usage)}"

      schema = details.fetch(:schema)
      unless schema.empty?
        puts
        puts "Options:"
        puts DowlOptParse.format(schema)
      end
    end

  end
end
