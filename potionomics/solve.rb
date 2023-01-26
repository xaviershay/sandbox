require 'algorithms'
require 'set'

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
    modifier = if ratios == target_ratios
      1.2 
    else
      1
    end

    count * modifier
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
].map {|x| [x, 100] }.to_h

c = Cauldron.new(35, 16)

heap = Containers::MaxHeap.new
seen = Set.new
target_ratios = [0.5, 0.5, 0, 0, 0]

ingredients.each do |i, n|
  mix = Mix.singleton(i)
  heap.push mix.value(target_ratios), mix
  seen.add(mix)
end

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
    if v > max_value
      puts "CANDIDATE: #{mix.value(target_ratios)} #{mix.count} #{mix.ingredient_count} #{mix}"
      max_value = v
    end
  end
end
