module Blueprints
  # Class for actual blueprints. Allows building itself by executing block passed against current context.
  class Blueprint < Buildable
    attr_reader :file
    # Initializes blueprint by name, namespace, file and block
    def initialize(name, namespace, file, &block)
      @file = file
      super(name, namespace)

      ivname = variable_name
      @block = block
      @demolish_block = Proc.new { instance_variable_get(ivname).destroy }
      @update_block = Proc.new { instance_variable_get(ivname).blueprint(options) }
    end

    # Returns whether blueprint was ever used
    def used?
      @used
    end

    # Builds blueprint and adds it to executed blueprint hash. Setups instance variable with same name as blueprint if it is not defined yet.
    def build_self(build_once = true)
      @used = true
      surface_errors do
        if built? and build_once
          Namespace.root.context.instance_eval(&@update_block) if RootNamespace.root.context.options.present?
        elsif @block
          self.result = Namespace.root.context.instance_eval(&@block)
        end
      end
    end

    # Changes blueprint block to build another blueprint by passing additional options to it. Usually used to dry up
    # blueprints that are often built with some options.
    def extends(parent, options)
      attributes(options)
      @block = Proc.new { build parent => attributes }
    end

    def backtrace(trace)
      trace.collect! { |line| line.sub(/^#{@file}:(\d+).*/, "#{@file}:\\1:in blueprint '#{@name}'") }
    end

    # If block is passed then sets custom demolish block for this blueprint.
    # If no block is passed then calls demolish block and marks blueprint as not built.
    # Raises DemolishError if blueprints has not been built.
    def demolish(&block)
      if block
        @demolish_block = block
      elsif built?
        Namespace.root.context.instance_eval(&@demolish_block)
        undo!
      else
        raise DemolishError, @name
      end
    end

    # Allows customizing what happens when blueprint is already built and it's being built again.
    def update(&block)
      @update_block = block
    end

    private

    def surface_errors
      yield
    rescue StandardError => error
      backtrace(error.backtrace)
      raise error
    end
  end
end
