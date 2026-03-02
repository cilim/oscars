import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["fill", "pickedLabel", "remainingLabel"]
  static values  = { total: Number }

  connect() {
    this.update()
  }

  update() {
    const total   = this.totalValue
    const picked  = this.countPicked()
    const remaining = total - picked
    const pct     = total > 0 ? (picked / total * 100).toFixed(2) : 0

    if (picked === 0) {
      this.fillTarget.hidden = true
    } else {
      this.fillTarget.hidden = false
      this.fillTarget.style.width = `${pct}%`
      this.pickedLabelTarget.textContent = `★ ${picked} picked`
    }
    this.pickedLabelTarget.hidden = picked === 0

    if (remaining > 0) {
      this.remainingLabelTarget.textContent = `${remaining} remaining`
      this.remainingLabelTarget.hidden = false
    } else {
      this.remainingLabelTarget.hidden = true
    }
  }

  countPicked() {
    let count = 0
    document.querySelectorAll("[data-controller~='picks-carousel']").forEach(el => {
      const thinkInput = el.querySelector("[data-picks-carousel-target='thinkInput']")
      const wantInput  = el.querySelector("[data-picks-carousel-target='wantInput']")
      if (thinkInput?.value && wantInput?.value) count++
    })
    return count
  }
}
