import React, { useState, useEffect, useCallback } from 'react'
import { DefaultPortModel, NodeModel } from '@projectstorm/react-diagrams'
import { AbstractReactFactory } from '@projectstorm/react-canvas-core'
import { PortWidget } from '@projectstorm/react-diagrams'

function imageFor(x) {
  if (x == null) return "/img/transparent.png";
  return `/img/icons/${x}.png`
}

class ProductionPortModel extends DefaultPortModel {
}

export const ProductionNodeWidget = ({ engine, node }) => {
  const [editable, setEditable] = useState(null)

  // A click event is sent to our elements after a drag action completes, but
  // we only want to handle them when no drag happened. This state allows up to
  // track that.
  const [moved, setMoved] = useState(false)

  let defaultPortValues = {}
  Object.values(node.ports).forEach(port => {
    defaultPortValues[port.options.label] = port.options.count
  })
  const [editableValues, setEditableValues] = useState({
    name: node.options.name,
    duration: node.options.duration,
    craftingSpeed: node.options.craftingSpeed,
    productivityBonus: node.options.productivityBonus,
    targetRate: node.options.targetRate || '',
    ports: defaultPortValues,
  })

  const handleInputChange = (e) => {
    const { name, value } = e.target
    setEditableValues({ ...editableValues, [name]: value })
  }

  const handlePortInputChange = (e) => {
    const { name, value } = e.target
    setEditableValues({
      ...editableValues,
      ports: {...editableValues.ports, [name]: value}
    })
  }

  const inputPorts = Object.values(node.ports).filter((p) => p.options.in)
  const outputPorts = Object.values(node.ports).filter((p) => !p.options.in)

  const handleAddInputPort = (e) => {
    const portIndex = inputPorts.length + 1
    node.addPort(
      new ProductionPortModel({
        in: true,
        name: 'in-' + portIndex,
        icon: null,
        count: 1,
      })
    )
    setEditableValues({
      ...editableValues,
      ports: {...editableValues.ports, ['in-' + portIndex]: 1}
    })
    engine.repaintCanvas()
  }

  const handleAddOutputPort = (e) => {
    const portIndex = outputPorts.length + 1
    node.addPort(
      new ProductionPortModel({
        in: false,
        name: 'out-' + portIndex,
        icon: null,
        count: 1,
      })
    )
    setEditableValues({
      ...editableValues,
      ports: {...editableValues.ports, ['out-' + portIndex]: 1}
    })
    engine.repaintCanvas()
  }

  useEffect(() => {
    node.setLocked(editable !== null)
  }, [node, editable])

  const handleSubmit = useCallback(() => {
    node.options.name = parseFloat(editableValues.name)
    node.options.duration = parseFloat(editableValues.duration)
    node.options.craftingSpeed = parseFloat(editableValues.craftingSpeed)
    node.options.productivityBonus = parseFloat(editableValues.productivityBonus)
    node.options.targetRate = parseFloat(editableValues.targetRate)
    Object.entries(editableValues.ports).forEach(([portName, value]) => {
      node.ports[portName].options.count = parseFloat(value)
    })
    setEditable(null)
  }, [node, editableValues])

  useEffect(() => {
    const handle = node.registerListener({
      eventDidFire: (e) => {
        if (e.function === 'selectionChanged' && !e.isSelected) {
          handleSubmit()
        } else if (!moved && e.function === 'positionChanged') {
          setMoved(true)
        }
      },
    })
    return () => handle.deregister()
  }, [node, handleSubmit, moved])

  const handleMouseUp = name => {
    if (!moved) {
      setEditable(name)
    }
    setMoved(false)
  }
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
          onMouseDown={e => e.stopPropagation() }
          onKeyDown={(e) => {
            if (e.keyCode === 13) {
              handleSubmit()
            }
          }}
        />
      )
    } else {
      return (
        <span
          onMouseDown={() => setMoved(false)}
          onMouseUp={() => handleMouseUp(name)}
        >
          {format(editableValues[name])}
        </span>
      )
    }
  }

  const editablePortInput = port => {
    const name = port.options.label

    if (editable) {
      return (
        <input
          name={name}
          value={editableValues.ports[name]}
          onFocus={(e) => e.currentTarget.select()}
          autoFocus={editable === ['port', name].join('-')}
          onChange={handlePortInputChange}
          onMouseDown={e => e.stopPropagation() }
          onKeyDown={(e) => {
            if (e.keyCode === 13) {
              handleSubmit()
            }
          }}
        />
      )
    } else {
      return (
        <span
          onMouseDown={() => setMoved(false)}
          onMouseUp={() => handleMouseUp(['port', name].join('-'))}
        >
          {editableValues.ports[name]}
        </span>
      )
    }
  }

  return (
    <div className="production-node"
    onMouseDown={() => setEditable(null)}
    >
      <div className="header">{editableInput({ name: 'name' })}</div>
      <div className="body">
        <div className="inputs">
          {inputPorts.map((p) =>
            <div key={p.options.id} className='port-container'>
              <PortWidget key={p.options.id} engine={engine} port={p}>
                <img
                  draggable={false}
                  src={imageFor(p.options.icon)}
                  width="20"
                  height="20"
                  alt={p.options.icon}
                />
              </PortWidget>
              {editablePortInput(p)}
            </div>
          )}
          <div className="port-container new" onClick={handleAddInputPort}>
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
          {outputPorts.map((p) =>
            <div className='port-container' key={p.options.id}>
            {editablePortInput(p)}
            <PortWidget key={p.options.id} engine={engine} port={p}>
              <img
                draggable={false}
                src={imageFor(p.options.icon)}
                width="20"
                height="20"
                alt={p.options.icon}
              />
            </PortWidget>
            </div>
          )}
          <div className="port-container new" onClick={handleAddOutputPort}>
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
