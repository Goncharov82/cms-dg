import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["row", "search", "date", "alpha", "status", "type", "shown"]

  connect() { this.apply() }

  apply() {
    const query = this.hasSearchTarget ? this.normalize(this.searchTarget.value) : ""
    const status = this.hasStatusTarget ? this.statusTarget.value : "all"
    const type = this.hasTypeTarget ? this.typeTarget.value : "all"
    const rows = [...this.rowTargets]

    this.renderActiveFilters({ query, status, type })

    rows.forEach((row) => {
      const matchesSearch = !query || this.normalize(row.dataset.search).includes(query)
      const matchesStatus = status === "all" || row.dataset.status === status
      const matchesType = type === "all" || row.dataset.type === type
      row.hidden = !(matchesSearch && matchesStatus && matchesType)
    })

    const direction = this.hasAlphaTarget ? this.alphaTarget.value : "none"
    const dateDirection = this.hasDateTarget ? this.dateTarget.value : "none"
    const sorted = rows.sort((a, b) => {
      if (direction === "asc" || direction === "desc") {
        const result = (a.dataset.name || "").localeCompare(b.dataset.name || "", "ru", { sensitivity: "base" })
        return direction === "asc" ? result : -result
      }
      if (dateDirection === "newest" || dateDirection === "oldest") {
        const result = Number(a.dataset.date || 0) - Number(b.dataset.date || 0)
        return dateDirection === "oldest" ? result : -result
      }
      return 0
    })

    const body = rows[0]?.parentElement
    if (body) sorted.forEach((row) => body.appendChild(row))
    const visible = rows.filter((row) => !row.hidden).length
    this.renderNoResults(body, rows.length > 0 && visible === 0)
    if (this.hasShownTarget) this.shownTarget.textContent = `Показано ${visible} из ${rows.length}`
  }

  renderActiveFilters({ query, status, type }) {
    if (this.hasSearchTarget) {
      this.toggleActiveFilter(this.searchTarget, query.length > 0, ".filter-search")
    }

    if (this.hasStatusTarget) {
      this.toggleActiveFilter(this.statusTarget, status !== "all", ".filter-control")
    }

    if (this.hasTypeTarget) {
      this.toggleActiveFilter(this.typeTarget, type !== "all", ".filter-control")
    }

    if (this.hasAlphaTarget) {
      this.toggleActiveFilter(this.alphaTarget, this.alphaTarget.value !== "none", ".filter-control")
    }

    if (this.hasDateTarget) {
      this.toggleActiveFilter(this.dateTarget, !["newest", "none"].includes(this.dateTarget.value), ".filter-control")
    }
  }

  toggleActiveFilter(target, active, selector) {
    if (!target) return
    target.closest(selector)?.classList.toggle("is-active", active)
  }

  navigateCategory(event) {
    const url = new URL(window.location.href)
    if (event.currentTarget.value === "all") {
      url.searchParams.delete("category")
    } else {
      url.searchParams.set("category", event.currentTarget.value)
    }
    if (window.Turbo) window.Turbo.visit(url.toString())
    else window.location.assign(url.toString())
  }

  renderNoResults(body, show) {
    if (!body) return
    let row = body.querySelector(".filter-no-results")
    if (!row) {
      row = document.createElement("tr")
      row.className = "filter-no-results"
      row.innerHTML = `<td colspan="20"><div class="filter-no-results-message">Ничего не найдено</div></td>`
      body.appendChild(row)
    }
    row.hidden = !show
  }

  normalize(value) { return (value || "").toString().trim().toLocaleLowerCase("ru") }
}
