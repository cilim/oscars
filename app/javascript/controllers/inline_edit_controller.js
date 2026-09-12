import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["display", "editor", "input"]

  edit(event) {
    event.preventDefault()
    this.displayTarget.hidden = true
    this.editorTarget.hidden = false
    if (this.hasInputTarget) this.inputTarget.focus()
  }
}
