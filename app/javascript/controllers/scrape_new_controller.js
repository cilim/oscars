import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button"]

  loading() {
    if (this.hasButtonTarget) {
      this.buttonTarget.value    = "Scraping + fetching posters… (this may take ~30s)"
      this.buttonTarget.disabled = true
    }
  }
}
