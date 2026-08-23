import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "card", "empty", "grid"]

  filter() {
    const query = this.inputTarget.value.trim().toLocaleLowerCase("ru-RU")
    let visible = 0

    this.cardTargets.forEach((card) => {
      const matches = query.length === 0 || card.dataset.searchText.includes(query)
      card.hidden = !matches
      if (matches) visible += 1
    })

    this.emptyTarget.hidden = visible !== 0
    this.gridTarget.hidden = visible === 0
  }
}
