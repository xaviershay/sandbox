require 'algorithms'
require 'set'
require 'csv'
require_relative "./types"

target_ratios = [0.5, 0.5, 0, 0, 0] # Health Potion
target_ratios = [0.5, 0.0, 0, 0.5, 0] # Ice Tonic
target_ratios = [0.5, 0.0, 0.5, 0, 0] # Fire Tonic
target_ratios = [0.5, 0.5, 0.0, 0, 0] # Health Tonic
target_ratios = [0.5, 0.0, 0.25, 0.25, 0] # Poison Cure
target_ratios = [0, 0.5, 0, 0.5, 0] # Thunder Tonic

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
c = Cauldron.new(405, 9)

heap = Containers::MaxHeap.new
seen = Set.new

ingredients.each do |i, n|
  mix = Mix.singleton(i)
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
puts "Solving for #{c}\n  with #{target_ratios}"
puts
max_value = 0
while mix = heap.pop
  # puts "EVAL: #{mix} #{mix.summed_ingredients.inspect}"
  new_mixes = ingredients.keys
    .map {|i| mix.add(Mix.singleton(i)) }
    .select {|m| !seen.include?(m) && c.can_contain?(m) }

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
  end
end
