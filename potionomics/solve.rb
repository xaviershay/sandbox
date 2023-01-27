require 'algorithms'
require 'set'
require 'csv'
require 'pry'
require 'pry-nav'
require_relative "./types"


target = Recipe.new("Posion Cure", [0.5, 0.0, 0.25, 0.25, 0])
target = Recipe.new("Thunder Tonic", [0, 0.5, 0, 0.5, 0])
target = Recipe.new("Health Potion", [0.5, 0.5, 0, 0, 0])
target = Recipe.new("Mana Potion", [0.0, 0.5, 0.5, 0, 0])
target = Recipe.new("Fire Tonic", [0.5, 0, 0.5, 0, 0])
target = Recipe.new("Ice Tonic", [0.5, 0, 0, 0.5, 0])

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

c = Cauldron.new(320, 8)
c = Cauldron.new(405, 8)

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
ingredients.each do |k, v|
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
    components = i.migamins.ratio
    next if components_seen.include?(components)

    new_mix = mix.add(Mix.singleton(i))

    next if seen.include?(new_mix)
    next unless c.can_contain?(new_mix)

    components_seen << components
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
