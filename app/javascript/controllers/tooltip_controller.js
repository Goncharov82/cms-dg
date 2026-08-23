import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  show() {
    this.hide()
    const text = this.element.dataset.tooltip
    if (!text) return

    this.tooltip = document.createElement("div")
    this.tooltip.className = "floating-tooltip"
    this.tooltip.textContent = text
    this.tooltip.setAttribute("role", "tooltip")
    document.body.appendChild(this.tooltip)

    const anchor = this.element.getBoundingClientRect()
    const box = this.tooltip.getBoundingClientRect()
    const gap = 10
    let left = anchor.right + gap
    if (left + box.width > window.innerWidth - 8) left = anchor.left - box.width - gap
    const top = Math.min(Math.max(8, anchor.top + (anchor.height - box.height) / 2), window.innerHeight - box.height - 8)
    this.tooltip.style.left = `${Math.max(8, left)}px`
    this.tooltip.style.top = `${top}px`
    requestAnimationFrame(() => this.tooltip?.classList.add("is-visible"))
  }

  hide() {
    this.tooltip?.remove()
    this.tooltip = null
  }

  disconnect() { this.hide() }
}
