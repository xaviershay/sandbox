import * as React from 'react';
import { DefaultPortModel, NodeModel } from '@projectstorm/react-diagrams';
import { AbstractReactFactory } from '@projectstorm/react-canvas-core';
import { PortWidget } from '@projectstorm/react-diagrams';

function imageFor(x) {
    return `/img/icons/${x}.png`
}

export class ProductionNodeWidget extends React.Component {
	render() {
        const {node} = this.props;
        console.log(node)

        const inputPorts = Object.values(node.ports).filter(p => p.options.in)
        const outputPorts = Object.values(node.ports).filter(p => !p.options.in)

		return (
			<div className="production-node">
              <div className="header">{node.options.name}</div>
              <div className="body">
                <div className="inputs">
                    {inputPorts.map(p => 
                        <PortWidget key={p.options.id} engine={this.props.engine} port={p}>
                        <img src={imageFor(p.options.icon)} width="20" height="20" />
                        <span onClick={() => console.log("hi")}>{p.options.count}</span>
                        </PortWidget>
                    )}
                    <div className="port new">
                    +
                    </div>
                </div>
                <div className="assembler">
                {/*Time by Gagana from the Noun Project*/}
                  <img src="/img/noun_Time_2027684.png" width="20" height="20" />
                  {node.options.duration}s
                  <br />
                  {/* Time by Alice Design from the Noun Project */}
                  <img src="/img/noun_Time_2630876.png" width="20" height="20" />
                  {node.options.craftingSpeed}
                  <br />
                    {/*Gear by Vincencio from the Noun Project*/}
                  <img src="/img/noun_Gear_3267680.png" width="20" height="20" />
                  {node.options.productivityBonus > 0 ? `+${node.options.productivityBonus * 100}%` : "-"}
                </div>
                <div className="outputs">
                    {outputPorts.map(p => 
                        <PortWidget key={p.options.id} engine={this.props.engine} port={p}>
                        <span onClick={() => console.log("hi")}>{p.options.count}</span>
                        <img src={imageFor(p.options.icon)} width="20" height="20" />
                        </PortWidget>
                    )}
                    <div className="port new">
                    +
                    </div>
                </div>
              </div>
			</div>
		);
	}
}

export class ProductionNodeFactory extends AbstractReactFactory {
	constructor() {
		super('production-node');
	}

	generateModel(event) {
		return new ProductionNode();
	}

	generateReactWidget(event) {
		return <ProductionNodeWidget engine={this.engine} node={event.model} />;
	}
}

export class ProductionNode extends NodeModel {
	constructor(options = {}) {
		super({
			...options,
			type: 'production-node'
		});
		//this.color = options.color || { options: 'red' };

		// setup an in and out port
	}

	serialize() {
		return {
			...super.serialize(),
			//color: this.options.color
		};
	}

	deserialize(ob, engine) {
		super.deserialize(ob, engine);
		//this.color = ob.color;
	}
}