import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["nomineeList"]
  static values  = { categoryIndex: Number, hasPerson: Boolean }

  addNominee() {
    const ci  = this.categoryIndexValue
    const idx = Date.now() // unique key — Rails accepts non-sequential hash indices
    const row = document.createElement("div")
    row.setAttribute("data-nominee-row", "")
    row.className = "space-y-1.5 py-2 border-b border-oscar-border last:border-0"

    let html = `
      <div class="flex gap-2 items-center">
        <input type="text" name="categories[${ci}][nominees][${idx}][movie]"
               placeholder="Movie" class="input-field flex-1 text-xs py-1.5" required>`

    if (this.hasPersonValue) {
      html += `
        <input type="text" name="categories[${ci}][nominees][${idx}][person]"
               placeholder="Person" class="input-field w-36 text-xs py-1.5">`
    }

    html += `
        <button type="button"
                data-action="click->scrape-category#removeNominee"
                class="btn btn-danger btn-sm flex-shrink-0 px-2 leading-none">✕</button>
      </div>
      <div class="flex gap-2 items-start">
        <input type="text" name="categories[${ci}][nominees][${idx}][poster_url]"
               placeholder="Poster URL (optional)" class="input-field flex-1 text-xs py-1.5">
        <input type="url" name="categories[${ci}][nominees][${idx}][imdb_url]"
               placeholder="IMDb URL (optional)" class="input-field flex-1 text-xs py-1.5">
      </div>
      <textarea name="categories[${ci}][nominees][${idx}][description]"
                placeholder="Description (optional)" rows="2"
                class="input-field w-full text-xs py-1.5"></textarea>`

    row.innerHTML = html
    this.nomineeListTarget.appendChild(row)
    row.querySelector("input").focus()
  }

  togglePerson(event) {
    const hasPerson = event.target.checked
    this.hasPersonValue = hasPerson
    this.nomineeListTarget.querySelectorAll("[data-person-field]").forEach(el => {
      el.classList.toggle("hidden", !hasPerson)
    })
  }

  removeNominee(event) {
    event.target.closest("[data-nominee-row]").remove()
  }
}
