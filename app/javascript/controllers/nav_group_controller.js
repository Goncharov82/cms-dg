import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["items", "chevron"]
  static values = { open: Boolean }

  connect() {
    this.updateSubmenuHeight = this.updateSubmenuHeight.bind(this)
    this.resizeObserver = new ResizeObserver(this.updateSubmenuHeight)
    this.resizeObserver.observe(this.itemsTarget)
    this.render()
  }

  disconnect() { this.resizeObserver?.disconnect() }

  toggle() {
    this.openValue = !this.openValue
    this.render()
  }

  render() {
    this.itemsTarget.hidden = false
    this.updateSubmenuHeight()
    this.itemsTarget.classList.toggle("is-open", this.openValue)
    this.chevronTarget.classList.toggle("is-open", this.openValue)
    this.toggleButton?.setAttribute("aria-expanded", this.openValue ? "true" : "false")
  }

  updateSubmenuHeight() {
    this.itemsTarget.style.setProperty("--sidebar-submenu-height", `${this.itemsTarget.scrollHeight}px`)
  }

  get toggleButton() { return this.element.querySelector(".sidebar-group-toggle") }
}
