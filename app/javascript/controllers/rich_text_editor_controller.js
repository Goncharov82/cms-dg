import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["visual", "source", "toolbar", "visualButton", "htmlButton"]

  connect() {
    this.boundSubmit = () => this.sync()
    this.element.closest("form")?.addEventListener("submit", this.boundSubmit)
  }

  disconnect() {
    this.element.closest("form")?.removeEventListener("submit", this.boundSubmit)
  }

  showVisual() {
    this.visualTarget.innerHTML = this.sourceTarget.value
    this.visualTarget.hidden = false
    this.toolbarTarget.hidden = false
    this.sourceTarget.hidden = true
    this.setMode("visual")
  }

  showHtml() {
    this.syncFromVisual()
    this.visualTarget.hidden = true
    this.toolbarTarget.hidden = true
    this.sourceTarget.hidden = false
    this.setMode("html")
  }

  format(event) {
    event.preventDefault()
    this.visualTarget.focus()
    document.execCommand(event.currentTarget.dataset.command, false, event.currentTarget.dataset.value || null)
    this.syncFromVisual()
  }

  addLink(event) {
    event.preventDefault()
    const url = window.prompt("Введите адрес ссылки", "https://")
    if (!url) return

    this.visualTarget.focus()
    document.execCommand("createLink", false, url)
    this.syncFromVisual()
  }

  clearFormatting(event) {
    event.preventDefault()
    this.visualTarget.focus()
    document.execCommand("removeFormat", false, null)
    this.syncFromVisual()
  }

  syncFromVisual() {
    this.sourceTarget.value = this.visualTarget.innerHTML
  }

  syncFromSource() {
    this.visualTarget.innerHTML = this.sourceTarget.value
  }

  sync() {
    if (!this.visualTarget.hidden) this.syncFromVisual()
  }

  setMode(mode) {
    this.visualButtonTarget.classList.toggle("is-active", mode === "visual")
    this.htmlButtonTarget.classList.toggle("is-active", mode === "html")
  }
}
