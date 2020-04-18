import * as React from 'react';
import * as ReactDOM from 'react-dom';
import './index.css';
import createEngine, { DefaultPortModel, DefaultLinkModel, DiagramModel, DefaultNodeModel } from '@projectstorm/react-diagrams';
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
const node1 = new DefaultNodeModel({ name: 'hi', color: 'rgb(192,255,0)' });
node1.addPort(new DefaultPortModel({in: false, name: 'out'}))
node1.addPort(new DefaultPortModel({in: false, name: 'out 2'}))
node1.setPosition(50, 50);

const node2 = new DefaultNodeModel({ color: 'rgb(0,192,255)' });
node2.addPort(new DefaultPortModel({in: true, name: 'in'}))
node2.setPosition(200, 50);

const link1 = new DefaultLinkModel();
link1.setSourcePort(node1.getPort('out'));
link1.setTargetPort(node2.getPort('in'));
link1.addLabel("13i/s");

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
  productivityBonus: 0.0
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
node5.setPosition(100, 50);
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
link2.addLabel("10/s");

const link3 = new DefaultLinkModel();
link3.setSourcePort(node5.getPort('out-1'));
link3.setTargetPort(node3.getPort('in-1'));
link3.addLabel("5/s");

const link4 = new DefaultLinkModel();
link4.setSourcePort(node6.getPort('out-1'));
link4.setTargetPort(node4.getPort('in-2'));
link4.addLabel("3.33/s");

model.addAll(node3, node4, link2, node5, node6, link3, link4);

//####################################################

// install the model into the engine
engine.setModel(model);

document.addEventListener('DOMContentLoaded', () => {
	ReactDOM.render(<CanvasWidget className="diagram-container" engine={engine} /> , document.querySelector('#application'));
});
