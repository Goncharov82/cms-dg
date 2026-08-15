import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["lightButton", "darkButton"]

  connect() {
    this.apply(localStorage.getItem("dg-cms-theme") || "light")
  }

  light() { this.apply("light") }
  dark() { this.apply("dark") }

  apply(theme) {
    this.element.dataset.theme = theme
    localStorage.setItem("dg-cms-theme", theme)
    this.lightButtonTarget.classList.toggle("is-active", theme === "light")
    this.darkButtonTarget.classList.toggle("is-active", theme === "dark")
  }
}
