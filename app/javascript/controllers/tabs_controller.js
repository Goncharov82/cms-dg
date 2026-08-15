import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel"]

  async show(event) {
    const selected = event.currentTarget.dataset.tabsName
    const currentPanel = this.panelTargets.find((panel) => !panel.hidden)
    const nextPanel = this.panelTargets.find((panel) => panel.dataset.tabsName === selected)

    if (currentPanel === nextPanel) return

    this.tabTargets.forEach((tab) => tab.classList.toggle("is-active", tab.dataset.tabsName === selected))

    if (currentPanel) {
      await currentPanel.animate(
        [{ opacity: 1, transform: "translateY(0)" }, { opacity: 0, transform: "translateY(4px)" }],
        { duration: 120, easing: "ease-out" }
      ).finished
      currentPanel.hidden = true
    }

    nextPanel.hidden = false
    nextPanel.animate(
      [{ opacity: 0, transform: "translateY(5px)" }, { opacity: 1, transform: "translateY(0)" }],
      { duration: 190, easing: "ease-out" }
    )
  }
}
