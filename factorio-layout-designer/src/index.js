import * as React from 'react';
import * as ReactDOM from 'react-dom';
import './index.css';
import createEngine, { DefaultPortModel, DefaultLinkModel, DiagramModel} from '@projectstorm/react-diagrams';
import { CanvasWidget } from '@projectstorm/react-canvas-core';
import {ProductionNode, ProductionNodeFactory} from './ProductionNode'
/*
import { JSCustomNodeFactory } from './custom-node-js/JSCustomNodeFactory';
import { TSCustomNodeFactory } from './custom-node-ts/TSCustomNodeFactory';
import { JSCustomNodeModel } from './custom-node-js/JSCustomNodeModel';
import { TSCustomNodeModel } from './custom-node-ts/TSCustomNodeModel';
*/
//import { BodyWidget } from './BodyWidget';

// create an instance of the engine
const engine = createEngine();

// register the two engines
/*
engine.getNodeFactories().registerFactory(new JSCustomNodeFactory() as any);
engine.getNodeFactories().registerFactory(new TSCustomNodeFactory());
*/

engine.getNodeFactories().registerFactory(new ProductionNodeFactory());

// create a diagram model
const model = new DiagramModel();

//####################################################
// now create two nodes of each type, and connect them

//const node1 = new JSCustomNodeModel({ color: 'rgb(192,255,0)' });
//const node1 = new DefaultNodeModel({ name: 'hi', color: 'rgb(192,255,0)' });
//node1.addPort(new DefaultPortModel({in: false, name: 'out'}))
//node1.addPort(new DefaultPortModel({in: false, name: 'out 2'}))
//node1.setPosition(50, 50);
//
//const node2 = new DefaultNodeModel({ color: 'rgb(0,192,255)' });
//node2.addPort(new DefaultPortModel({in: true, name: 'in'}))
//node2.setPosition(200, 50);
//
//const link1 = new DefaultLinkModel();
//link1.setSourcePort(node1.getPort('out'));
//link1.setTargetPort(node2.getPort('in'));
//link1.addLabel("13i/s");

/*
const node3 = new ProductionNode({
  name: 'Copper Cable',
  duration: 0.5,
  craftingSpeed: 1.25,
  productivityBonus: 0.20
});
node3.setPosition(300, 50);
node3.addPort(
  new DefaultPortModel({
    in: true,
    name: 'in-1',
    icon: 'copper-plate',
    count: 1,
  })
);
node3.addPort(
  new DefaultPortModel({
    in: false,
    name: 'out-1',
    icon: 'copper-cable',
    count: 2,
  })
);

const node5 = new ProductionNode({
  name: 'Furnace',
  duration: 2,
  craftingSpeed: 2,
  productivityBonus: 0
})
node5.setPosition(100, 50);
node5.addPort(
  new DefaultPortModel({
    in: false,
    name: 'out-1',
    icon: 'copper-plate',
    count: 1,
  })
);
*/

const node3 = new ProductionNode({
  name: 'Copper Cable',
  duration: 0.5,
  craftingSpeed: 1.25,
  productivityBonus: 0.20
});
node3.setPosition(300, 50);
node3.addPort(
  new DefaultPortModel({
    in: true,
    name: 'in-1',
    icon: 'copper-plate',
    count: 1,
  })
);
node3.addPort(
  new DefaultPortModel({
    in: false,
    name: 'out-1',
    icon: 'copper-cable',
    count: 2,
  })
);

const node4 = new ProductionNode({
  name: 'Green Circuit',
  duration: 0.5,
  craftingSpeed: 0.75,
  productivityBonus: 0.0,
  targetRate: 10
});
node4.addPort(
  new DefaultPortModel({
    in: true,
    name: 'in-1',
    icon: 'copper-cable',
    count: 3,
  })
);
node4.addPort(
  new DefaultPortModel({
    in: true,
    name: 'in-2',
    icon: 'iron-plate',
    count: 1,
  })
);
node4.addPort(
  new DefaultPortModel({
    in: false,
    name: 'out-1',
    icon: 'green-circuit',
    count: 1,
  })
);
node4.setPosition(650, 100);

const node5 = new ProductionNode({
  name: 'Furnace',
  duration: 2,
  craftingSpeed: 2,
  productivityBonus: 0
})
node5.setPosition(50, 50);
node5.addPort(
  new DefaultPortModel({
    in: false,
    name: 'out-1',
    icon: 'copper-plate',
    count: 1,
  })
);

const node6 = new ProductionNode({
  name: 'Furnace',
  duration: 2,
  craftingSpeed: 2,
  productivityBonus: 0
})
node6.setPosition(400, 250);
node6.addPort(
  new DefaultPortModel({
    in: false,
    name: 'out-1',
    icon: 'iron-plate',
    count: 1,
  })
);

