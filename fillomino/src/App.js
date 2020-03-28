import React, {useState} from 'react';
import classNames from 'classnames';
import isEqual from 'lodash/isEqual';
import useHotkeys from '@reecelucas/react-use-hotkeys';
import { List } from 'immutable';

import './App.css';


function App() {
  return (
    <div className="App">
      <Board rows={2} columns={2} />
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

  const handleClick = (x, y) => () => {
    setSelected([y, x])
  }

  window.grid = grid;
  useHotkeys("1", () => {
    if (selected !== null) {
      setGrid(grid.setIn([...selected, "value"], 1));
    }
  })

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

function Cell({x, y, selected, value, onClick}) {
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
  >
    <span className="value">{value}</span>
  </div>
}
export default App;
