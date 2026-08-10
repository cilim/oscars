import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "popover"]

  connect() {
    this.outsideClick = (event) => {
      if (!this.element.contains(event.target)) this.hide()
    }
  }

  disconnect() {
    document.removeEventListener("click", this.outsideClick)
  }

  toggle(event) {
    event.stopPropagation()
    if (this.popoverTarget.classList.contains("hidden")) {
      this.show()
    } else {
      this.hide()
    }
  }

  show() {
    this.popoverTarget.classList.remove("hidden")
    document.addEventListener("click", this.outsideClick)
  }

  hide() {
    this.popoverTarget.classList.add("hidden")
    document.removeEventListener("click", this.outsideClick)
  }

  select(event) {
    const emoji = event.detail?.unicode || event.detail?.emoji?.unicode
    if (emoji) {
      this.inputTarget.value = emoji
      this.inputTarget.dispatchEvent(new Event("input", { bubbles: true }))
    }
    this.hide()
  }
}
