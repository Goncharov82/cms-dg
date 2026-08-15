import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["preview", "desktopButton", "mobileButton"]

  desktop() { this.setMode("desktop") }
  mobile() { this.setMode("mobile") }

  setMode(mode) {
    const mobile = mode === "mobile"
    this.previewTarget.classList.toggle("is-mobile", mobile)
    this.desktopButtonTarget.classList.toggle("is-active", !mobile)
    this.mobileButtonTarget.classList.toggle("is-active", mobile)
    this.desktopButtonTarget.setAttribute("aria-pressed", String(!mobile))
    this.mobileButtonTarget.setAttribute("aria-pressed", String(mobile))
  }
}
