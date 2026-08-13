import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["track", "pickTypeGroup", "pickInput", "summary", "pool", "poolTray", "poolToken"]
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

    if (isSelected) {
      this.playTransfer({
        kind: "return",
        pickType,
        fromEl: this.badgeEl(nomineeId, pickTypeId),
        toEl: this.firstSpentToken(pickTypeId)
      })
      this.setSelectionsForType(pickTypeId, current.filter((id) => id !== nomineeId))
    } else if (current.length >= pickType.max) {
      if (pickType.multi) {
        this.shakeTray(pickTypeId)
        return
      }

      this.playTransfer({
        kind: "move",
        pickType,
        fromEl: this.badgeEl(current[0], pickTypeId),
        toEl: this.badgeEl(nomineeId, pickTypeId)
      })
      this.setSelectionsForType(pickTypeId, [nomineeId])
    } else {
      this.playTransfer({
        kind: "take",
        pickType,
        fromEl: this.lastRemainingToken(pickTypeId),
        toEl: this.badgeEl(nomineeId, pickTypeId)
      })
      this.setSelectionsForType(pickTypeId, [...current, nomineeId])
    }

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
        if (badge) {
          badge.hidden = !isActive
          if (!isActive) badge.classList.remove("is-arriving", "pick-badge-pop")
        }

        const button = slide.querySelector(`[data-pick-btn="${pickType.id}"]`)
        if (button) button.dataset.active = isActive ? "true" : "false"

        if (isActive) activeTypes.push(pickType)
      })

      activeByNominee[nomineeId] = activeTypes
      this.applyPosterRing(slide, activeTypes)
    })

    this.updateSummaries()
    this.updatePool()
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

  updatePool() {
    this.pickTypesValue.forEach((pickType) => {
      const remaining = Math.max(0, pickType.max - this.selectedIdsForType(pickType.id).length)
      this.poolTokensFor(pickType.id).forEach((token, index) => {
        token.classList.toggle("is-spent", index >= remaining)
      })

      const count = this.element.querySelector(`[data-pool-remaining="${pickType.id}"]`)
      if (count) count.textContent = remaining

      const tray = this.trayFor(pickType.id)
      if (tray) tray.dataset.empty = remaining === 0 ? "true" : "false"
    })
  }

  playTransfer({ kind, pickType, fromEl, toEl }) {
    if (this.prefersReducedMotion() || !fromEl || !toEl) return

    const fromRect = this.measureRect(fromEl)
    const toRect = this.measureRect(toEl)
    if (fromRect.width === 0 || toRect.width === 0) return

    if (kind === "take") {
      toEl.classList.add("is-arriving")
    } else if (kind === "return") {
      toEl.classList.add("is-awaiting")
    } else if (kind === "move") {
      toEl.classList.add("is-arriving")
    }

    this.animateFly(fromRect, toRect, pickType).finally(() => {
      toEl.classList.remove("is-arriving", "is-awaiting")
      if (kind === "take" || kind === "move") {
        toEl.classList.remove("pick-badge-pop")
        void toEl.offsetWidth
        toEl.classList.add("pick-badge-pop")
      }
    })
  }

  animateFly(fromRect, toRect, pickType) {
    const clone = document.createElement("span")
    clone.className = "pick-fly"
    clone.textContent = pickType.emoji
    clone.setAttribute("aria-hidden", "true")
    clone.style.setProperty("--pick-color", pickType.color)
    clone.style.left = `${fromRect.left}px`
    clone.style.top = `${fromRect.top}px`
    clone.style.width = `${fromRect.width}px`
    clone.style.height = `${fromRect.height}px`
    clone.style.fontSize = `${Math.max(12, fromRect.height * 0.55)}px`
    document.body.appendChild(clone)

    const dx = toRect.left - fromRect.left
    const dy = toRect.top - fromRect.top
    const scale = Math.max(0.55, Math.min(1.35, toRect.width / Math.max(fromRect.width, 1)))
    const lift = Math.min(56, Math.abs(dx) * 0.18 + 28)

    const animation = clone.animate(
      [
        { transform: "translate(0, 0) scale(1) rotate(0deg)", opacity: 1 },
        {
          transform: `translate(${dx * 0.5}px, ${dy * 0.45 - lift}px) scale(1.2) rotate(${dx >= 0 ? 14 : -14}deg)`,
          opacity: 1,
          offset: 0.55
        },
        { transform: `translate(${dx}px, ${dy}px) scale(${scale}) rotate(0deg)`, opacity: 1 }
      ],
      {
        duration: 520,
        easing: "cubic-bezier(0.22, 1, 0.36, 1)",
        fill: "forwards"
      }
    )

    return animation.finished.catch(() => {}).finally(() => clone.remove())
  }

  measureRect(element) {
    const wasHidden = element.hidden
    const previousVisibility = element.style.visibility
    const previousDisplay = element.style.display

    if (wasHidden) {
      element.hidden = false
      element.style.visibility = "hidden"
      element.style.display = "inline-flex"
    }

    const rect = element.getBoundingClientRect()
    const snapshot = { left: rect.left, top: rect.top, width: rect.width, height: rect.height }

    if (wasHidden) {
      element.hidden = true
      element.style.visibility = previousVisibility
      element.style.display = previousDisplay
    }

    return snapshot
  }

  shakeTray(pickTypeId) {
    const tray = this.trayFor(pickTypeId)
    if (!tray) return

    tray.classList.remove("is-shaking")
    void tray.offsetWidth
    tray.classList.add("is-shaking")
    tray.addEventListener("animationend", () => tray.classList.remove("is-shaking"), { once: true })
  }

  prefersReducedMotion() {
    return window.matchMedia?.("(prefers-reduced-motion: reduce)")?.matches
  }

  poolTokensFor(pickTypeId) {
    return this.poolTokenTargets.filter((token) => token.dataset.pickTypeId === String(pickTypeId))
  }

  lastRemainingToken(pickTypeId) {
    const remaining = this.poolTokensFor(pickTypeId).filter((token) => !token.classList.contains("is-spent"))
    return remaining[remaining.length - 1]
  }

  firstSpentToken(pickTypeId) {
    return this.poolTokensFor(pickTypeId).find((token) => token.classList.contains("is-spent"))
  }

  trayFor(pickTypeId) {
    return this.poolTrayTargets.find((tray) => tray.dataset.pickTypeId === String(pickTypeId))
  }

  badgeEl(nomineeId, pickTypeId) {
    return this.slideFor(nomineeId)?.querySelector(`[data-pick-badge="${pickTypeId}"]`)
  }

  slideFor(nomineeId) {
    return this.trackTarget.querySelector(`[data-slide][data-nominee-id="${nomineeId}"]`)
  }
}
