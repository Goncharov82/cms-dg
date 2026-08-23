import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "label"]

  submit() {
    if (this.hasLabelTarget) {
      this.labelTarget.textContent = this.inputTarget.checked ? "Сайт выключен" : "Сайт доступен"
    }

    this.element.requestSubmit()
  }
}
