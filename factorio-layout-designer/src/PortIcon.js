import React from 'react'
import { PortWidget } from '@projectstorm/react-diagrams'
import ReactModal from 'react-modal'
import { useModal } from 'react-modal-hook'

function imageFor(x) {
  if (x == null) return '/img/transparent.png'
  return `/img/icons/${x}.png`
}

const PortIcon = ({ engine, port, onChangeIcon }) => {
  const icon = port.options.icon
  const [showModal, hideModal] = useModal(() => (
    <ReactModal
      isOpen
      className="icon-picker"
      overlayClassName="icon-picker-overlay"
      onRequestClose={hideModal}
    >
      <input placeholder="Search" />
      <div>
        {['iron-plate', 'copper-plate', 'copper-cable', 'green-circuit'].map(
          (icon) => (
            <button
              key={icon}
              onClick={() => {
                hideModal()
                onChangeIcon(icon)
              }}
            >
              <img src={imageFor(icon)} height="20" width="20" alt={icon} />
            </button>
          )
        )}
      </div>
    </ReactModal>
  ))

  return (
    <div
      onContextMenu={(e) => {
        e.preventDefault()
        e.stopPropagation()
        showModal()
      }}
    >
      <PortWidget engine={engine} port={port}>
        <img
          draggable={false}
          src={imageFor(icon)}
          width="20"
          height="20"
          alt={icon}
        />
      </PortWidget>
    </div>
  )
}

export default PortIcon
