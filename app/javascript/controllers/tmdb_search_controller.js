import { Controller } from "@hotwired/stimulus"

// Movie form Apply-to-form + scrape JSON dump share this controller.
export default class extends Controller {
  static targets = ["input", "results", "button", "posterField", "descriptionField", "imdbField"]

  connect() {
    if (!this.hasInputTarget) return

    this.inputTarget.addEventListener("keydown", (e) => {
      if (e.key === "Enter") { e.preventDefault(); this.search() }
    })
  }

  async search() {
    const query = this.inputTarget.value.trim()
    if (!query) return

    this.buttonTarget.disabled = true
    this.buttonTarget.textContent = "Searching…"
    this.clearResults()

    try {
      const url = `/admin/tmdb_search?query=${encodeURIComponent(query)}`
      const res  = await fetch(url, { headers: { "Accept": "application/json" } })
      const data = await res.json()
      if (this.hasPosterFieldTarget) {
        this.renderCards(Array.isArray(data) ? data : [])
      } else {
        this.resultsTarget.textContent = JSON.stringify(data, null, 2)
      }
    } catch (e) {
      this.resultsTarget.textContent = `Error: ${e.message}`
    } finally {
      this.buttonTarget.disabled = false
      this.buttonTarget.textContent = "Search"
    }
  }

  applySuggestion(event) {
    this.applyData(event.currentTarget.dataset)
  }

  async applyResult(event) {
    const { tmdbId, posterUrl, overview } = event.currentTarget.dataset
    this.applyData({ posterUrl, description: overview, imdbUrl: "" })

    if (!tmdbId) return

    try {
      const res = await fetch(`/admin/tmdb_search?tmdb_id=${encodeURIComponent(tmdbId)}`, {
        headers: { "Accept": "application/json" }
      })
      const data = await res.json()
      this.applyData({
        posterUrl: data.poster_url,
        description: data.description,
        imdbUrl: data.imdb_url
      })
    } catch (_e) {
      // Search fields already filled from the list result.
    }
  }

  applyData({ posterUrl, description, imdbUrl }) {
    if (this.hasPosterFieldTarget && posterUrl) this.posterFieldTarget.value = posterUrl
    if (this.hasDescriptionFieldTarget && description) this.descriptionFieldTarget.value = description
    if (this.hasImdbFieldTarget && imdbUrl) this.imdbFieldTarget.value = imdbUrl
  }

  renderCards(results) {
    this.resultsTarget.replaceChildren()
    if (!results.length) {
      this.resultsTarget.textContent = "No results"
      return
    }

    results.forEach((result) => {
      const button = document.createElement("button")
      button.type = "button"
      button.className = "w-full text-left border border-oscar-border rounded-lg p-2 hover:border-oscar-gold bg-white space-y-1"
      button.dataset.action = "click->tmdb-search#applyResult"
      if (result.tmdb_id) button.dataset.tmdbId = result.tmdb_id
      if (result.poster_url) button.dataset.posterUrl = result.poster_url
      if (result.overview) button.dataset.overview = result.overview

      const title = document.createElement("div")
      title.className = "font-semibold text-oscar-text"
      title.textContent = [result.title, result.year].filter(Boolean).join(" · ")
      button.appendChild(title)

      if (result.overview) {
        const overview = document.createElement("div")
        overview.className = "text-oscar-muted leading-relaxed"
        overview.textContent = result.overview
        button.appendChild(overview)
      }

      this.resultsTarget.appendChild(button)
    })
  }

  clearResults() {
    if (this.hasPosterFieldTarget) {
      this.resultsTarget.replaceChildren()
    } else {
      this.resultsTarget.textContent = ""
    }
  }
}
