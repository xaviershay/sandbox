import React from 'react';
import './App.css';

//import "@projectstorm/react-diagrams/dist/style.min.css"

import createEngine, { 
    DefaultLinkModel, 
    DefaultNodeModel,
    DiagramModel 
} from '@projectstorm/react-diagrams';

import {
    CanvasWidget
} from '@projectstorm/react-canvas-core';

// create an instance of the engine with all the defaults
const engine = createEngine();

// node 1
const node1 = new DefaultNodeModel({
    name: 'Node 1',
    color: 'rgb(0,192,255)',
});
node1.setPosition(100, 100);
let port1 = node1.addOutPort('Copper Cable');
let port3 = node1.addInPort('Copper Plate');

// node 2
const node2 = new DefaultNodeModel({
    name: 'Node 2',
    color: 'rgb(0,192,255)',
});

node2.setPosition(100, 10);
let port2 = node2.addInPort('Copper Cable');
node2.addInPort('Iron Plate');
node2.addOutPort('Green Circuit');

// link them and add a label to the link
const link = port1.link<DefaultLinkModel>(port2);
//link.addLabel('Hello World!');

const model = new DiagramModel();
model.addAll(node1, node2, link);
engine.setModel(model);

const styles = { height: "100vh", width: "90%", backgroundColor: "aliceblue"};

function App() {
  return (
    <div className="app-wrapper">
      <div></div>
      <div style={styles}>
        <CanvasWidget className="canvas" engine={engine} />
      </div>

    </div>
 
  );
}

export default App;
