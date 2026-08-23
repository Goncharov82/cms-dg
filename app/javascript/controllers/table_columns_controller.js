import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "picker"]
  static values = { key: String }

  connect() {
    this.closeOnOutsideClick = this.closeOnOutsideClick.bind(this)
    document.addEventListener("pointerdown", this.closeOnOutsideClick)
    const saved = this.readState()
    this.checkboxTargets.forEach((checkbox) => {
      if (!checkbox.disabled && Object.hasOwn(saved, checkbox.value)) checkbox.checked = saved[checkbox.value]
    })
    this.prepareDraggableColumns()
    this.applyOrder(this.readOrder())
    this.apply()
  }

  disconnect() { document.removeEventListener("pointerdown", this.closeOnOutsideClick) }

  closeOnOutsideClick(event) {
    if (this.hasPickerTarget && this.pickerTarget.open && !this.pickerTarget.contains(event.target)) this.pickerTarget.open = false
  }

  toggle() {
    this.apply()
    this.saveState()
  }

  apply() {
    this.checkboxTargets.forEach((checkbox) => {
      this.element.querySelectorAll(`[data-column="${checkbox.value}"]`).forEach((cell) => {
        cell.hidden = !checkbox.checked
      })
    })
  }

  readState() {
    try { return JSON.parse(localStorage.getItem(this.storageKey) || "{}") } catch (_) { return {} }
  }

  saveState() {
    const state = Object.fromEntries(this.checkboxTargets.filter((item) => !item.disabled).map((item) => [item.value, item.checked]))
    try { localStorage.setItem(this.storageKey, JSON.stringify(state)) } catch (_) {}
  }

  prepareDraggableColumns() {
    this.element.querySelectorAll("thead th[data-column]:not([data-fixed-column])").forEach((heading) => {
      if (heading.querySelector(".column-drag-handle")) return
      const handle = document.createElement("span")
      handle.className = "column-drag-handle"
      handle.draggable = true
      handle.setAttribute("role", "button")
      handle.setAttribute("aria-label", `Переместить столбец ${heading.textContent.trim()}`)
      handle.innerHTML = "<i></i><i></i><i></i><i></i><i></i><i></i>"
      handle.addEventListener("dragstart", (event) => this.startDrag(event, heading.dataset.column))
      handle.addEventListener("dragend", () => this.finishDrag())
      heading.prepend(handle)
      heading.addEventListener("dragover", (event) => this.dragOver(event, heading))
      heading.addEventListener("drop", (event) => this.drop(event, heading))
    })
  }

  startDrag(event, column) {
    this.draggedColumn = column
    event.dataTransfer.effectAllowed = "move"
    event.dataTransfer.setData("text/plain", column)
    this.element.querySelector(`[data-column="${column}"]`).classList.add("is-dragging")
  }

  dragOver(event, heading) {
    if (!this.draggedColumn || heading.dataset.column === this.draggedColumn) return
    event.preventDefault()
    event.dataTransfer.dropEffect = "move"
  }

  drop(event, heading) {
    event.preventDefault()
    const target = heading.dataset.column
    const order = this.currentOrder().filter((column) => column !== this.draggedColumn)
    const targetIndex = order.indexOf(target)
    const after = event.clientX > heading.getBoundingClientRect().left + heading.offsetWidth / 2
    order.splice(targetIndex + (after ? 1 : 0), 0, this.draggedColumn)
    this.applyOrder(order)
    this.saveOrder(order)
    this.finishDrag()
  }

  finishDrag() { this.element.querySelectorAll(".is-dragging").forEach((item) => item.classList.remove("is-dragging")); this.draggedColumn = null }

  currentOrder() { return Array.from(this.element.querySelectorAll("thead th[data-column]:not([data-fixed-column])"), (item) => item.dataset.column) }

  applyOrder(order) {
    if (!Array.isArray(order) || order.length === 0) return
    const known = this.currentOrder()
    const normalized = [...order.filter((column) => known.includes(column)), ...known.filter((column) => !order.includes(column))]
    this.element.querySelectorAll("table.collection-table tr").forEach((row) => {
      const cells = new Map(Array.from(row.children).filter((cell) => cell.dataset.column && !cell.hasAttribute("data-fixed-column")).map((cell) => [cell.dataset.column, cell]))
      if (cells.size === 0) return
      const trailingCell = Array.from(row.children).findLast((cell) => !cell.dataset.column)
      const rightFixedCell = Array.from(row.children).find((cell) => cell.dataset.fixedPosition === "right")
      normalized.forEach((column) => { if (cells.has(column)) row.insertBefore(cells.get(column), rightFixedCell || trailingCell || null) })
    })
  }

  readOrder() { try { return JSON.parse(localStorage.getItem(this.orderStorageKey) || "[]") } catch (_) { return [] } }
  saveOrder(order) { try { localStorage.setItem(this.orderStorageKey, JSON.stringify(order)) } catch (_) {} }

  get storageKey() { return `dg-cms-columns-${this.keyValue}` }
  get orderStorageKey() { return `${this.storageKey}-order` }
}
