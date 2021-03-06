blueprint :apple do
  Fruit.blueprint :species => 'apple'
end

blueprint :many_apples => [:apple, :apple, :apple]

blueprint :bananas_and_apples => :apple do
  @banana = Fruit.blueprint :species => 'banana'
end

blueprint :orange do
  Fruit.blueprint :species => 'orange'
end

blueprint :fruit => [:apple, :orange] do
  [@orange, @apple]
end

blueprint :bananas_and_apples_and_oranges => [:bananas_and_apples, :orange] do
  @fruit = [@orange, @apple, @banana]
end

blueprint :cherry do
  Fruit.blueprint :species => 'cherry', :average_diameter => 3
end

blueprint :big_cherry => :cherry do
  Fruit.blueprint options.reverse_merge(:species => @cherry.species, :average_diameter => 7)
end

blueprint :cherry_basket => [:big_cherry, :cherry] do
  [@cherry, @big_cherry]
end

blueprint :parent_not_existing => :not_existing

Tree.blueprint :oak, :name => 'Oak', :size => 'large'
blueprint(:huge_oak).extends(:oak, :size => 'huge')
Tree.blueprint(:oak_without_attributes)

blueprint :pine do
  @the_pine = Tree.blueprint :name => 'Pine', :size => 'medium'
  @pine = Tree.blueprint :name => 'Pine', :size => 'small'
end

Fruit.blueprint(:acorn, :species => 'Acorn', :tree => d(:oak))
blueprint :small_acorn do
  @small_acorn = build :acorn => {:average_diameter => 1}
  @small_acorn_options = options
end
blueprint(:huge_acorn => :huge_oak).extends(:acorn, :average_diameter => 100)

namespace :pitted => :pine do
  Tree.blueprint :peach_tree, :name => 'pitted peach tree'
  Fruit.blueprint :peach, :species => 'pitted peach', :tree => d(:'pitted.peach_tree')
  Fruit.blueprint :acorn, :species => 'pitted acorn', :tree => d(:oak)

  namespace :red => :orange do
    Fruit.blueprint(:apple, :species => 'pitted red apple')
  end
end

blueprint :apple_with_params do
  Fruit.blueprint options.reverse_merge(:species => 'apple')
end

namespace :attributes do
  blueprint :cherry do
    Fruit.blueprint attributes
  end.attributes(:species => 'cherry')

  Fruit.blueprint :shortened_cherry, :species => 'cherry'

  Fruit.blueprint :dependent_cherry, :tree => d(:pine, :the_pine)
end.attributes(:average_diameter => 10, :species => 'fruit with attributes')

blueprint :circular_reference => :circular_reference
