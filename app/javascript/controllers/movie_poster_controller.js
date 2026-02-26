import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog", "poster", "title"]

  show(event) {
    event.preventDefault()
    const { posterUrl, movieTitle } = event.currentTarget.dataset
    if (!posterUrl) return

    this.posterTarget.src = posterUrl
    this.posterTarget.alt = movieTitle || "Movie poster"
    this.titleTarget.textContent = movieTitle || ""
    this.dialogTarget.showModal()
  }

  close() {
    this.dialogTarget.close()
  }

  // Close when clicking the dark backdrop (outside the inner dialog box)
  backdropClick(event) {
    const rect = this.dialogTarget.getBoundingClientRect()
    const outside =
      event.clientX < rect.left || event.clientX > rect.right ||
      event.clientY < rect.top  || event.clientY > rect.bottom
    if (outside) this.dialogTarget.close()
  }
}
