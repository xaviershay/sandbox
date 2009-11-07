class Basic
  attr_accessor :a
end

class Square
  attr_accessor :width, :height, :area
  persistent :width, :height
  
  def calc_area
    @area = @width * @height
  end
end

class SuperSquare < Square
  attr_accessor :bonus
  persistent :bonus
end

class Square2
  attr_accessor :width, :height, :area
  persistent :width
  persistent :height
end

class Square3
  attr_accessor :width, :height, :area
  persistent :width, :height

  def post_deserialize
    @area = @width * @height
  end
end

class SquareCyclic
  def initialize
    @me = self
  end
  
  def post_deserialize
  end
end
