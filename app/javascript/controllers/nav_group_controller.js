import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["items", "chevron"]
  static values = { open: Boolean }

  connect() { this.render() }

  toggle() {
    this.openValue = !this.openValue
    this.render()
  }

  render() {
    this.itemsTarget.hidden = !this.openValue
    this.chevronTarget.classList.toggle("is-open", this.openValue)
  }
}
