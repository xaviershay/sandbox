import React, {useState} from 'react';
import classNames from 'classnames';
import isEqual from 'lodash/isEqual';
import useHotkeys from '@reecelucas/react-use-hotkeys';
import { List, Set } from 'immutable';

import './App.css';


function App() {
  return (
    <div className="App">
      <Board rows={3} columns={3} />
    </div>
  );
}

const cellSizePx = 50;

function Board({rows, columns}) {
  const newCell = () => { return {
    value: null,
  }}
  const initialGrid = List(Array(columns).fill().map((_, y) =>
                        List(Array(rows).fill().map((_, x) => newCell()))))

  const [selected, setSelected] = useState(null);
  const [grid, setGrid] = useState(initialGrid);

  const decomposeValue =
    n => [n].concat(n >= 10 ? decomposeValue(Math.floor(n / 10)) : [])
  const knownValues =
    Set(grid.flatMap(rows => rows.flatMap(n => decomposeValue(n.value))).filter(Boolean))

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
        setGrid(grid.updateIn([...selected, "value"], old => old * 10 + i))
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

  return (
    <div className="board" style={{width: cellSizePx * columns + 3, height: cellSizePx * rows + 3}}>
      {Array(columns).fill().flatMap((_, y) =>
        Array(rows).fill().map((_, x) =>
          <Cell
            x={x}
            y={y}
            value={grid.get(y).get(x).value}
            selected={isEqual([y, x], selected)}
            onClick={handleClick(x, y)}
            key={[x, y]}
          />
        )
      )}
    </div>
  )
}

// For rounded inner borders:
// * Create a div with size border*2,  border-radius 50% (a circle)
// * Absolute position to left/bottom, with negative margin if needed (will depend on corner)
// * clip path on parent div
function Cell({x, y, selected, value, onClick}) {
  const [bounds, setBounds] = useState(null);

  return <div
    className={classNames("cell", {
      firstInRow: x === 0,
      firstInColumn: y === 0,
      selected: selected,
    })}
    style={{
      width: cellSizePx,
      height: cellSizePx
    }}
    data-x={x}
    data-y={y}
    onClick={onClick}

    // TODO: Do something with this
    onMouseDown={e => console.log("drag start", e.clientX - bounds[0], e)}
    ref={el => {
      if (el) {
        const rect = el.getBoundingClientRect()
        const newBounds = [rect.x, rect.y]
        if (!isEqual(bounds, newBounds)) {
          setBounds(newBounds)
        }
      }
    }}
  >
    <span className="value">{value}</span>
  </div>
}
export default App;
