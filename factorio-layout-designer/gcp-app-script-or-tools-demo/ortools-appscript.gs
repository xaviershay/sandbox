function test() {
  const data = {
    variables: {
      x: [0, 10],
      y: [0, 5],
      z: [4,4],
    },
    constraints: [
      {
        range: [0, 10],
        coefficients: {x: 2, y: 5}
      },
      {
        range: [0, 20],
        coefficients: {x: 10, y: 3}
      }
    ],
    objective: {
      type: 'max',
      coefficients: {
        x: 1,
        y: 2
      }
    }
  }

  Logger.log(solveLP(data));
}

function solveLP(params) {
  Logger.log(JSON.stringify(params))

  var engine = LinearOptimizationService.createEngine();

  Object.entries(params.variables).forEach(([k, v]) => {
    engine.addVariable(k, v[0], v[1])
  })

  params.constraints.forEach(c => {
    var constraint = engine.addConstraint(c.range[0], c.range[1]);
    Object.entries(c.coefficients).forEach(([k, v]) => {
      constraint.setCoefficient(k, v);
    });
  })

  Object.entries(params.objective.coefficients).forEach(([k, v]) => {
    engine.setObjectiveCoefficient(k, v);
  });

  switch (params.objective.type) {
    case 'max':
      engine.setMaximization()
      break;
    default:
      throw new Error("Unsupported objective type: " + type)
  }

  var solution = engine.solve();

  if (!solution.isValid()) {
    Logger.log('No solution ' + solution.getStatus());
    return JSON.stringify({
      solved: false,
      status: solution.getStatus()
    })
  } else {
    var ret = {
      solved: true,
      variables: {}
    }

    Object.keys(params.variables).forEach(k => {
      ret.variables[k] = solution.getVariableValue(k)
    })
    return JSON.stringify(ret)
  }
}
