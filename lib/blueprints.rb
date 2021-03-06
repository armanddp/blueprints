require 'active_support'
require 'active_support/core_ext'
require 'database_cleaner'
require 'set'

files = %w{
configuration context buildable namespace root_namespace blueprint file_context helper errors dependency extensions
}
files.each { |f| require File.join(File.dirname(__FILE__), 'blueprints', f) }

module Blueprints
  # Contains current configuration of blueprints
  def self.config
    @@config ||= Blueprints::Configuration.new
  end

  # Setups variables from global context and starts transaction. Should be called before every test case.
  def self.setup(current_context)
    Namespace.root.setup
    Namespace.root.copy_ivars(current_context)
    if_orm { DatabaseCleaner.start }
  end

  # Rollbacks transaction returning everything to state before test. Should be called after every test case.
  def self.teardown
    if_orm { DatabaseCleaner.clean }
  end

  # Enables blueprints support for RSpec or Test::Unit depending on whether (R)Spec is defined or not. Yields
  # Blueprints::Configuration object that you can use to configure blueprints.
  def self.enable
    yield config if block_given?
    load
    extension = if defined? Cucumber
                  'cucumber'
                elsif defined? Spec or defined? RSpec
                  'rspec'
                else
                  'test_unit'
                end
    require File.join(File.dirname(__FILE__), 'blueprints', 'extensions', extension)
  end

  # Sets up configuration, clears database, runs scenarios that have to be prebuilt. Should be run before all test cases and before Blueprints#setup.
  def self.load
    return unless Namespace.root.empty?

    if_orm do
      DatabaseCleaner.clean_with :truncation
      DatabaseCleaner.strategy = (config.transactions ? :transaction : :truncation)
    end
    load_scenarios_files(config.filename)

    Namespace.root.prebuild(config.prebuild) if config.transactions
  end

  def self.backtrace_cleaner
    @backtrace_cleaner ||= ActiveSupport::BacktraceCleaner.new.tap do |bc|
      root_sub = /^#{config.root}[\\\/]/
      blueprints_path = File.expand_path(File.dirname(__FILE__))

      bc.add_filter { |line| line.sub(root_sub, '') }
      bc.add_silencer { |line| [blueprints_path, *Gem.path].any? { |path| File.expand_path(File.dirname(line)).starts_with?(path) } }
    end
  end

  # Returns array of blueprints that have not been used since now. Allows passing namespace to start search from (defaults to root namespace)
  def self.unused(from = Namespace.root)
    from.children.values.collect do |child|
      if child.is_a?(Blueprints::Blueprint)
        child.path('.') unless child.used?
      else
        unused(child)
      end
    end.flatten.compact
  end

  def self.warn(message, blueprint)
    $stderr.puts("**WARNING** #{message}: '#{blueprint.name}'")
    $stderr.puts(backtrace_cleaner.clean(blueprint.backtrace(caller)).first)
  end

  protected

  # Loads blueprints file and creates blueprints from data it contains. Is run by setup method
  def self.load_scenarios_files(patterns)
    patterns.each do |pattern|
      pattern = config.root.join(pattern)
      files = Dir[pattern.to_s]
      files.each { |f| FileContext.new f }
      return if files.size > 0
    end

    raise "Blueprints file not found! Put blueprints in #{patterns.join(' or ')} or pass custom filename pattern with :filename option"
  end

  private

  def self.if_orm
    yield
  rescue DatabaseCleaner::NoORMDetected, DatabaseCleaner::NoStrategySetError
  end
end
