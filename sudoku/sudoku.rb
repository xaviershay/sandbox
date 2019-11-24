# Messing around with solving state-deterministic sudoku problems using
# explicit logic rather than a dynamic programming approach.

require 'set'

Cell = Struct.new(:id, :values, :groups)
Group = Struct.new(:id, :cells)

ALL_VALUES = ->{ Set.new(1..4) }

def new_cell(id, groups)
  Cell.new(id, ALL_VALUES.call, groups)
end

state = [
  new_cell("r1c1", %w(r1 b1)),
  new_cell("r1c2", %w(r1 b1)),
  new_cell("r1c3", %w(r1 b2)),
  new_cell("r1c4", %w(r1 b2)),
  new_cell("r2c1", %w(r2 b1)),
  new_cell("r2c2", %w(r2 b1)),
  new_cell("r2c3", %w(r2 b2)),
  new_cell("r2c4", %w(r2 b2)),
].map {|x| [x.id, x] }.to_h

structure = [
  Group.new("r1", %w(r1c1 r1c2 r1c3 r1c4)),
  Group.new("r2", %w(r2c1 r2c2 r2c3 r2c4)),
  Group.new("b1", %w(r1c1 r1c2 r2c1 r2c2)),
  Group.new("b2", %w(r1c3 r1c4 r2c3 r2c4)),
].map {|x| [x.id, x] }.to_h

constrain = ->(cell_id, values) {
  cell = state[cell_id]
  if cell.values == values
    return
  end
  cell.values = values

  # Rule: if N cells in a group are constrained to the same N values, then no
  # other cell in that group can contain those values.
  #
  # Interesting that N=1 ("specify a number") is a specialization of a more
  # general rule! (N=2 covers "twins")
  #
  # TODO: can probably generalize further to cover hidden twins as well.
  cell.groups.each do |group_id|
    group = structure[group_id]
    group_cells = group.cells.map {|x| state.fetch(x) }
    matching_cells = group_cells.select {|c| c.values == cell.values }
    if matching_cells.length == values.length
      (group_cells - matching_cells).each do |c|
        constrain.call(c.id, c.values - values)
      end
    end
  end
}

constrain.call("r2c1", Set.new([1]))
constrain.call("r2c2", Set.new([2]))
constrain.call("r1c4", Set.new([1]))

puts
# pp structure
pp state
