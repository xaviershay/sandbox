# OO solution to score a game of tenpin bowling
# Written for comparison against bowling_scorer.rb
# I don't like this one as much

# Code

class Array
  def sum
    self.inject(0) {|a, g| a + g }
  end
end

class Frames < Array
  def <<(frame)
    last.next_frame = frame if last
    super
  end
  
  def total
    collect {|x| x.score }.sum
  end
end

class Frame
  attr_accessor :rolls
  attr_accessor :next_frame
  
  def initialize(*rolls)
    self.rolls = rolls
  end
  
  def score
    self.rolls.sum
  end
  
  def next_rolls(count)
    self.rolls[0..count-1]
  end
end

class StrikeFrame < Frame
  def score
    10 + next_frame.next_rolls(2).sum
  end

  def next_rolls(count)
    [10, next_frame.next_rolls(1)[0]][0..count-1]
  end
end

class SpareFrame < Frame
  def score
    10 + next_frame.next_rolls(1).sum
  end
end

class LastFrame < Frame
  def score
    0
  end
end

class BowlingScorerOO
  def score(balls)
    frames = Frames.new
   
    10.times do
      first = balls.shift
      if first == 10
        frame = StrikeFrame.new
      else
        second = balls.shift
        frame = (first + second == 10 ? SpareFrame : Frame).new(first, second)
      end
      frames << frame
    end
    frames << LastFrame.new(*balls)
    frames.total
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
    @scorer = BowlingScorerOO.new
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
