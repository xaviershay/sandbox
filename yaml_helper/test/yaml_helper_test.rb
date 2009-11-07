require 'test/unit'
require File.dirname(__FILE__) + '/../lib/rhnh/yaml_helper'
require File.dirname(__FILE__) + '/types'

class TestYamlHelper < Test::Unit::TestCase
  # Testing persistent attribute
  def test_basic
    obj = Basic.new
    obj.a = 2
    s = obj.to_yaml
    obj2 = YAML::load(s)
    assert_equal obj.a, obj2.a
  end
  
  def check_persist_square obj
    obj.width = 2
    obj.height = 3
    obj.area = 5

    s = obj.to_yaml
    obj2 = YAML::load(s)
    assert_equal obj.width, obj2.width
    assert_equal obj.height, obj2.height
    
    obj2
  end
  
  def test_persist_attribute
    obj2 = check_persist_square Square.new
    assert_nil obj2.area
  end
  
  def test_persist_multi_attribute
    obj2 = check_persist_square Square2.new
    assert_nil obj2.area
  end
  
  def test_persist_attribute_inherited
    obj = SuperSquare.new
    obj.bonus = "WINNER"
    obj2 = check_persist_square obj

    assert_equal obj.bonus, obj2.bonus
  end
  
  # Testing post_deserialize
  def test_post_deserialize
    obj2 = check_persist_square Square3.new
    assert_equal obj2.height * obj2.width, obj2.area
  end
  
  def init_squares num
    arr = []
    for i in (0..num)
      sqr = Square3.new
      sqr.width = 2 + (i * 2)
      sqr.height = 3 + (i * 2)
      arr.push(sqr)
    end
    arr
  end
  
  def test_array_post_deserialize
    sqr, sqr2 = init_squares(2)
    
    s = [sqr, sqr2, nil].to_yaml
    obj2 = YAML::load(s)
    for obj in obj2
      assert_equal obj.width * obj.height, obj.area if obj
    end
  end
  
  def test_hash_post_deserialize
    sqr, sqr2 = init_squares(2)
    
    s = { :one => sqr, :two => sqr2, :three => nil }.to_yaml
    obj2 = YAML::load(s)
    for obj in obj2.values
      assert_equal obj.width * obj.height, obj.area if obj
    end
  end
  
  def test_cyclic_post_deserialize
    sqr = SquareCyclic.new
    s = sqr.to_yaml
    begin
      obj = YAML::load(s)
    rescue
      flunk "Infinite loop"
    end
  end
end
