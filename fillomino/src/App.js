// @flow

import React, {useState} from 'react';
import classNames from 'classnames';
import isEqual from 'lodash/isEqual';
import inRange from 'lodash/inRange';
import sortBy from 'lodash/sortBy';
import useHotkeys from '@reecelucas/react-use-hotkeys';
import { List, Set } from 'immutable';

import './App.css';

// TODO:
// * Inner corners for borders
// * Outer borders
// * Auto-border
// * serder state
// * store state in URL
// * separate out "givens" from guesses

type CellType = {
  x: number,
  y: number,
  value: ?number,
  complete?: boolean,
  borders: {
    "left": boolean,
    "right": boolean,
    "top": boolean,
    "bottom": boolean,
  }
}

function App() {
  return (
    <div className="App">
      <Board rows={3} columns={3} />
    </div>
  );
}

const cellSizePx = 50;

// This is important to be able to a) get mouse drag events outside the grid,
// and b) to make room for rendering outside borders.
const boardPadding = cellSizePx;

function Board({rows, columns}) {
  const newCell : (number, number) => CellType = (x, y) => { return {
    x: x,
    y: y,
    value: null,
    borders: {
      "left": false,
      "right": false,
      "top": false,
      "bottom": false,
    },
  }}
  const initialGrid = List(Array(columns).fill().map((_, y) =>
                        List(Array(rows).fill().map((_, x) => newCell(x, y)))))
    .updateIn([0,0], c => { return {...c,
      value: 1,
      borders: {
        "left": true,
        "right": false,
        "top": true,
        "bottom": true,
      }
    }})
    .updateIn([1,0], c => { return {...c,
      value: 4,
      borders: {
        "left": false,
        "right": true,
        "top": true,
        "bottom": true,
      }
    }})
    .updateIn([1,1], c => { return {...c,
      value: 3,
      borders: {
        "left": true,
        "right": true,
        "top": false,
        "bottom": false,
      }
    }})
    .updateIn([1,2], c => { return {...c,
      value: 3,
      borders: {
        "left": true,
        "right": false,
        "top": true,
        "bottom": true,
      }
    }})
    .updateIn([0,2], c => { return {...c,
      value: 5,
      borders: {
        "left": false,
        "right": false,
        "top": false,
        "bottom": true,
      }
    }})
    .updateIn([2,0], c => { return { ...c,
      value: 5,
      borders: {
        "left": false,
        "right": false,
        "top": true,
        "bottom": false,
      }
    }})
    .updateIn([2,2], c => { return {...c,
      value: 5,
      borders: {
        "left": false,
        "right": false,
        "top": true,
        "bottom": false,
      }
    }})

  const [selected, setSelected] = useState(null);
  const [grid, setGrid] = useState(initialGrid);
  const [bounds, setBounds] = useState({left: 0, top: 0});

  const decomposeValue : (number) => Array<number> =
    n => [n].concat(n >= 10 ? decomposeValue(Math.floor(n / 10)) : [])
  const knownValues =
    Set(grid.flatMap(rows => rows.map(c => c.value).filter(Boolean).flatMap(decomposeValue)))

  const handleClick = (x, y) => () => {
    setSelected([y, x])
  }

  for (let i = 0; i <= 9; i++) {
    useHotkeys("" + i, () => { // eslint-disable-line
      if (selected !== null) {
        setGrid(grid.updateIn([...selected, "value"], old => {
          if (old != null) {
            const candidate = old * 10 + i;
            if (knownValues.has(candidate)) {
              return candidate
            }
          }
          return i;
        }));
      }
    })
    useHotkeys("Control+" + i, () => { // eslint-disable-line
      if (selected !== null) {
        setGrid(grid.updateIn([...selected, "value"], old => old ? old * 10 + i : i))
      }
    })
  }
  [" ", "Backspace"].forEach(mapping =>
    useHotkeys(mapping, () => { // eslint-disable-line
      if (selected !== null) {
        setGrid(grid.setIn([...selected, "value"], null))
      }
    })
  )

  const moveSelected = (dx, dy) => {
    if (selected) {
      setSelected([(selected[0] + dy + rows) % rows, (selected[1]+dx+rows) % columns])
    } else {
      setSelected([0,0])
    }
  }
  useHotkeys("ArrowLeft", () => moveSelected(-1, 0))
  useHotkeys("ArrowRight", () => moveSelected(1, 0))
  useHotkeys("ArrowUp", () => moveSelected(0, -1))
  useHotkeys("ArrowDown", () => moveSelected(0, 1))
  useHotkeys("Escape", () => setSelected(null))

  const getMatchingNeighbours = cellToMatch => {
    const f = (cellToMatch, cell, seen) => {
      seen = seen.add(cell)

      if (cellToMatch.value == cell.value) {
        const cs = Object.values(neighbours(cell.x, cell.y)).filter(Boolean).filter(c => !seen.has(c))

        return cs.reduce([[cell], seen], (a, v) => {
          const [matches, seen] = a
          const [newMatches, newSeen] = f(cellToMatch, v, seen);

          return [matches.concat(newMatches), newSeen];
        })
      } else {
        return [[], seen];
      }

    }
    const [matches, seen] = f(cellToMatch, cellToMatch, Set())
    return matches
  }

  const grid2 = grid.map((cs, y) => cs.map((c, x) => {
    if (c.value) {
      if (getMatchingNeighbours(c).length == c.value) {
        return {...c, complete: true};
      }
    }
    return c;
  }))

  const lookupCell = (x, y) => {
    const row = grid2.get(y)
    if (!row) {
      throw new Error("Assertion failed: row " + y + " does not exist in grid")
    }
    const cell = row.get(x);
    if (!cell) {
      throw new Error("Assertion failed: column " + x + " does not exist in grid")
    }
    return cell;
  }
  const neighbours = (x,y) => { return {
    left: x > 0 ? lookupCell(x - 1, y) : null,
    right: x < columns - 1 ? lookupCell(x + 1, y) : null,
    top: y > 0 ? lookupCell(x, y - 1) : null,
    bottom: y < rows - 1 ? lookupCell(x, y + 1) : null,
  }}

  const [startPoint, setStartPoint] = useState(null)
  const [endPoint, setEndPoint] = useState(null)

  const handleMouseDown = e => {
    const
      x = e.clientX - bounds.left - boardPadding,
      y = e.clientY - bounds.top - boardPadding;

    const
      coordX = Math.round(x / cellSizePx),
      coordY = Math.round(y / cellSizePx)

    if (inRange(coordX, 0, columns + 1) && inRange(coordY, 0, rows + 1)) {
      setStartPoint({x: coordX, y: coordY})
    }
  }

  const handleMouseMove = e => {
    const
      x = e.clientX - bounds.left - boardPadding,
      y = e.clientY - bounds.top - boardPadding;

    const
      coordX = x / cellSizePx,
      coordY = y / cellSizePx
    if (startPoint !== null) {
      const possiblePoints = [
        {x: startPoint.x - 1, y: startPoint.y},
        {x: startPoint.x + 1, y: startPoint.y},
        {x: startPoint.x, y: startPoint.y - 1},
        {x: startPoint.x, y: startPoint.y + 1},
      ].filter(p => inRange(p.x, 0, columns + 1) && inRange(p.y, 0, rows + 1))

      if (possiblePoints.length === 0) {
        throw new Error("Assertion failed: no possible points")
      }

      const bestPoint = sortBy(
        possiblePoints,
        p => Math.sqrt((coordX - p.x) ** 2 + (coordY - p.y) ** 2)
      )[0]

      if (!bestPoint) {
        throw new Error("Assertion failed: no bestPoint")
      }

      // TODO: Min distance threshold?
      setEndPoint(bestPoint)
    } else {
      throw new Error("Assertion failed: handleMouseMove called when no startPoint")
    }
  }

  const handleMouseUp = e => {
    // TODO: Sometimes a click event registers at same time, but we don't want
    // both! Probably replace click handler with something here.
    if (startPoint && endPoint) {
      let newGrid = grid
      if (endPoint.y === startPoint.y) {
        const topCell = [endPoint.y - 1, Math.min(startPoint.x, endPoint.x)]
        const bottomCell = [endPoint.y, Math.min(startPoint.x, endPoint.x)]

        if (topCell[0] >= 0)
          newGrid = newGrid.updateIn([...topCell, "borders", "bottom"], x => !x);

        if (bottomCell[0] < columns)
          newGrid = newGrid.updateIn([...bottomCell, "borders", "top"], x => !x)

      } else if (endPoint.x === startPoint.x) {
        const leftCell = [Math.min(startPoint.y, endPoint.y), endPoint.x - 1]
        const rightCell = [Math.min(startPoint.y, endPoint.y), endPoint.x]

        if (leftCell[1] >= 0)
          newGrid = newGrid.updateIn([...leftCell, "borders", "right"], x => !x);

        if (rightCell[1] < columns)
          newGrid = newGrid.updateIn([...rightCell, "borders", "left"], x => !x)
      } else {
        throw new Error("Assertion failed: shouldn't be able to get here")
      }
      setGrid(newGrid);
    }

    setStartPoint(null);
    setEndPoint(null);
  }

  return (
    <div
      ref={el => {
        if (el) {
          const rect = el.getBoundingClientRect()
          const newBounds = {left: rect.left, top: rect.top}
          if (!isEqual(bounds, newBounds)) {
            setBounds(newBounds)
          }
        }
      }}
      onMouseDown={handleMouseDown}
      onMouseMove={startPoint ? handleMouseMove : null}
      onMouseUp={handleMouseUp}
      className="board"
      style={{
        width: cellSizePx * columns + 3,
        height: cellSizePx * rows + 3,
        padding: boardPadding,
      }}
    >
      {Array(columns).fill().flatMap((_, y) =>
        Array(rows).fill().map((_, x) =>
          <Cell
            x={x}
            y={y}
            neighbours={neighbours(x, y)}
            data={lookupCell(x, y)}
            selected={isEqual([y, x], selected)}
            onClick={handleClick(x, y)}
            key={[x, y].join('-')}
          />
        )
      )}
      {startPoint && endPoint &&
        <>
          <div
            className="startPoint"
            style={{
              left: boardPadding + startPoint.x * cellSizePx,
              top:  boardPadding + startPoint.y * cellSizePx
            }}
          ></div>
          <div
            className="startPoint"
            style={{
              left: boardPadding + endPoint.x * cellSizePx,
              top:  boardPadding + endPoint.y * cellSizePx
            }}
          ></div>
        </>
      }
    </div>
  )
}

