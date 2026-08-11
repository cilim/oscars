import { Controller } from "@hotwired/stimulus"

// Drag-and-drop reordering for pick type cards. A card only becomes
// draggable once its grip handle is pressed (see #armDrag), so dragging
// text inside inputs still works normally. Order is recalculated from
// DOM position on every drop and again on submit, as a safety net.
export default class extends Controller {
  static targets = ["orderInput"]

  armDrag(event) {
    const item = event.currentTarget.closest("[data-nested-pick-types-target='item']")
    if (item) item.draggable = true
  }

  dragStart(event) {
    this.dragging = event.currentTarget
    event.dataTransfer.effectAllowed = "move"
    event.dataTransfer.setData("text/plain", "")
    event.currentTarget.classList.add("opacity-40")
  }

  dragOver(event) {
    event.preventDefault()
    const target = event.currentTarget
    if (!this.dragging || target === this.dragging) return

    const rect = target.getBoundingClientRect()
    const isBefore = event.clientX - rect.left < rect.width / 2
    target.parentNode.insertBefore(this.dragging, isBefore ? target : target.nextSibling)
  }

  drop(event) {
    event.preventDefault()
  }

  dragEnd(event) {
    event.currentTarget.classList.remove("opacity-40")
    event.currentTarget.draggable = false
    this.dragging = null
    this.renumber()
  }

  renumber() {
    this.orderInputTargets.forEach((input, index) => {
      input.value = index + 1
    })
  }
}