const link2 = new DefaultLinkModel();
link2.setSourcePort(node3.getPort('out-1'));
link2.setTargetPort(node4.getPort('in-1'));

const link3 = new DefaultLinkModel();
link3.setSourcePort(node5.getPort('out-1'));
link3.setTargetPort(node3.getPort('in-1'));

const link4 = new DefaultLinkModel();
link4.setSourcePort(node6.getPort('out-1'));
link4.setTargetPort(node4.getPort('in-2'));

let models = model.addAll(node3, node4, link2, node5, node6, link3, link4);
/*
const link3 = new DefaultLinkModel();
link3.setSourcePort(node5.getPort('out-1'));
link3.setTargetPort(node3.getPort('in-1'));
link3.addLabel("5/s");

let models = model.addAll(node3, node5, link3);
*/
class ProductionSolver {
  constructor() {
    this.nodes = []
    this.variables = {}
    this.objective = {}
    this.constraints = []
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
        [nodeVar.name]: 1
      }
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

    let constraint = {
      range: [0, 0],
      coefficients: {
        [nodeVar.name]: rate,
      }
    }

    links.forEach(link => {
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
    links.forEach(link => {
      const supplierVar = this.linkVar(link, 'OUTPUT')
      const consumerVar = this.linkVar(link, 'INPUT')

      // The consuming end of the link must be no greater than the supplyind
      // end.
      {
        const constraint = {
          range: [0, Number.POSITIVE_INFINTIY],
          coefficients: {
            [supplierVar.name]: 1,
            [consumerVar.name]: -1
          }
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
    Object.values(this.variables).forEach(v => {
      variableHash[v.name] = v.range
    })
    const doc = {
      variables: variableHash,
      constraints: this.constraints,
      objective: {
        type: 'min',
        coefficients: this.objective
      }
    }
    return JSON.stringify(doc)
  }

  nodeVar(node, type) {
    return this.variableFor(node.options.id, type, node.options.name)
  }

  linkVar(link, type) {
    let name = 'link'
    if (type === "INPUT") {
      name = [link.targetPort.parent.options.name, link.targetPort.options.icon].join('-')
    } else if (type === 'OUTPUT') {
      name = [link.sourcePort.parent.options.name, link.sourcePort.options.icon].join('-')
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
      range: [0, Number.POSITIVE_INFINITY]
    }

    this.variables[varId] = newVar;
    return newVar;
  }
}
models.forEach(item => {
  item.registerListener({
    eventDidFire: e => {
      switch (e.function) {
        case 'nodeStructureChanged':
          engine.repaintCanvas()
          break;
        default:
          // it's fine
      }
    }
  })
})

//####################################################

// install the model into the engine
engine.setModel(model);

const App = () => {
  const handleSerialize = () => {
    console.log(engine.getModel().serialize())
  }

  const handleSolve = async () => {
    const model = engine.getModel();
    const nodes = model.getNodes();
    const links = model.getLinks();

    let solver = new ProductionSolver();
    nodes.forEach(node => {
      solver.addNode(node)

      if (node.options.targetRate) {
        solver.addTarget(node4, 10)
      }

      Object.values(node.ports).forEach(port => {
        const links = Object.values(port.links)
        if (links.length > 0) {
          solver.addRatio(node, links, port.options.count, port.options.in ? 'INPUT' : 'OUTPUT')

          if (port.options.in) {
            solver.addInputLinks(node, links)
          }
        }
      })
    })
    const solverEndpoint =
      "https://sa6mifk9pb.execute-api.us-east-1.amazonaws.com/solveLP"

    try {
      const solution = await fetch(solverEndpoint, {
        method: 'post',
        body: solver.toJson()
      })

      const jsonSolution = await solution.json()

      if (jsonSolution.solved) {
        links.forEach(link => {
          // Link throughput is the maximum, i.e. the supply solution. The
          // consumer solution may be less than this if the consumer is
          // buffering.
          const v = solver.linkVar(link, 'INPUT')
          link.labels.length = 0
          link.addLabel(jsonSolution.variables[v.name] + "/s")
        });
        engine.repaintCanvas()
      } else {
        console.log("no solution")
      }
    } catch(e) {
      console.log("Error trying to solve", e)
    }
  }

  handleSolve()

  return (
    <div style={{width: "100%", height: "100%"}}>
      <div>
        <button onClick={handleSerialize}>Serialize</button>
        <button onClick={handleSolve}>Solve</button>
      </div>
      <CanvasWidget className="diagram-container" engine={engine} />
    </div>
  )
}

document.addEventListener('DOMContentLoaded', () => {
	ReactDOM.render(<App /> , document.querySelector('#application'));
});
