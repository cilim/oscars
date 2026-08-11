import { Controller } from "@hotwired/stimulus"

// Lets a decorative "palette" trigger open a native color input, and
// paints the resulting color onto the controller's own element (used to
// tint a pick type card's border to match its chosen color).
export default class extends Controller {
  static targets = ["input"]

  connect() {
    this.applyColor()
  }

  open() {
    if (!this.inputTarget.disabled) this.inputTarget.click()
  }

  applyColor() {
    this.element.style.borderColor = this.inputTarget.value
  }
}
