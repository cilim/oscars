import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "template", "item", "destroyField"]

  add() {
    const content = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, Date.now())
    this.containerTarget.insertAdjacentHTML("beforeend", content)
  }

  remove(event) {
    const item = event.target.closest("[data-nested-pick-types-target='item']")
    const destroyField = item.querySelector("[data-nested-pick-types-target='destroyField']")

    if (destroyField && destroyField.name.includes("[id]")) {
      destroyField.value = "1"
      item.classList.add("hidden")
    } else {
      item.remove()
    }
  }
}
