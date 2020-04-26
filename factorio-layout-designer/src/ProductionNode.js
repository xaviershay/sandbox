import React from 'react'
import { DefaultPortModel, NodeModel } from '@projectstorm/react-diagrams'
import { AbstractReactFactory } from '@projectstorm/react-canvas-core'
import ProductionNodeWidget from './ProductionNodeWidget'

class ProductionPortModel extends DefaultPortModel {}

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
  }

  get id() {
    return this.options.id
  }
  get name() {
    return this.options.name
  }
  get duration() {
    return this.options.duration
  }
  get craftingSpeed() {
    return this.options.craftingSpeed
  }
  get productivityBonus() {
    return this.options.productivityBonus
  }
  get targetRate() {
    return this.options.targetRate
  }
  get targetRateUnits() {
    return this.options.targetRateUnits
  }
  get targetRateInSeconds() {
    if (!this.options.targetRate) {
      return null
    }

    const multiplier = {
      s: 1,
      m: 1 / 60.0,
      h: 1 / 60.0 / 60.0,
    }[this.targetRateUnits]

    if (!multiplier) {
      throw new Error(`Unknown target rate unit: ${this.targetRateUnits}`)
    }
    return this.targetRate * multiplier
  }

  get inputPorts() {
    return Object.values(this.ports).filter((p) => p.options.in)
  }
  get outputPorts() {
    return Object.values(this.ports).filter((p) => !p.options.in)
  }

  update(values) {
    this.options = {
      ...this.options,
      ...values,
    }
  }

  addOutput() {
    const portName = 'out-' + (this.outputPorts.length + 1)
    this.addPort(
      new ProductionPortModel({
        in: false,
        name: portName,
        icon: null,
        count: 1,
      })
    )
    return portName
  }

  addInput() {
    const portName = 'in-' + (this.inputPorts.length + 1)
    this.addPort(
      new ProductionPortModel({
        in: true,
        name: portName,
        icon: null,
        count: 1,
      })
    )
    return portName
  }

  get assemblersRequired() {
    const { calculatedRate } = this.options

    if (!calculatedRate) return null

    // Copied from Foreman, machines have to wait for a new tick before
    // starting a new item, so round up to nearest tick (assume 60fps). Return
    // fractional assemblers even though not possible in reality in order to
    // help user adjust and tweak.
    return (
      Math.ceil((this.duration / this.craftingSpeed) * calculatedRate * 60) / 60
    )
  }

  set calculatedRate(x) {
    this.options.calculatedRate = x
  }

  serialize() {
    return {
      ...super.serialize(),
    }
  }

  deserialize(ob, engine) {
    super.deserialize(ob, engine)
  }
}
