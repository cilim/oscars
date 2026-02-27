import { Controller } from "@hotwired/stimulus"

// Clears localStorage pick state for all categories in this season when the form submits.
// This ensures that successfully saved picks don't "restore" from stale localStorage
// on the next page load.
export default class extends Controller {
  static values = { seasonId: Number }

  clearStorage() {
    const prefix = `oscars_picks_${this.seasonIdValue}_cat_`
    Object.keys(localStorage)
      .filter(k => k.startsWith(prefix))
      .forEach(k => localStorage.removeItem(k))
  }
}
