import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["track", "thinkInput", "wantInput", "thinkSummary", "wantSummary"]
  static values = { seasonId: Number, categoryId: Number }

  connect() {
    this.restoreFromStorage()
    this.updateAllCards()
  }

  // ── localStorage ───────────────────────────────────────

  get storageKey() {
    return `oscars_picks_${this.seasonIdValue}_cat_${this.categoryIdValue}`
  }

  restoreFromStorage() {
    try {
      const saved = localStorage.getItem(this.storageKey)
      if (!saved) return
      const { think, want } = JSON.parse(saved)
      this.thinkInputTarget.value = think ?? ""
      this.wantInputTarget.value  = want  ?? ""
    } catch (_) {}
  }

  saveToStorage() {
    try {
      localStorage.setItem(this.storageKey, JSON.stringify({
        think: this.thinkInputTarget.value || null,
        want:  this.wantInputTarget.value  || null
      }))
    } catch (_) {}
  }

  clearStorage() {
    localStorage.removeItem(this.storageKey)
  }

  // ── Actions ────────────────────────────────────────────

  toggleThink(event) {
    const id = event.currentTarget.dataset.nomineeId
    this.thinkInputTarget.value = (this.thinkInputTarget.value === id) ? "" : id
    this.updateAllCards()
    this.saveToStorage()
    this.scheduleAutoSave()
  }

  toggleWant(event) {
    const id = event.currentTarget.dataset.nomineeId
    this.wantInputTarget.value = (this.wantInputTarget.value === id) ? "" : id
    this.updateAllCards()
    this.saveToStorage()
    this.scheduleAutoSave()
  }

  scheduleAutoSave() {
    clearTimeout(this._saveTimer)
    this._saveTimer = setTimeout(() => {
      this.element.closest("form")?.requestSubmit()
    }, 800)
  }

  prev() {
    this.scrollTrack(-1)
  }

  next() {
    this.scrollTrack(1)
  }

  scrollTrack(dir) {
    const track = this.trackTarget
    const slide = track.querySelector("[data-slide]")
    if (!slide) return
    // Scroll 3 cards at a time (card width + gap)
    const step = (slide.offsetWidth + 12) * 3
    track.scrollBy({ left: dir * step, behavior: "smooth" })
  }

  // ── UI update ──────────────────────────────────────────

  updateAllCards() {
    const thinkId = this.thinkInputTarget.value
    const wantId  = this.wantInputTarget.value

    this.trackTarget.querySelectorAll("[data-slide]").forEach(slide => {
      const id      = slide.dataset.nomineeId
      const isThink = thinkId === id && id !== ""
      const isWant  = wantId  === id && id !== ""

      // Data attributes drive CSS styling (see application.css)
      slide.dataset.isThink = isThink ? "true" : "false"
      slide.dataset.isWant  = isWant  ? "true" : "false"

      // Badges: toggle hidden attribute
      const thinkBadge = slide.querySelector("[data-think-badge]")
      const wantBadge  = slide.querySelector("[data-want-badge]")
      if (thinkBadge) thinkBadge.hidden = !isThink
      if (wantBadge)  wantBadge.hidden  = !isWant

      // Button active state
      const thinkBtn = slide.querySelector("[data-think-btn]")
      const wantBtn  = slide.querySelector("[data-want-btn]")
      if (thinkBtn) thinkBtn.dataset.active = isThink ? "true" : "false"
      if (wantBtn)  wantBtn.dataset.active  = isWant  ? "true" : "false"
    })

    this.updateSummary(thinkId, wantId)
    this.dispatch("changed")
  }

  updateSummary(thinkId, wantId) {
    const names = {}
    this.trackTarget.querySelectorAll("[data-slide]").forEach(slide => {
      names[slide.dataset.nomineeId] = slide.dataset.nomineeName
    })

    if (this.hasThinkSummaryTarget) {
      this.thinkSummaryTarget.textContent = names[thinkId] || "—"
      this.thinkSummaryTarget.classList.toggle("text-sky-600",    !!names[thinkId])
      this.thinkSummaryTarget.classList.toggle("text-oscar-muted", !names[thinkId])
    }
    if (this.hasWantSummaryTarget) {
      this.wantSummaryTarget.textContent = names[wantId] || "—"
      this.wantSummaryTarget.classList.toggle("text-violet-600",  !!names[wantId])
      this.wantSummaryTarget.classList.toggle("text-oscar-muted", !names[wantId])
    }
  }
}
