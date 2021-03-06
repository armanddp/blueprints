module Blueprints
  # Defines a root namespace that is used when no other namespace is. Apart from functionality in namespace it also allows
  # building blueprints/namespaces by name. Is also used for copying instance variables between blueprints/contexts/global
  # context.
  class RootNamespace < Namespace
    attr_reader :context, :executed_blueprints

    def initialize
      @executed_blueprints = @global_executed_blueprints = []
      @auto_iv_list = Set.new

      super '', nil
    end

    # Loads all instance variables from global context to current one.
    def setup
      (@executed_blueprints - @global_executed_blueprints).each(&:undo!)
      @executed_blueprints = @global_executed_blueprints.clone
      @context = Blueprints::Context.new

      if Blueprints.config.transactions
        Marshal.load(@global_variables).each { |name, value| @context.instance_variable_set(name, value) }
      else
        build(Blueprints.config.prebuild)
      end
    end

    # Copies all instance variables from current context to another one.
    def copy_ivars(to)
      @context.instance_variables.each do |iv|
        to.instance_variable_set(iv, @context.instance_variable_get(iv))
      end
    end

    # Sets up global context and executes prebuilt blueprints against it.
    def prebuild(blueprints)
      @context = Blueprints::Context.new
      build(blueprints) if blueprints

      @global_executed_blueprints = @executed_blueprints
      @global_variables = Marshal.dump(@context.instance_variables.each_with_object({}) { |iv, hash| hash[iv] = @context.instance_variable_get(iv) })
    end

    # Builds blueprints that are passed against current context. Copies instance variables to context given if one is given.
    def build(names, context = nil, build_once = true)
      names = [names] unless names.is_a?(Array)
      result = names.inject(nil) do |result, member|
        if member.is_a?(Hash)
          member.map { |name, options| self[name].build(build_once, options) }.last
        else
          self[member].build(build_once)
        end
      end

      copy_ivars(context) if context
      result
    end

    # Sets instance variable in current context to passed value. If instance variable with same name already exists, it
    # is set only if it was set using this same method
    def add_variable(name, value)
      if not @context.instance_variable_defined?(name) or @auto_iv_list.include?(name)
        @auto_iv_list << name
        @context.instance_variable_set(name, value)
      end
    end

    @@root = RootNamespace.new
  end
end