// For rounded inner borders:
// * Create a div with size border*2,  border-radius 50% (a circle)
// * Absolute position to left/bottom, with negative margin if needed (will depend on corner)
// * clip path on parent div
function Cell({x, y, selected, data, onClick, neighbours}) {
  const {value, borders, complete} = data;

  const corners = {
    bottomLeft: neighbours.left && neighbours.bottom && !borders.left && neighbours.left.borders.bottom && !borders.bottom && neighbours.bottom.borders.left,
    bottomRight: neighbours.right && neighbours.bottom && !borders.right && neighbours.right.borders.bottom && !borders.bottom && neighbours.bottom.borders.right,
    topLeft: neighbours.left && neighbours.top && !borders.left && neighbours.left.borders.top && !borders.top && neighbours.top.borders.left,
    topRight: neighbours.right && neighbours.top && !borders.right && neighbours.right.borders.top && !borders.top && neighbours.top.borders.right,
  }

  return <div
    className={classNames("cell", {
      firstInRow: x === 0,
      firstInColumn: y === 0,
      selected: selected,
      borderLeft: borders["left"],
      borderRight: borders["right"],
      borderTop: borders["top"],
      borderBottom: borders["bottom"],
      complete: complete,
    })}
    style={{
      width: cellSizePx,
      height: cellSizePx,
      left: boardPadding + (cellSizePx * x),
      top: boardPadding + (cellSizePx * y),
    }}
    data-x={x}
    data-y={y}
    onClick={onClick}
  >
    <span
      className="value"
      style={{
      }}
    >{value}</span>
    {borders.bottom && <div className="border bottom" ></div> }
    {borders.top && <div className="border top" ></div> }
    {borders.left && <div className="border left" ></div> }
    {borders.right && <div className="border right" ></div> }
    {corners.bottomLeft &&
      <div
        className="corner bottomLeft"
        style={{
          left: 0,
          bottom: 0
        }}
      ></div>
    }
    {corners.bottomRight &&
      <div
        className="corner bottomRight"
        style={{
          right: 0,
          bottom: 0
        }}
      ></div>
    }
    {corners.topLeft &&
      <div
        className="corner topLeft"
        style={{
          left: 0,
          top: 0
        }}
      ></div>
    }
    {corners.topRight &&
      <div
        className="corner topRight"
        style={{
          right: 0,
          top: 0
        }}
      ></div>
    }
  </div>
}
export default App;
