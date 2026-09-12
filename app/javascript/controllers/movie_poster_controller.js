import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog", "poster", "title", "description", "imdb"]

  show(event) {
    event.preventDefault()
    event.stopPropagation()

    const { posterUrl, movieTitle, movieDescription, imdbUrl } = event.currentTarget.dataset
    if (!posterUrl && !movieDescription && !imdbUrl) return

    if (posterUrl) {
      this.posterTarget.src = posterUrl
      this.posterTarget.alt = movieTitle || "Movie poster"
      this.posterTarget.hidden = false
    } else {
      this.posterTarget.removeAttribute("src")
      this.posterTarget.alt = ""
      this.posterTarget.hidden = true
    }

    this.titleTarget.textContent = movieTitle || ""

    if (this.hasDescriptionTarget) {
      this.descriptionTarget.textContent = movieDescription || ""
      this.descriptionTarget.hidden = !movieDescription
    }

    if (this.hasImdbTarget) {
      if (imdbUrl) {
        this.imdbTarget.href = imdbUrl
        this.imdbTarget.hidden = false
      } else {
        this.imdbTarget.removeAttribute("href")
        this.imdbTarget.hidden = true
      }
    }

    this.dialogTarget.showModal()
  }

  // Close the dialog from the X button or Escape.

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
