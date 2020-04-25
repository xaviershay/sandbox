import * as React from 'react'
import { DefaultPortModel, NodeModel } from '@projectstorm/react-diagrams'
import { AbstractReactFactory } from '@projectstorm/react-canvas-core'
import { PortWidget } from '@projectstorm/react-diagrams'

function imageFor(x) {
  if (x == null) return null
  return `/img/icons/${x}.png`
}

export class ProductionNodeWidget extends React.Component {
  render() {
    const { node } = this.props

    const inputPorts = Object.values(node.ports).filter((p) => p.options.in)
    const outputPorts = Object.values(node.ports).filter((p) => !p.options.in)

    const handleAddInputPort = (e) => {
      const portIndex = inputPorts.length + 1
      node.addPort(
        new DefaultPortModel({
          in: true,
          name: 'in-' + portIndex,
          icon: null,
          count: 1,
        })
      )
      node.fireEvent({}, 'nodeStructureChanged')
    }

    const handleAddOutputPort = (e) => {
      console.log('handling a thing')
      const portIndex = outputPorts.length + 1
      node.addPort(
        new DefaultPortModel({
          in: false,
          name: 'out-' + portIndex,
          icon: null,
          count: 1,
        })
      )
      node.fireEvent({}, 'nodeStructureChanged')
    }

    return (
      <div className="production-node">
        <div className="header">{node.options.name}</div>
        <div className="body">
          <div className="inputs">
            {inputPorts.map((p) => (
              <PortWidget
                key={p.options.id}
                engine={this.props.engine}
                port={p}
              >
                <img
                  src={imageFor(p.options.icon)}
                  width="20"
                  height="20"
                  alt={p.options.icon}
                />
                <span onClick={() => console.log('hi')}>{p.options.count}</span>
              </PortWidget>
            ))}
            <div className="port new" onClick={handleAddInputPort}>
              +
            </div>
          </div>
          <div className="assembler">
            {/*Time by Gagana from the Noun Project*/}
            <img
              src="/img/noun_Time_2027684.png"
              width="20"
              height="20"
              alt="Recipe Duration"
            />
            {node.options.duration}s
            <br />
            {/* Time by Alice Design from the Noun Project */}
            <img
              src="/img/noun_Time_2630876.png"
              width="20"
              height="20"
              alt="Crafting Speed"
            />
            {node.options.craftingSpeed}
            <br />
            {/*Gear by Vincencio from the Noun Project*/}
            <img
              src="/img/noun_Gear_3267680.png"
              width="20"
              height="20"
              alt="Productivity Bonus"
            />
            {node.options.productivityBonus > 0
              ? `+${node.options.productivityBonus * 100}%`
              : '-'}
            {node.options.targetRate && (
              <>
                {/*Target by Edward Boatman from the Noun Project*/}
                <br />
                <img
                  src="/img/noun_Target_308.png"
                  width="20"
                  height="20"
                  alt="Target Rate"
                />
                {node.options.targetRate}/s
              </>
            )}
          </div>
          <div className="outputs">
            {outputPorts.map((p) => (
              <PortWidget
                key={p.options.id}
                engine={this.props.engine}
                port={p}
              >
                <span onClick={() => console.log('hi')}>{p.options.count}</span>
                <img
                  src={imageFor(p.options.icon)}
                  width="20"
                  height="20"
                  alt={p.options.icon}
                />
              </PortWidget>
            ))}
            <div className="port new" onClick={handleAddOutputPort}>
              +
            </div>
          </div>
        </div>
      </div>
    )
  }
}

export class ProductionNodeFactory extends AbstractReactFactory {
  constructor() {
    super('production-node')
  }

  generateModel(event) {
    return new ProductionNode()
  }

  generateReactWidget(event) {
    return <ProductionNodeWidget engine={this.engine} node={event.model} />
  }
}

export class ProductionNode extends NodeModel {
  constructor(options = {}) {
    super({
      ...options,
      type: 'production-node',
    })
    //this.color = options.color || { options: 'red' };

    // setup an in and out port
  }

  serialize() {
    return {
      ...super.serialize(),
      //color: this.options.color
    }
  }

  deserialize(ob, engine) {
    super.deserialize(ob, engine)
    //this.color = ob.color;
  }
}
