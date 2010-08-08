require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Blueprints::Blueprint do
  before do
    mock = @mock
    @blueprint = Blueprints::Blueprint.new(:blueprint, __FILE__) { mock }
    Blueprints::Namespace.root.build :blueprint
  end

  describe "demolish" do
    before do
      @mock.stubs(:destroy)
    end

    it "should allow to demolish blueprint" do
      @mock.expects(:destroy)
      @blueprint.demolish
    end

    it "should unset @result after demolish" do
      @blueprint.demolish
      @blueprint.instance_variable_defined?(:@result).should be_false
    end

    it "should raise error if @result is not set" do
      @blueprint.demolish
      lambda { @blueprint.demolish }.should raise_error(Blueprints::DemolishError)
    end

    it "should set blueprint as not built" do
      @blueprint.demolish
      Blueprints::Namespace.root.executed_blueprints.collect(&:to_s).should_not include('demolish')
    end

    it "should allow to customize demolishing" do
      @mock.expects(:demolish)
      @blueprint.demolish { @blueprint.demolish }
      @blueprint.demolish
    end
  end
end
