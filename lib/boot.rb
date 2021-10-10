# require standard libraries
require 'stringio'
require 'date'
require 'pathname'

ENV['BUNDLE_GEMFILE'] ||= Pathname(__dir__).parent.join('Gemfile').to_path

# require gems
require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)

# boot stuff that the codebase expects to be globally available
ValueSemantics.monkey_patch!
$LOAD_PATH.unshift(__dir__)
require 'dabooks'
require 'dabooks/cli'
