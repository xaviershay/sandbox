// Ported from
// https://bitbucket.org/PowellNGL/foreman/pull-requests/17/do-not-merge-progress-modal-new-solver/diff#chg-Foreman/Models/Solver/GoogleSolver.cs
//
// It uses an or-tools webservice.
export default class ProductionSolver {
  constructor() {
    this.nodes = []
    this.variables = {}
    this.objective = {}
    this.constraints = []
    this.endpoint =
      'https://sa6mifk9pb.execute-api.us-east-1.amazonaws.com/solveLP'
  }

  addNode(node) {
    const v = this.nodeVar(node, 'ACTUAL')

    // The rate of all nodes should be minimized
    this.objective[v.name] = 1.0
  }

  // Ensure that the solution has a rate matching desired for this node.
  // Typically there will one of these on the ultimate output node, though
  // multiple are supported, on any node. If there is a conflict, a 'best
  // effort' solution will be returned, where some nodes actual rates will not
  // match the desired asked for here.
  //
  // TODO: Best effort not support yet, need to add error variables
  addTarget(node, desiredRate) {
    const nodeVar = this.nodeVar(node, 'ACTUAL')

    const constraint = {
      range: [desiredRate, desiredRate],
      coefficients: {
        [nodeVar.name]: 1,
      },
    }

    this.constraints.push(constraint)
  }

  // Ensure that the sum on the end of all the links is in relation to the rate
  // of the recipe. The given rate is always for a single execution of the
  // recipe, so the ratio is always (X1 + X2 + ... + XN)*Rate:1
  //
  // For example, if a copper wire recipe (1 plate makes 2 wires) is connected
  // to two different consumers, then the sum of the wire rate flowing over
  // those two links must be equal to 2 time the rate of the recipe.  For the
  // steel input to a solar panel, the sum of every input variable to this node
  // must equal 5 * rate.
  addRatio(node, links, rate, type) {
    const nodeVar = this.nodeVar(node, 'ACTUAL')

    // Output ratios are increased by any productivity bonus attached to the
    // node.
    const productivity = 1 + (type === 'OUTPUT' ? node.productivityBonus : 0)

    let constraint = {
      range: [0, 0],
      coefficients: {
        [nodeVar.name]: rate * productivity,
      },
    }

    links.forEach((link) => {
      const linkVar = this.linkVar(link, type)
      constraint.coefficients[linkVar.name] = -1
    })

    this.constraints.push(constraint)
  }

  // Constrain input to a node for a particular item so that the node does not
  // consume more than is being produced by the supplier.
  //
  // Consuming less than is being produced is fine. This represents a backup.
  addInputLinks(node, links, rate) {
    links.forEach((link) => {
      const supplierVar = this.linkVar(link, 'OUTPUT')
      const consumerVar = this.linkVar(link, 'INPUT')

      // The consuming end of the link must be no greater than the supplyind
      // end.
      {
        const constraint = {
          range: [0, Number.POSITIVE_INFINTIY],
          coefficients: {
            [supplierVar.name]: 1,
            [consumerVar.name]: -1,
          },
        }
        this.constraints.push(constraint)
      }

      // TODO:
      // Minimize over-supply. Necessary for unbalanced diamond recipe chains
      // (such as Yuoki smelting - this doesn't occur in Vanilla) where the
      // deficit is made up by an infinite supplier, in order to not just grab
      // everything from that supplier and let produced materials backup. Also,
      // this is needed so that resources don't "pool" in pass-through nodes.
      //
      // TODO: A more correct solution for pass-through would be to forbid
      // over-supply on them.
    })
  }

  toJson() {
    let variableHash = {}
    Object.values(this.variables).forEach((v) => {
      variableHash[v.name] = v.range
    })
    const doc = {
      variables: variableHash,
      constraints: this.constraints,
      objective: {
        type: 'min',
        coefficients: this.objective,
      },
    }
    return JSON.stringify(doc)
  }

  async solve() {
    try {
      const solution = await fetch(this.endpoint, {
        method: 'post',
        body: this.toJson(),
      })

      const jsonSolution = await solution.json()

      if (jsonSolution.solved) {
        return jsonSolution.variables
      } else {
        return null
      }
    } catch (e) {
      console.log(e)
      return null
    }
  }

  nodeVar(node, type) {
    return this.variableFor(node.id, type, node.name)
  }

  linkVar(link, type) {
    let name = 'link'
    if (type === 'INPUT') {
      name = [
        link.targetPort.parent.options.name,
        link.targetPort.options.icon,
      ].join('-')
    } else if (type === 'OUTPUT') {
      name = [
        link.sourcePort.parent.options.name,
        link.sourcePort.options.icon,
      ].join('-')
    }
    return this.variableFor(link.options.id, type, name)
  }

  variableFor(objectId, type, name) {
    const varId = [objectId, type].join(':')
    if (this.variables[varId]) {
      return this.variables[varId]
    }

    const newVar = {
      name: [name, type, Object.keys(this.variables).length + 1].join(','),
      range: [0, Number.POSITIVE_INFINITY],
    }

    this.variables[varId] = newVar
    return newVar
  }
}
