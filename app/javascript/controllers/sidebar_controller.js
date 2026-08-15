import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "backdrop"]

  open() {
    this.panelTarget.classList.remove("-translate-x-full")
    this.panelTarget.classList.add("translate-x-0")
    this.backdropTarget.classList.remove("hidden")
  }

  close() {
    this.panelTarget.classList.remove("translate-x-0")
    this.panelTarget.classList.add("-translate-x-full")
    this.backdropTarget.classList.add("hidden")
  }
}
