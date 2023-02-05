require 'algorithms'
require 'set'
require 'csv'
require 'pry'
require 'pry-nav'
require_relative "./types"


target = Recipe.new("Thunder Tonic", [0, 0.5, 0, 0.5, 0])
target = Recipe.new("Mana Potion", [0.0, 0.5, 0.5, 0, 0])
target = Recipe.new("Fire Tonic", [0.5, 0, 0.5, 0, 0])
target = Recipe.new("Posion Cure", [0.5, 0.0, 0.25, 0.25, 0])
target = Recipe.new("Stamina Potion", [0.5, 0, 0, 0, 0.5])
target = Recipe.new("Silence Cure", [0, 0.5, 0.25, 0, 0.25])
target = Recipe.new("Ice Tonic", [0.5, 0, 0, 0.5, 0])
target = Recipe.new("Drowsiness Cure", [0.25, 0.25, 0, 0.5, 0])
target = Recipe.new("Sleep Cure", [0, 0.5, 0.25, 0, 0.25])


# Supeior with 2/3/5
target = Recipe.new("Seeking Enhancer", [0.0, 0.0, 0.3, 0.4, 0.3])
target = Recipe.new("Dowsing Enhancer", [0.3, 0.0, 0, 0.3, 0.4])
target = Recipe.new("Insight Enhancer", [0.4, 0.3, 0, 0, 0.3])

# 2 x Superior with 1/3/4
target = Recipe.new("Tolerance Potion", [0, 0, 0.5, 0, 0.5])

target = Recipe.new("Alertness Enhancer", [0.3, 0.4, 0.3, 0, 0])
target = Recipe.new("Health Potion", [0.5, 0.5, 0, 0, 0])

target_ratios = target.ratio

data = CSV.read('data/ingredients.csv', headers: true)
ingredients = data.map do |row|
  Ingredient.new(
    row[0],
    Migamins.new(
      *[row[2], row[3], row[4], row[5], row[6]].map(&:to_i)
    )
  )
end

ingredients.select! {|i|
  !i.migamins.to_a.zip(target_ratios).any? {|i, r| i > 0 && r == 0 }
}

ingredients = ingredients.map {|x| [x, 100] }.to_h

c = Cauldron.new(540, 8)
c = Cauldron.new(505, 9)
c = Cauldron.new(675, 10)
c = Cauldron.new(320, 8)

heap = Containers::MaxHeap.new
seen = Set.new
components_seen = Set.new
available_ingredients = ingredients.keys.sort_by {|x| -x.migamins.count }

new_mixes = []
available_ingredients.each do |i|
  components = i.migamins.ratio
  next if components_seen.include?(components)

  new_mix = Mix.singleton(i)

  next if seen.include?(new_mix)
  next unless c.can_contain?(new_mix)

  components_seen << components
  new_mixes << new_mix
end

new_mixes.each do |mix|
  heap.push mix.value(target_ratios), mix
  seen.add(mix)
end

puts "Ingredient list:"
ingredients.sort_by {|x, _| -x.migamins.count }.each do |k, v|
  puts "  #{v} * %-10s #{k.name}" % [
    k.migamins.inspect
  ]
end
puts
puts "Solving for #{c.max_migamins} in #{c.max_ingredients}\n  with #{target.name} #{target_ratios}"
puts
max_value = 0

while mix = heap.pop
  # puts "EVAL: #{mix.ingredients.keys.map(&:name)} #{mix.summed_ingredients.inspect}"
  components_seen = Set.new

  new_mixes = []
  available_ingredients.each do |i|
    quantity = ingredients[i] - mix.ingredients.fetch(i, 0)
    next unless quantity > 0

    components = i.migamins.ratio
    next if components_seen.include?(components)

    new_mix = mix.add(Mix.singleton(i))

    next if seen.include?(new_mix)
    next unless c.can_contain?(new_mix)

    components_seen << components if (c.max_migamins - i.migamins.count) >= i.migamins.count * 2
    new_mixes << new_mix
  end

  new_mixes.each do |m|
    heap.push m.value(target_ratios), m
    seen.add(m)
  end

  if new_mixes.empty?
    v = mix.value(target_ratios)
    if v > max_value && mix.valid?(target_ratios)
      stop = stop_for(mix.value(target_ratios))
      puts "CANDIDATE: value=#{mix.count} ingredients=#{mix.ingredient_count} quality=#{stop.label}"
      puts "  #{mix.summed_ingredients.inspect}"
      puts
      mix.ingredients.each do |k, v|
        puts "  #{v} * %-10s #{k.name}" % [
          k.migamins.inspect
        ]
      end
      puts
      max_value = v
    end
  else
  end
end
