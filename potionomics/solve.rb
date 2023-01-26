require 'algorithms'

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
    @summed_ingredients = ingredients.reduce(Migamins.empty) {|x, y| x.add(y) }
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

  def add(other_ingredient)
    self.class.new(ingredients + [other_ingredient])
  end

  def ingredient_count
    ingredients.length
  end

  def self.singleton(ingredient)
    new([ingredient])
  end
end

ingredients = [
  Migamins.new(6,0,0,0,0),
  Migamins.new(0,6,0,0,0),
].map {|x| [x, 100] }.to_h

c = Cauldron.new(115, 2)

heap = Containers::MaxHeap.new
target_ratios = [0.5, 0.5, 0, 0, 0]

ingredients.each do |i, n|
  mix = Mix.singleton(i)
  heap.push mix.value(target_ratios), mix
end

while mix = heap.pop
  new_mixes =
    ingredients.keys
      .map {|i| mix.add(i) }
      .select {|m| c.can_contain?(m) }

  new_mixes.each do |m|
    heap.push m.value(target_ratios), m
  end

  if new_mixes.empty?
    puts "CANDIDATE: #{mix.value(target_ratios)} #{mix.count} #{mix.ingredient_count} #{mix}"
  end
end
