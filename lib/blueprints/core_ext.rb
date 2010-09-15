# Include this module into your class if you need klass.blueprint and object.blueprint methods.
module Blueprints::Blueprintable
  module ClassMethods
    # Two forms of this method can be used. First one is typically used inside blueprint block. Essentially it does
    # same as <tt>create!</tt>, except it does bypass attr_protected and attr_accessible. It accepts only a hash or attributes,
    # same as <tt>create!</tt> does.
    #   blueprint :post => [:user, :board] do
    #     @user.posts.blueprint(:title => 'first post', :text => 'My first post')
    #   end
    # The second form is used when you want to define new blueprint. It takes first argument as name of blueprint
    # and second one as hash of attributes. As you cannot use instance variables outside of blueprint block, you need
    # to prefix them with colon. So the example above could be rewritten like this:
    #   Post.blueprint(:post, :title => 'first post', :text => 'My first post', :user => d(:user)).depends_on(:board)
    def blueprint(name_or_attrs, attrs = {})
      if Blueprints::FileContext.current
        define_blueprint(name_or_attrs, attrs)
      else
        if name_or_attrs.is_a?(Array)
          name_or_attrs.collect { |attrs| blueprint(attrs) }
        else
          blueprint_object(name_or_attrs)
        end
      end
    end

    private

    def define_blueprint(name, attrs)
      klass = self
      blueprint = Blueprints::Blueprint.new(name, Blueprints::FileContext.current.namespaces.last, Blueprints::FileContext.current.file) { klass.blueprint attributes }
      blueprint.attributes(attrs)
      blueprint
    end

    def blueprint_object(attrs)
      object = new
      object.blueprint(attrs)
      object
    end
  end

  def self.included(mod)
    mod.extend Blueprints::Blueprintable::ClassMethods
  end

  # Updates attributes of object by calling setter methods.
  def blueprint(attributes)
    Blueprints::Blueprint.normalize_attributes(attributes).each do |attr, val|
      send(:"#{attr}=", val)
    end
  end
end

# Include this instead of Blueprints::Blueprintable if record needs to persist, includes Blueprints::Blueprintable
module Blueprints::Saveable
  include Blueprints::Blueprintable

  def self.included(mod)
    mod.extend Blueprints::Blueprintable::ClassMethods
  end

  # Overrides object.blueprint to also call save!
  def blueprint(attributes)
    super(attributes)
    save!
  end
end

::ActiveRecord::Base.send(:include, Blueprints::Saveable) if defined?(ActiveRecord)
