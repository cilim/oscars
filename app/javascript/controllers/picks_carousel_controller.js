import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["track", "pickTypeGroup", "pickInput", "summary"]
  static values = {
    seasonId: Number,
    categoryId: Number,
    pickTypes: Array
  }

  connect() {
    this.restoreFromStorage()
    this.updateAllCards()
  }

  get storageKey() {
    return `oscars_picks_${this.seasonIdValue}_cat_${this.categoryIdValue}`
  }

  restoreFromStorage() {
    try {
      const saved = localStorage.getItem(this.storageKey)
      if (!saved) return

      const selections = JSON.parse(saved)
      this.pickTypesValue.forEach((pickType) => {
        const ids = selections[pickType.id] || []
        this.setSelectionsForType(pickType.id, ids)
      })
    } catch (_) {}
  }

  saveToStorage() {
    try {
      const selections = {}
      this.pickTypesValue.forEach((pickType) => {
        selections[pickType.id] = this.selectedIdsForType(pickType.id)
      })
      localStorage.setItem(this.storageKey, JSON.stringify(selections))
    } catch (_) {}
  }

  clearStorage() {
    localStorage.removeItem(this.storageKey)
  }

  togglePick(event) {
    const button = event.currentTarget
    const pickTypeId = button.dataset.pickTypeId
    const nomineeId = button.dataset.nomineeId
    const pickType = this.pickTypeConfig(pickTypeId)

    if (!pickType) return

    const current = this.selectedIdsForType(pickTypeId)
    const isSelected = this.nomineeHasPick(nomineeId, pickTypeId)

    let next
    if (pickType.multi) {
      if (isSelected) {
        next = current.filter((id) => id !== nomineeId)
      } else if (current.length >= pickType.max) {
        return
      } else {
        next = [...current, nomineeId]
      }
    } else {
      next = isSelected ? [] : [nomineeId]
    }

    this.setSelectionsForType(pickTypeId, next)
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
    const step = (slide.offsetWidth + 12) * 3
    track.scrollBy({ left: dir * step, behavior: "smooth" })
  }

  pickTypeConfig(pickTypeId) {
    return this.pickTypesValue.find((pickType) => String(pickType.id) === String(pickTypeId))
  }

  selectedIdsForType(pickTypeId) {
    return this.pickInputTargets
      .filter((input) => input.dataset.pickTypeId === String(pickTypeId))
      .map((input) => input.value)
      .filter(Boolean)
  }

  nomineeHasPick(nomineeId, pickTypeId) {
    return this.selectedIdsForType(pickTypeId).some(
      (id) => String(id) === String(nomineeId)
    )
  }

  setSelectionsForType(pickTypeId, nomineeIds) {
    const group = this.pickTypeGroupTargets.find(
      (element) => element.dataset.pickTypeId === String(pickTypeId)
    )
    if (!group) return

    group.querySelectorAll("[data-picks-carousel-target='pickInput']").forEach((input) => input.remove())

    nomineeIds.forEach((nomineeId) => {
      const input = document.createElement("input")
      input.type = "hidden"
      input.name = `picks[${this.categoryIdValue}][${pickTypeId}][nominee_ids][]`
      input.value = nomineeId
      input.dataset.picksCarouselTarget = "pickInput"
      input.dataset.pickTypeId = pickTypeId
      group.appendChild(input)
    })
  }

  updateAllCards() {
    const activeByNominee = {}

    this.trackTarget.querySelectorAll("[data-slide]").forEach((slide) => {
      const nomineeId = slide.dataset.nomineeId
      const activeTypes = []

      this.pickTypesValue.forEach((pickType) => {
        const isActive = this.nomineeHasPick(nomineeId, pickType.id)
        slide.dataset[`pickType${pickType.id}`] = isActive ? "true" : "false"

        const badge = slide.querySelector(`[data-pick-badge="${pickType.id}"]`)
        if (badge) badge.hidden = !isActive

        const button = slide.querySelector(`[data-pick-btn="${pickType.id}"]`)
        if (button) button.dataset.active = isActive ? "true" : "false"

        if (isActive) activeTypes.push(pickType)
      })

      activeByNominee[nomineeId] = activeTypes
      this.applyPosterRing(slide, activeTypes)
    })

    this.updateSummaries()
    this.updateCounters()
    this.dispatch("changed")
  }

  applyPosterRing(slide, activeTypes) {
    const poster = slide.querySelector("[data-poster-wrap]")
    if (!poster) return

    poster.style.outline = ""
    poster.style.outlineOffset = ""
    poster.style.boxShadow = ""

    if (activeTypes.length === 0) {
      poster.style.borderColor = "transparent"
      return
    }

    poster.style.borderStyle = "solid"

    if (activeTypes.length === 1) {
      poster.style.borderWidth = "2.5px"
      poster.style.borderColor = activeTypes[0].color
      return
    }

    poster.style.borderWidth = "3px"
    poster.style.borderColor = "#f59e0b"
  }

  updateSummaries() {
    const names = {}
    this.trackTarget.querySelectorAll("[data-slide]").forEach((slide) => {
      names[slide.dataset.nomineeId] = slide.dataset.nomineeName
    })

    this.summaryTargets.forEach((summary) => {
      const pickTypeId = summary.dataset.pickTypeId
      const selected = this.selectedIdsForType(pickTypeId)
      const label = selected.map((id) => names[id]).filter(Boolean).join(", ") || "—"
      summary.textContent = label
      summary.classList.toggle("text-oscar-muted", selected.length === 0)
    })
  }

  updateCounters() {
    this.element.querySelectorAll("[data-pick-counter]").forEach((counter) => {
      const pickTypeId = counter.dataset.pickTypeId
      const pickType = this.pickTypeConfig(pickTypeId)
      if (!pickType?.multi) return

      const count = this.selectedIdsForType(pickTypeId).length
      counter.textContent = `${count}/${pickType.max} selected`
    })
  }
}
