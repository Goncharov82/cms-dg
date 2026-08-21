import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "backdrop", "collapseLabel", "collapseButton"]

  connect() {
    this.handleResize = this.handleResize.bind(this)
    window.addEventListener("resize", this.handleResize)
    this.renderDesktopState()
  }

  disconnect() { window.removeEventListener("resize", this.handleResize) }

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

  toggleCollapsed() {
    if (!this.desktop) return
    const collapsed = !this.element.classList.contains("sidebar-collapsed")
    this.element.classList.toggle("sidebar-collapsed", collapsed)
    try { localStorage.setItem("dg-cms-sidebar-collapsed", collapsed ? "1" : "0") } catch (_) {}
    this.updateCollapseControl(collapsed)
  }

  handleResize() { this.renderDesktopState() }

  renderDesktopState() {
    if (!this.desktop) {
      this.element.classList.remove("sidebar-collapsed")
      this.updateCollapseControl(false)
      return
    }
    let collapsed = false
    try { collapsed = localStorage.getItem("dg-cms-sidebar-collapsed") === "1" } catch (_) {}
    this.element.classList.toggle("sidebar-collapsed", collapsed)
    this.updateCollapseControl(collapsed)
  }

  updateCollapseControl(collapsed) {
    if (this.hasCollapseLabelTarget) this.collapseLabelTarget.textContent = collapsed ? "Показать меню" : "Скрыть меню"
    if (this.hasCollapseButtonTarget) {
      this.collapseButtonTarget.setAttribute("aria-label", collapsed ? "Показать меню" : "Скрыть меню")
      this.collapseButtonTarget.title = collapsed ? "Показать меню" : "Скрыть меню"
    }
  }

  get desktop() { return window.matchMedia("(min-width: 1024px)").matches }
}
