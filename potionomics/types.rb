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
  Stop.new("Greater 1", 170),
  Stop.new("Greater 2", 195),
  Stop.new("Greater 3", 215),
  Stop.new("Greater 4", 235),
  Stop.new("Greater 5", 260),
  Stop.new("Grand 0", 290),
  Stop.new("Grand 1", 315),
  Stop.new("Grand 2", 345),
  Stop.new("Grand 3", 370),
  Stop.new("Grand 4", 400),
  Stop.new("Grand 5", 430),
  Stop.new("Superior 0", 470),
  Stop.new("Superior 1", 505),
  Stop.new("Superior 2", 545),
  Stop.new("Superior 3", 580),
  Stop.new("Superior 4", 620),
  Stop.new("Superior 5", 660),
  Stop.new("Masterwork 0", 720),
  Stop.new("Masterwork 1", 800),
  Stop.new("Masterwork 2", 875),
  Stop.new("Masterwork 3", 960),
  Stop.new("Masterwork 4", 1040),
  Stop.new("Masterwork 5", 1125),
  Stop.new("OFF THE SCALE", 1200),
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

  def ratio
    to_a.map {|x| x.to_f / count }
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
  attr_reader :enhancers

  def initialize(args)
    ingredients = args.fetch(:ingredients)
    summed_ingredients =
      ingredients
      .reduce(Migamins.empty) {|y, (x, n)|
        z = y
        n.times { z = z.add(x.migamins) }
        z
      }
    @count = summed_ingredients.count
    @summed_ingredients = summed_ingredients
    @enhancers = ingredients.keys.map(&:enhancers).reduce(Enhancers.empty) {|y, x|
      y.merge(x)
    }
    super
  end

  def value(target_ratios)
    e = err(target_ratios)
    stop_modifier =
      if e > 0.1
        -1000
      elsif e < 0.0000000001
        2
      else
        1
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
    summed_ingredients.ratio
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

Ingredient = Data.define(:name, :migamins, :enhancers)
Enhancers = Data.define(:a, :b, :c, :d, :e) do
  def self.from_csv(*args)
    new(*args.map {|x|
      if x == ""
        nil
      else
        x.to_i
      end
    })
  end

  def self.empty
    new(nil, nil, nil, nil, nil)
  end

  def to_a
    [a, b, c, d, e]
  end

  def match?(filter)
    filter.zip(to_a).all? {|f, v|
      f.nil? || f == -1 && v != -1
    }
  end

  def inspect
    f = ->(x) {
      case x
      when nil
        "o"
      when -1
        "-"
      when 1
        "+"
      end
    }
    "<#{to_a.map(&f).join(" ")}>"
  end

  def merge(other)
    Enhancers.new(*to_a.zip(other.to_a).map {|a, b|
      if a == -1 || b == -1
        -1
      elsif a == 1 || b == 1
        1
      else
        nil
      end
    })
  end
end

Recipe = Data.define(:name, :ratio)
