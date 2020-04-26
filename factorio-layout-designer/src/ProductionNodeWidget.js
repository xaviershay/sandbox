import React, { useState, useEffect, useCallback } from 'react'
import uniqBy from 'lodash/uniqBy'
import PortIcon from './PortIcon'
import UIIcon from './UIIcon'

const ProductionNodeWidget = ({ engine, node }) => {
  // STATE

  const [editable, setEditable] = useState(null)

  // A click event is sent to our elements after a drag action completes, but
  // we only want to handle them when no drag happened. This state allows up to
  // track that.
  const [moved, setMoved] = useState(false)

  let defaultPortValues = {}
  Object.values(node.ports).forEach((port) => {
    defaultPortValues[port.options.label] = port.options.count
  })
  const [editableValues, setEditableValues] = useState({
    name: node.name,
    duration: node.duration,
    craftingSpeed: node.craftingSpeed,
    productivityBonus: node.productivityBonus,
    targetRate: node.targetRate || '',
    ports: defaultPortValues,
  })

  const forceUpdate = React.useReducer(() => ({}))[1]

  // EVENT HANDLERS
  const handleInputChange = (e) => {
    const { name, value } = e.target
    setEditableValues({ ...editableValues, [name]: value })
  }

  const handlePortInputChange = (e) => {
    const { name, value } = e.target
    setEditableValues({
      ...editableValues,
      ports: { ...editableValues.ports, [name]: value },
    })
  }

  const handleAddPort = (type) => (e) => {
    const portName = type === 'INPUT' ? node.addInput() : node.addOutput()
    setEditableValues({
      ...editableValues,
      ports: { ...editableValues.ports, [portName]: 1 },
    })
    forceUpdate()
  }

  const handleSubmit = useCallback(() => {
    node.update({
      name: parseFloat(editableValues.name),
      duration: parseFloat(editableValues.duration),
      craftingSpeed: parseFloat(editableValues.craftingSpeed),
      productivityBonus: parseFloat(editableValues.productivityBonus),
      targetRate: parseFloat(editableValues.targetRate),
    })
    Object.entries(editableValues.ports).forEach(([portName, value]) => {
      node.ports[portName].options.count = parseFloat(value)
    })
    setEditable(null)
  }, [node, editableValues])

  const handleMouseUp = (name) => {
    if (!moved) {
      setEditable(name)
    }
    setMoved(false)
  }

  const handleChangeIcon = (port, icon) => {
    // Find all ports connected to this one, then change all of their icons.
    // For each source/target port in links, change icon
    let seen = {}
    let affectedNodes = []

    let f = (port) => {
      if (!port) return
      if (seen[port.options.id]) return

      seen[port.options.id] = true
      port.options.icon = icon
      affectedNodes.push(port.parent)

      Object.values(port.links).forEach((link) => {
        f(link.sourcePort)
        f(link.targetPort)
      })
    }
    f(port)
    uniqBy(affectedNodes, (n) => n.options.id).forEach((node) => {
      node.fireEvent({}, 'repaint')
    })
  }

  // EFFECTS

  useEffect(() => {
    return engine.registerListener({
      repaintCanvas: forceUpdate,
    }).deregister
  }, [engine, forceUpdate])

  useEffect(() => {
    node.setLocked(editable !== null)
  }, [node, editable])

  useEffect(
    () =>
      node.registerListener({
        eventDidFire: (e) => {
          switch (e.function) {
            case 'selectionChanged':
              // submit onBlur
              if (!e.isSelected) {
                handleSubmit()
              }
              break
            case 'positionChanged':
              if (!moved) {
                setMoved(true)
              }
              break
            case 'repaint':
              forceUpdate()
              break
            default:
            // it's ok
          }
        },
      }).deregister,
    [node, handleSubmit, moved, forceUpdate]
  )

  // COMPONENTS

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
          onMouseDown={(e) => e.stopPropagation()}
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

  const editablePortInput = (port) => {
    const name = port.options.label

    if (editable) {
      return (
        <input
          name={name}
          value={editableValues.ports[name]}
          onFocus={(e) => e.currentTarget.select()}
          autoFocus={editable === ['port', name].join('-')}
          onChange={handlePortInputChange}
          onMouseDown={(e) => e.stopPropagation()}
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

  // RENDER

  const nodeStyle = node.isSelected() ? { borderColor: 'white' } : {}

  return (
    <div
      className="production-node"
      onMouseDown={() => setEditable(null)}
      style={nodeStyle}
    >
      <div className="header">{editableInput({ name: 'name' })}</div>
      <div className="body">
        <div className="inputs">
          {node.inputPorts.map((p) => (
            <div key={p.options.id} className="port-container">
              <PortIcon
                engine={engine}
                port={p}
                onChangeIcon={(icon) => handleChangeIcon(p, icon)}
              />
              {editablePortInput(p)}
            </div>
          ))}
          <div className="port-container new" onClick={handleAddPort('INPUT')}>
            +
          </div>
        </div>
        <div className="assembler">
          <div className="row">
            <UIIcon name="duration" />
            {editableInput({ name: 'duration', format: (x) => `${x}s` })}
          </div>
          <div className="row">
            <UIIcon name="craftingSpeed" />
            {editableInput({ name: 'craftingSpeed' })}
          </div>
          <div className="row">
            <UIIcon name="productivityBonus" />
            {editableInput({
              name: 'productivityBonus',
              format: (x) => (x > 0 ? `+${x * 100}%` : '-'),
            })}
          </div>
          <div className="row">
            <UIIcon name="targetRate" />
            {editableInput({
              name: 'targetRate',
              format: (x) => (x > 0 ? `${x}/s` : '-'),
            })}
          </div>
          <div className="row">
            <UIIcon name="assemblersRequired" />
            <span>
              {((x) => (x > 0 ? Math.round(x * 100) / 100 : '-'))(
                node.assemblersRequired
              )}
            </span>
          </div>
        </div>
        <div className="outputs">
          {node.outputPorts.map((p) => (
            <div className="port-container" key={p.options.id}>
              {editablePortInput(p)}
              <PortIcon
                engine={engine}
                port={p}
                onChangeIcon={(icon) => handleChangeIcon(p, icon)}
              />
            </div>
          ))}
          <div className="port-container new" onClick={handleAddPort('OUTPUT')}>
            +
          </div>
        </div>
      </div>
    </div>
  )
}

export default ProductionNodeWidget
