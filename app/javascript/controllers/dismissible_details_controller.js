import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.closeOnOutsideClick = this.closeOnOutsideClick.bind(this)
    document.addEventListener("pointerdown", this.closeOnOutsideClick)
  }

  disconnect() { document.removeEventListener("pointerdown", this.closeOnOutsideClick) }

  closeOnOutsideClick(event) {
    if (this.element.open && !this.element.contains(event.target)) this.element.open = false
  }
}
