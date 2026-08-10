import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["multiToggle", "maxSelections"]

  connect() {
    this.syncMaxSelectionsField()
  }

  toggleMulti() {
    this.syncMaxSelectionsField()
  }

  syncMaxSelectionsField() {
    if (!this.hasMultiToggleTarget || !this.hasMaxSelectionsTarget) return

    const enabled = this.multiToggleTarget.checked
    const input = this.maxSelectionsTarget.querySelector("input")

    this.maxSelectionsTarget.classList.toggle("hidden", !enabled)

    if (!input) return

    input.disabled = !enabled
    if (!enabled) {
      input.value = ""
    } else if (!input.value || Number(input.value) < 2) {
      input.value = "2"
    }
  }
}
