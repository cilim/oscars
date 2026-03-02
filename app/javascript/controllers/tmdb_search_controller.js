import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "results", "button"]

  connect() {
    this.inputTarget.addEventListener("keydown", (e) => {
      if (e.key === "Enter") { e.preventDefault(); this.search() }
    })
  }

  async search() {
    const query = this.inputTarget.value.trim()
    if (!query) return

    this.buttonTarget.disabled = true
    this.buttonTarget.textContent = "Searching…"
    this.resultsTarget.textContent = ""

    try {
      const url = `/admin/tmdb_search?query=${encodeURIComponent(query)}`
      const res  = await fetch(url, { headers: { "Accept": "application/json" } })
      const data = await res.json()
      this.resultsTarget.textContent = JSON.stringify(data, null, 2)
    } catch (e) {
      this.resultsTarget.textContent = `Error: ${e.message}`
    } finally {
      this.buttonTarget.disabled = false
      this.buttonTarget.textContent = "Search"
    }
  }
}
