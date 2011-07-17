# A partial prototype implementation of the Disruptor pattern in ruby as described at:
#   http://martinfowler.com/articles/lmax.html
#
# It supports multiple producers, but not mulitple readers (yet). Done just
# to get a rough feel for how much quick it is than using a Queue.
require 'thread'
require 'benchmark'

class QueueTest
  def initialize(n, num_writers)
    @queue = Queue.new
    @n = n
    @num_writers = num_writers
  end

  def run
    sum = 0
    writers = (0..@num_writers-1).map do |x|
      Thread.new do
        (@n / @num_writers).times { @queue.push 1 }
      end
    end

    reader = Thread.new do
      @n.times { sum += @queue.pop }
    end

    writers.each {|x| x.join }
    reader.join
    sum
  end
end

class DisruptorTest
  def initialize(n, num_writers)
    @queue = Array.new(2 ** 21)
    @n = n
    @writer_index = 0
    @reader_index = 0
    @num_writers = num_writers
  end

  def run
    sum = 0
    writers = (0..@num_writers-1).map do |x|
      Thread.new do
        writer_index = x
        (@n / @num_writers).times do |n|
          if @queue[writer_index] != nil
            puts "Dropping message, queue full: #{n}"
            next
          end
          @queue[writer_index] = 1
          writer_index = (writer_index + @num_writers) % @queue.length
        end
      end
    end

    reader = Thread.new do
      @n.times do
        while @queue[@reader_index] == nil
        end
        sum += @queue[@reader_index]
        @queue[@reader_index] = nil
        @reader_index = (@reader_index + 1) % @queue.length
      end
    end

    writers.each {|x| x.join }
    reader.join
    sum
  end
end

n = 900_000
Benchmark.bm do |bm|
  (1..6).each do |x|
    bm.report("Queue,     #{x} writer") { QueueTest.new(n, x).run }
    bm.report("Disruptor, #{x} writer") { DisruptorTest.new(n, x).run }
  end
end
