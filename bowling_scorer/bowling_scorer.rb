# Recursive solution to score a game of tenpin bowling
# Inspired by http://www.randomhacks.net/articles/2007/04/28/bowling-in-haskell

# Code

class BowlingScorer
  def score(balls, frames = 10)
    return frames == 0 ? 0 : score_function(balls[0], balls[1]).call(balls) + score(balls, frames - 1)
  end
  
protected
  Component       = Struct.new(:condition, :number_to_score, :number_to_shift)
  ConditionIsTrue = lambda {|x| x[0].call }
  
  def score_function(s1, s2)
    p = Component.new *[
      [ lambda { s1 == 10},      3, 1], # Strike
      [ lambda { s1 + s2 == 10}, 3, 2], # Spare
      [ lambda { true },         2, 2]  # Default
    ].find(&ConditionIsTrue)
    return join_return_first(score_frame(p.number_to_score), multi_shift(p.number_to_shift))
  end
  
  def score_frame(n)
    lambda {|balls| n ? balls[0..n-1].inject(0) {|a, g| a + g } : 0 }
  end
  
  def multi_shift(count)
    lambda {|x| count.times { x.shift } }
  end
end

# Helpers

def join_return_first(*functions)
  lambda do |*args|
    ret = functions.shift.call(*args)
    functions.each {|x| x.call(*args) }
    return ret
  end
end

# Tests
require 'test/unit'

class BowlingScorerTest < Test::Unit::TestCase
  def self.test(name, &block)
    test_name = :"test_#{name.gsub(' ','_')}"
    raise ArgumentError, "#{test_name} is already defined" if self.instance_methods.include? test_name.to_s
    define_method test_name, &block
  end
  
  Gutter = [0, 0]
  Strike = [10]
  
  def setup
    @scorer = BowlingScorer.new
  end
  
  test "All gutters should score 0" do
    assert_equal 0, @scorer.score(Gutter * 10)
  end
  
  test "All strikes should score 300" do
    assert_equal 300, @scorer.score(Strike * 12)
  end
  
  test "All 5 spares should score 150" do
    assert_equal 150, @scorer.score([5, 5] * 9 + [5, 5, 5])
  end
  
  test "9:Strike, 10:2,3 should score 20" do
    assert_equal 20, @scorer.score(Gutter * 8 + Strike + [2,3])
  end
  
  test "10:Strike,2,3 should score 15" do
    assert_equal 15, @scorer.score(Gutter * 9 + [10, 2,3])
  end
end
