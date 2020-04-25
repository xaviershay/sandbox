import React, { useState, useEffect, useCallback } from 'react'
import { DefaultPortModel, NodeModel } from '@projectstorm/react-diagrams'
import { AbstractReactFactory } from '@projectstorm/react-canvas-core'
import { PortWidget } from '@projectstorm/react-diagrams'

function imageFor(x) {
  if (x == null) return null
  return `/img/icons/${x}.png`
}

export const ProductionNodeWidget = ({ engine, node }) => {
  const [editable, setEditable] = useState(null)

  const [editableValues, setEditableValues] = useState({
    name: node.options.name,
    duration: node.options.duration,
    craftingSpeed: node.options.craftingSpeed,
    productivityBonus: node.options.productivityBonus,
    targetRate: node.options.targetRate || '',
  })

  const handleInputChange = (e) => {
    const { name, value } = e.target
    setEditableValues({ ...editableValues, [name]: value })
  }

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
    engine.repaintCanvas()
  }

  const handleAddOutputPort = (e) => {
    const portIndex = outputPorts.length + 1
    node.addPort(
      new DefaultPortModel({
        in: false,
        name: 'out-' + portIndex,
        icon: null,
        count: 1,
      })
    )
    engine.repaintCanvas()
  }

  useEffect(() => {
    node.setLocked(editable !== null)
  }, [node, editable])

  const handleSubmit = useCallback(() => {
    node.options.name = editableValues.name
    node.options.duration = editableValues.duration
    node.options.craftingSpeed = editableValues.craftingSpeed
    node.options.productivityBonus = editableValues.productivityBonus
    node.options.targetRate = editableValues.targetRate
    setEditable(null)
  }, [node, editableValues])

  useEffect(() => {
    const handle = node.registerListener({
      eventDidFire: (e) => {
        if (e.function === 'selectionChanged' && !e.isSelected) {
          handleSubmit()
        }
      },
    })
    return () => handle.deregister()
  }, [node, handleSubmit])

  const editableInput = ({ name, format }) => {
    if (format == null) {
      format = (x) => x
    }

    if (editable) {
      return (
        <input
          name={name}
          value={editableValues[name]}
          onFocus={(e) => e.currentTarget.select()}
          autoFocus={editable === name}
          onChange={handleInputChange}
          onKeyDown={(e) => {
            if (e.keyCode === 13) {
              handleSubmit()
            }
          }}
        />
      )
    } else {
      return (
        <span onDoubleClick={() => setEditable(name)}>
          {format(editableValues[name])}
        </span>
      )
    }
  }

  return (
    <div className="production-node">
      <div className="header">{editableInput({ name: 'name' })}</div>
      <div className="body">
        <div className="inputs">
          {inputPorts.map((p) => (
            <PortWidget key={p.options.id} engine={engine} port={p}>
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
          {editableInput({ name: 'duration', format: (x) => `${x}s` })}
          <br />
          {/* Time by Alice Design from the Noun Project */}
          <img
            src="/img/noun_Time_2630876.png"
            width="20"
            height="20"
            alt="Crafting Speed"
          />
          {editableInput({ name: 'craftingSpeed' })}
          <br />
          {/*Gear by Vincencio from the Noun Project*/}
          <img
            src="/img/noun_Gear_3267680.png"
            width="20"
            height="20"
            alt="Productivity Bonus"
          />
          {editableInput({
            name: 'productivityBonus',
            format: (x) => (x > 0 ? `+${x * 100}%` : '-'),
          })}

          {/*Target by Edward Boatman from the Noun Project*/}
          <br />
          <img
            src="/img/noun_Target_308.png"
            width="20"
            height="20"
            alt="Target Rate"
          />
          {editableInput({
            name: 'targetRate',
            format: (x) => (x > 0 ? `${x}/s` : '-'),
          })}
        </div>
        <div className="outputs">
          {outputPorts.map((p) => (
            <PortWidget key={p.options.id} engine={engine} port={p}>
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
