import {
  SelectingState,
  State,
  Action,
  InputType,
  DragCanvasState,
} from '@projectstorm/react-canvas-core'
import {
  PortModel,
  DragNewLinkState,
  DiagramEngine,
  DragDiagramItemsState,
} from '@projectstorm/react-diagrams'

// Override default interaction handler to restrict mouse down events to left
// click only.
export default class DiagramState extends State<DiagramEngine> {
  constructor() {
    super({
      name: 'default-diagrams',
    })
    this.childStates = [new SelectingState()]
    this.dragCanvas = new DragCanvasState()
    this.dragNewLink = new DragNewLinkState()
    this.dragNewLink.config.allowLooseLinks = false
    this.dragItems = new DragDiagramItemsState()

    // determine what was clicked on
    this.registerAction(
      new Action({
        type: InputType.MOUSE_DOWN,
        fire: (event) => {
          // Only respond to left click
          if (event.event.button !== 0) {
            return
          }
          const element = this.engine
            .getActionEventBus()
            .getModelForEvent(event)

          // the canvas was clicked on, transition to the dragging canvas state
          if (!element) {
            this.transitionWithEvent(this.dragCanvas, event)
          }
          // initiate dragging a new link
          else if (element instanceof PortModel) {
            this.transitionWithEvent(this.dragNewLink, event)
          }
          // move the items (and potentially link points)
          else {
            this.transitionWithEvent(this.dragItems, event)
          }
        },
      })
    )
  }
}
