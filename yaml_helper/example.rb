require 'lib/rhnh/yaml_helper'

class BeefCake
  attr_reader :ingredients
  persistent :ingredients
  
  def initialize
    @ingredients = ["Beef", "Flour", "More Beef", "Egg"]
    @result = nil
  end
  
  def mix!
    @result = self.ingredients.join  
  end
  
  def result
    @result ? @result : 'Beef cake has not been mixed yet!'
  end
  
  def post_deserialize
    puts "!!! Beef Cake got loaded !!!"
  end
end

puts "Let's make a Beef Cake!"
puts
cake = BeefCake.new
puts "Ingredients: " + cake.ingredients.join(", ")
puts "Result:      " + cake.result
puts " > Mixing..."
cake.mix!
puts "Result:      " + cake.result
puts " > YAMLizing and Restoring"
cake = YAML::load(cake.to_yaml)
puts "Result:      " + cake.result
puts " > Result was not stored!"
