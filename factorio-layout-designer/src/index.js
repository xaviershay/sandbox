import * as React from 'react';
import * as ReactDOM from 'react-dom';
import './index.css';
import createEngine, { DefaultPortModel, DefaultLinkModel, DiagramModel, DefaultNodeModel } from '@projectstorm/react-diagrams';
import { CanvasWidget } from '@projectstorm/react-canvas-core';
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
model.addAll(node1, node2, link1);

//####################################################

// install the model into the engine
engine.setModel(model);

document.addEventListener('DOMContentLoaded', () => {
	ReactDOM.render(<CanvasWidget className="diagram-container" engine={engine} /> , document.querySelector('#application'));
});
