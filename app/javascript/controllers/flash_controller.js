import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["message"]

  connect() {
    this.messageTargets.forEach((message) => {
      setTimeout(() => {
        message.style.transition = "opacity 0.5s ease-out"
        message.style.opacity = "0"
        setTimeout(() => message.remove(), 500)
      }, 4000)
    })
  }

  remove(event) {
    event.target.remove()
  }
}
