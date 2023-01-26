require 'algorithms'
require 'set'
require 'csv'

Stop = Data.define(:label, :min_value) do
  def inspect
    "<Stop '#{label}' #{min_value}>"
  end
end

$stops = [
  Stop.new("Minor 0", 0),
  Stop.new("Minor 1", 10),
  Stop.new("Minor 2", 20),
  Stop.new("Minor 3", 30),
  Stop.new("Minor 4", 40),
  Stop.new("Minor 5", 50),
  Stop.new("Common 0", 60),
  Stop.new("Common 1", 75),
  Stop.new("Common 2", 90),
  Stop.new("Common 3", 105),
  Stop.new("Common 4", 120),
  Stop.new("Common 5", 135),
  Stop.new("Common 5", 135),
  Stop.new("Greater 0", 150),
  Stop.new("Greater 1", 150 + 23 * 1),
  Stop.new("Greater 3", 150 + 23 * 2),
  Stop.new("Greater 4", 150 + 23 * 3),
  Stop.new("Greater 5", 150 + 23 * 4),
  Stop.new("Grand 0", 290),
  Stop.new("Grand 1", 290 + 30 * 1),
  Stop.new("Grand 2", 290 + 30 * 2),
  Stop.new("Grand 3", 290 + 30 * 3),
  Stop.new("Grand 4", 290 + 30 * 4),
  Stop.new("Grand 5", 290 + 30 * 5),
]

def stop_index(value)
  $stops.take_while {|stop| stop.min_value <= value }.length - 1
end

def stop_for(value)
  $stops.take_while {|stop| stop.min_value <= value }.last
end

Migamins = Data.define(:r, :g, :y, :b, :p) do
  def to_a
    [r, g, y, b, p]
  end

  def count
    r + g + y + b + p
  end

  def add(other)
    self.class.new(
      r + other.r,
      g + other.g,
      y + other.y,
      b + other.b,
      p + other.p,
    )
  end

  def self.empty
    Migamins.new(0, 0, 0, 0, 0)
  end

  def inspect
    "<" +
    %w(R G Y B P).zip(to_a).select {|_, n| n > 0 }.map {|l, n| "#{l}#{n}" }.join(" ") + ">"
  end
end

Cauldron = Data.define(:max_migamins, :max_ingredients) do
  def can_contain?(mix)
    mix.ingredient_count <= max_ingredients && mix.count <= max_migamins
  end
end

Mix = Data.define(:ingredients) do
  attr_reader :count
  attr_reader :summed_ingredients

  def initialize(args)
    ingredients = args.fetch(:ingredients)
    @summed_ingredients =
      ingredients
      .reduce(Migamins.empty) {|y, (x, n)|
        z = y
        n.times { z = z.add(x) }
        z
      }
    @count = @summed_ingredients.count
    super
  end

  def value(target_ratios)
    e = err(target_ratios)
    stop_modifier =
      if e > 0.1
        -1000
      elsif e < 0.0000000001
        1
      else
        2
      end

    stop = stop_index(count) + stop_modifier

    if stop >= 0
      ($stops[stop] || $stops.last).min_value
    else
      count * 0.1
    end
  end

  def err(target_ratios)
    ratios.zip(target_ratios).map {|x, y| (x - y).abs }.sum
  end

  def valid?(target_ratios)
    err(target_ratios) <= 0.1
  end

  def ratios
    summed_ingredients.to_a.map {|x| x.to_f / count }
  end

  def add(other)
    self.class.new(ingredients.merge(other.ingredients) {|k, a, b| a + b })
  end

  def ingredient_count
    ingredients.values.sum
  end

  def self.singleton(ingredient)
    new({ingredient => 1})
  end
end

ingredients = [
  Migamins.new(6,0,0,0,0),
  Migamins.new(4,0,0,0,0),
  Migamins.new(0,6,0,0,0),
  Migamins.new(0,4,0,0,0),
  Migamins.new(0,0,0,18,0),
]
ingredients = [
  Migamins.new(6,0,0,0,0),
  Migamins.new(4,0,0,0,0),
  Migamins.new(24,0,0,0,0),
  Migamins.new(30,0,0,0,0),
  Migamins.new(40,0,0,20,0),
  Migamins.new(18,0,0,6,0),
  Migamins.new(0,0,0,30,0),
  Migamins.new(0,0,0,18,0),
  Migamins.new(0,0,0,12,0),
]

data = CSV.read('data/ingredients.csv', headers: true)
ingredients = data.map do |row|
  Migamins.new(
    *[row[2], row[3], row[4], row[5], row[6]].map(&:to_i)
  )
end

ingredients = ingredients.map {|x| [x, 100] }.to_h

c = Cauldron.new(320, 8)

heap = Containers::MaxHeap.new
seen = Set.new
target_ratios = [0.5, 0.5, 0, 0, 0]
target_ratios = [0.5, 0.0, 0, 0.5, 0]
target_ratios = [0.5, 0.0, 0.25, 0.25, 0]

ingredients.each do |i, n|
  mix = Mix.singleton(i)
  heap.push mix.value(target_ratios), mix
  seen.add(mix)
end

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
      puts "CANDIDATE: Value=#{mix.count} Ingredients=#{mix.ingredient_count} stop=#{stop.label}"
      puts "  #{mix.summed_ingredients.inspect}"
      puts
      mix.ingredients.each do |k, v|
        puts "  #{v} * #{k.inspect}"
      end
      puts
      max_value = v
    end
  end
end
