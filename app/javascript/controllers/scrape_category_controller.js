import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["nomineeList"]
  static values  = { categoryIndex: Number, hasPerson: Boolean }

  addNominee() {
    const ci  = this.categoryIndexValue
    const idx = Date.now() // unique key — Rails accepts non-sequential hash indices
    const row = document.createElement("div")
    row.setAttribute("data-nominee-row", "")
    row.className = "flex gap-2 items-center"

    let html = `
      <input type="text" name="categories[${ci}][nominees][${idx}][movie]"
             placeholder="Movie" class="input-field flex-1 text-xs py-1.5" required>`

    if (this.hasPersonValue) {
      html += `
      <input type="text" name="categories[${ci}][nominees][${idx}][person]"
             placeholder="Person" class="input-field w-36 text-xs py-1.5">`
    }

    html += `
      <input type="text" name="categories[${ci}][nominees][${idx}][poster_url]"
             placeholder="Poster URL (optional)" class="input-field w-52 text-xs py-1.5">
      <button type="button"
              data-action="click->scrape-category#removeNominee"
              class="btn btn-danger btn-sm flex-shrink-0 px-2 leading-none">✕</button>`

    row.innerHTML = html
    this.nomineeListTarget.appendChild(row)
    row.querySelector("input").focus()
  }

  removeNominee(event) {
    event.target.closest("[data-nominee-row]").remove()
  }
}
