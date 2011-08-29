
class Operation
  attr_accessor :block

  def initialize(block)
    @block = block
  end

  # To support composites
  def +(other)
    CompositeOperation.new(self, other)
  end

  def run(state)
    @block.call(state)
  end

  # To support evaluators
  def call(*args)
    @block.call(*args)
  end
end

class CompositeOperation < Operation
  def initialize(a, b)
    @a = a
    @b = b
    super(lambda {|x| @b.block[@a.block[x][1]] })
  end

  def desc
    @a.desc + "\n" + @b.desc
  end
end

class PushOperation < Operation
  def initialize(value)
    @value = value
    super(lambda {|x| [value, x + [value]] })
  end

  def desc
    "push #{@value}"
  end
end

class AddOperation < Operation
  def initialize
    super(lambda {|x| [x[-1] + x[-2], x[0..-3]] })
  end

  def desc
    "add top two digits on stack"
  end
end

class VerboseStackEvaluator
  attr_accessor :result, :stack

  def initialize(stack)
    @result = nil
    @stack  = stack
  end

  def pass(op)
    puts op.desc if op.respond_to?(:desc)
    results = op.call(stack)
    self.class.new(results[1]).tap do |x|
      x.result = results[0]
    end
  end

  def self.identity
    new([])
  end
end

class RecursiveLazyStackEvaluator
  def initialize(stack)
    @stack  = stack
  end

  def pass(op)
    self.class.new(lambda {
      op.call(stack)
    })
  end

  def self.identity
    new(lambda { [nil, []] })
  end

  def result; evaled[0]; end
  def stack;  evaled[1]; end

  private

  def evaled
    @evaled ||= @stack.call
  end
end

class LazyStackEvaluator
  attr_accessor :steps

  def initialize(stack, steps = [])
    @stack  = stack
    @steps  = steps
  end

  def pass(op)
    self.class.new(@stack, steps + [op])
  end

  def self.identity
    new([])
  end

  def result; evaled[0]; end
  def stack;  evaled[1]; end

  protected

  def evaled
    @evaled ||= steps.inject([nil, @stack]) {|(r, s), op|
      op.call(s)
    }
  end
end

class OptimizingEvaluator < LazyStackEvaluator
  def evaled
    @evaled ||= begin
      accumulator = []
      new_steps   = []
      steps.each do |step|
        accumulator << step
        if !step.is_a?(PushOperation)
          new_steps += accumulator
          accumulator = []
        elsif accumulator.length > 2
          accumulator = accumulator[1..-1]
        end
      end
      new_steps += accumulator
      new_steps.inject([nil, @stack]) {|(r, s), op|
        op.call(s)
      }
    end
  end
end

class ThreadingEvaluator < LazyStackEvaluator
  attr_accessor :steps
  def evaled
    @evaled ||= begin
      accumulator = []
      workers = []
      steps.each do |step|
        accumulator << step
        if step.is_a?(AddOperation)
          workers << spawn_thread(accumulator)
          accumulator = []
        end
      end
      workers << spawn_thread(accumulator) unless accumulator.empty?
      workers.each(&:join)

      workers.last[:result]
    end
  end

  def spawn_thread(accumulator)
    Thread.new do
      sleep rand / 3
      Thread.current[:result] = begin
        e = accumulator.inject(VerboseStackEvaluator.identity) {|e, s| e.pass(s) }
        [e.result, e.stack]
      end
    end
  end
end

def push_op(value)
  lambda {|x| [value, x + [value]] }
end

def add_op
  lambda {|x| [x[-1] + x[-2], x[0..-3]] }
end

def tagged_push_op(value)
  PushOperation.new(value)
end

def tagged_add_op
  AddOperation.new
end

start_state = []

puts
puts "-- Plain Lambdas"

p [
  push_op(1),
  push_op(2),
  add_op
].inject([nil, []]) {|(result, state), op|
  op[state]
}

puts
puts "-- Composite operations"

ops =
  tagged_push_op(1) +
  tagged_push_op(2) +
  tagged_add_op

puts ops.desc
p ops.run(start_state)

puts
puts "-- Evaluators"
[
  VerboseStackEvaluator,
  RecursiveLazyStackEvaluator,
  LazyStackEvaluator,
  OptimizingEvaluator,
  ThreadingEvaluator
].each do |evaluator|

  puts
  puts "--- #{evaluator}"

  e = evaluator.identity.
    pass(tagged_push_op(1)).
    pass(tagged_push_op(1)).
    pass(tagged_push_op(2)).
    pass(tagged_add_op).
    pass(tagged_push_op(3)).
    pass(tagged_push_op(4)).
    pass(tagged_add_op)

  p [e.result, e.stack]
end
