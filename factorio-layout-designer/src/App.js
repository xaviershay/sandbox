import React from 'react';
import logo from './logo.svg';
import './App.css';
import numeric from 'numeric';

//import SimpleSimplex from 'simple-simplex'

/*
var lp=numeric.solveLP(
      [-9,-5,-6,-4],
      [
        [6,3,5,2],[-1,0,0,0],[1,0,0,0],[0,-1,0,0],[0,1,0,0],[0,0,-1,0],[0,0,1,0],[0,0,0,-1],[0,0,0,1]],
      [10,0,1,0,1,0,1,0,1]
    );
    */

// WORKS: minimize two variables such that a >= 5, b >= 1
{
  const lp = numeric.solveLP(
    [1, 1],
    [
      [-1, 0],
      [0, -1],
    ],
    [-5, -1]
  )

  console.log(lp)
  console.log(lp.solution)
}

// WORKS a >= 50, a - b <= 0 (a <= b)
{
  const lp = numeric.solveLP(
    [1, 1],
    [
      [-1, 0],
      [1, -1]
    ],
    [-50, 0]
  )

  console.log(lp)
  console.log(lp.solution)
}

// DOES NOT WORK a >= 50, 3a - b <= 0 (3a <= b)
{
  const lp = numeric.solveLP(
    [1, 1],
    [
      [-1, 0],
      [3, -1]
    ],
    [-50, 0]
  )

  console.log(lp)
  console.log(lp.solution)
}
/*
import solver from 'javascript-lp-solver'
const model = {
    "optimize": {
      "green-node": "min",
      "cable-var": "min",
    },
    "constraints": {
      "green": {"min": 10},
    },
    "variables": {
      "green-node": {"green": 1},
      "cable-var": {"green": -3, "cable": 1}
    },
}
    
console.log(solver.Solve(model));
*/

// want to min rate of all nodes

/*
// initialize a solver
const solver = new SimpleSimplex({
  objective: {
    green: -1,
    copper: 0,
  },
  constraints: [
    {
      namedVector: { copper: 3, green: -3},
      constraint: '>=',
      constant: 0,
    },
    {
      namedVector: { copper: 0, green: 1},
      constraint: '<=',
      constant: -10,
    },
  ],
  optimizationType: 'max',
});
 
// call the solve method with a method name
const result = solver.solve({
  methodName: 'simplex',
});
 
// see the solution and meta data
console.log(result.solution.coefficients)
console.log({
  solution: result.solution,
  isOptimal: result.details.isOptimal,
});
*/

function App() {
  return (
    <div className="App">
      <header className="App-header">
        <img src={logo} className="App-logo" alt="logo" />
        <p>
          Edit <code>src/App.js</code> and save to reload.
        </p>
        <a
          className="App-link"
          href="https://reactjs.org"
          target="_blank"
          rel="noopener noreferrer"
        >
          Learn React
        </a>
      </header>
    </div>
  );
}

export default App;
