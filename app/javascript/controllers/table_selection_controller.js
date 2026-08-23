import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["all", "row", "bulk", "apply"]

  connect() {
    this.allCheckbox = this.hasAllTarget ? this.allTarget : this.element.querySelector("thead .check-cell input[type='checkbox']")
    this.onAllChange = (event) => this.toggleAll(event)
    this.onRowChange = () => this.sync()
    this.allCheckbox?.addEventListener("change", this.onAllChange)
    this.rowCheckboxes.forEach((checkbox) => checkbox.addEventListener("change", this.onRowChange))
    this.sync()
  }

  disconnect() {
    this.allCheckbox?.removeEventListener("change", this.onAllChange)
    this.rowCheckboxes.forEach((checkbox) => checkbox.removeEventListener("change", this.onRowChange))
  }

  toggleAll(event) {
    const checked = event?.currentTarget?.checked ?? this.allCheckbox?.checked ?? false
    this.selectableRows.forEach((checkbox) => { checkbox.checked = checked })
    this.sync()
  }

  sync() {
    const rows = this.selectableRows
    const selected = rows.filter((checkbox) => checkbox.checked).length

    if (this.allCheckbox) {
      this.allCheckbox.checked = rows.length > 0 && selected === rows.length
      this.allCheckbox.indeterminate = selected > 0 && selected < rows.length
    }

    if (this.hasBulkTarget) this.bulkTarget.disabled = selected === 0
    if (this.hasApplyTarget) this.applyTarget.disabled = selected === 0
  }

  get selectableRows() {
    return this.rowCheckboxes.filter((checkbox) => !checkbox.disabled && !checkbox.closest("tr")?.hidden)
  }

  get rowCheckboxes() {
    return this.hasRowTarget ? this.rowTargets : [...this.element.querySelectorAll("tbody .check-cell input[type='checkbox']")]
  }
}
