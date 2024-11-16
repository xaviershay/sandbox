require 'rspec'
require 'gnuplot'
require 'pry'

EPSILON = 0.00000001
BASE = 0
UNCOMMON = 1
RARE = 2
EPIC = 3
LEGENDARY = 4

# Ref: https://wiki.factorio.com/Quality

def assemble(q, distribution, level)
  raise "invalid level: #{level}" if level >= LEGENDARY

  (4 - level).times do |i|
    remaining = distribution[level+i]
    upgraded = remaining * q
    distribution[level+i] -= upgraded
    distribution[level+i+1] += upgraded

    # Subsequent rolls use a constant 10% rather than quality value
    q = 0.1
  end
  distribution
end

def scrap_below_level(q, table, level, recycle_chance: 0.25)
  ds = []

  (BASE..LEGENDARY).each do |l|
    # Take what is there, multiply by 25%, add to new distribution
    d = [0.0, 0.0, 0.0, 0.0, 0.0]
    if l < level
      d[l] = table[l] * recycle_chance
      d = assemble(q, d, l)
    else
      d[l] = table[l]
    end
    ds << d
  end
  ds.transpose.map(&:sum)
end

def recycle_loop(table, assembler_qs, scrap_q, recycle_chance: 0.25, level: LEGENDARY)
  while true
    cont = false
    (BASE...level).to_a.reverse.each do |l|
      next if table[l] < EPSILON
      cont = true
      table = assemble(assembler_qs.fetch(l), table, l)
    end
    break unless cont
    table = scrap_below_level(scrap_q, table, level, recycle_chance: recycle_chance)
  end
  table
end

def base_distribution
  [1.0, 0.0, 0.0, 0.0, 0.0]
end

# How many crafts for different quality values
#   No scraping
#   No scrap quality
#   Scrap with quality

xaxis = (8..25).step(1).map { |x| x / 100.0 }

no_recycling = xaxis.map {|q| recycle_loop(base_distribution, [q] * 5, 0.0, recycle_chance: 0.0).last }
recycling_no_quality = xaxis.map {|q| recycle_loop(base_distribution, [q] * 5, 0.0, recycle_chance: 0.25).last }
recycling_with_quality = xaxis.map {|q| recycle_loop(base_distribution, [q] * 5, q, recycle_chance: 0.25).last }

[no_recycling, recycling_no_quality, recycling_with_quality].each {|xs| xs.map! {|x| (1.0 / x) }}

# Create the plot
Gnuplot.open do |gp|
  Gnuplot::Plot.new(gp) do |plot|
    plot.term 'pngcairo' # Set output format to PNG using Cairo
    plot.output 'chart-1.png' # Set output file name

    plot.title  "Initial Crafts vs Quality %"
    plot.xlabel "Quality %"
    plot.ylabel "Initial Crafts"

    extra = <<-EOS.lines
      set ytics 200
      set mytics 4
      set grid ytics
      set grid mytics
      set xtics nomirror
      set ytics nomirror
    EOS
    plot.arbitrary_lines += extra
    # Set line styles
    #plot.data << Gnuplot::DataSet.new([xaxis, no_recycling]) do |ds|
    #  ds.title = "No Recycling"
    #  ds.with = "linespoints"
    #end

    plot.data << Gnuplot::DataSet.new([xaxis, recycling_no_quality]) do |ds|
      ds.title = "Recycling no quality"
      ds.with = "lines"
    end

    plot.data << Gnuplot::DataSet.new([xaxis, recycling_with_quality]) do |ds|
      ds.title = "Recycling with quality"
      ds.with = "lines"
    end
  end
end
RSpec::Matchers.define :match_floats_within do |expected_array|
  tolerance = EPSILON

  match do |actual_array|
    actual_array.zip(expected_array).all? do |actual_value, expected_value|
      (actual_value - expected_value).abs <= tolerance
    end
  end

  failure_message do |actual_array|
    "expected #{actual_array} to match #{expected_array} within #{tolerance}, but they differ"
  end

  failure_message_when_negated do |actual_array|
    "expected #{actual_array} not to match #{expected_array} within #{tolerance}, but they match"
  end
end

describe 'quality math' do
  example 'assembling with 0% quality does not increase quality' do
    expect(assemble(0.0, base_distribution, BASE)).to \
      match_floats_within(base_distribution)
  end

  example 'assembling with 100% quality' do
    expect(assemble(1.0, base_distribution, BASE)).to \
      match_floats_within([0.0, 0.9, 0.09, 0.009, 0.001])
  end

  example 'assembling with 10% quality matches example from wiki' do
    expect(assemble(0.1, base_distribution, BASE)).to \
      match_floats_within([0.9, 0.09, 0.009, 0.0009, 0.0001])
  end

  example 'assembling with 24.8% quality matches example from wiki' do
    expect(assemble(0.248, base_distribution, BASE)).to \
      match_floats_within([0.752, 0.2232, 0.02232, 0.002232, 0.000248])
  end

  example 'scrap with no quality reduces below specified level to 25%' do
    expect(scrap_below_level(0.0, [1.0, 1.0, 1.0, 1.0, 1.0], RARE)).to \
      match_floats_within([0.25, 0.25, 1.0, 1.0, 1.0])
  end

  example 'scrap with quality increases amounts for quality' do
    expect(scrap_below_level(0.1, [1.0, 1.0, 1.0, 1.0, 1.0], UNCOMMON)).to \
      match_floats_within([0.225, 1.0225, 1.00225, 1.000225, 1.000025])
  end

  example 'scrap with quality increases amounts for each quality' do
    expect(scrap_below_level(0.1, [4.0, 4.0, 0.0, 0.0, 0.0], RARE)).to \
      match_floats_within([0.9, 0.99, 0.099, 0.0099, 0.0011])
  end

  example 'recycle loop at 10%' do
    expect(recycle_loop(base_distribution, [0.1] * 5, 0.1)).to \
      match_floats_within([0, 0, 0, 0, 0.0024102321987805146])
  end
end
