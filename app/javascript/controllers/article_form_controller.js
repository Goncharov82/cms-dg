import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["titleInput", "excerptInput", "slugInput", "categoryInput", "categoryPath", "seoTitleInput", "metaInput", "previewTitle", "previewDescription", "previewUrl", "seoCount", "metaCount"]
  static values = { currentYear: Number, currentMonthPred: String }

  connect() {
    this.slugLocked = this.slugInputTarget.value.length > 0 && this.slugInputTarget.value !== this.slugify(this.titleInputTarget.value)
    this.update()
  }

  lockSlug() {
    this.slugLocked = true
    this.update()
  }

  update() {
    const title = this.renderVariables(this.seoTitleInputTarget.value || this.titleInputTarget.value || "Заголовок статьи")
    const description = this.renderVariables(this.metaInputTarget.value || this.excerptInputTarget.value || "Краткое описание будущей статьи")
    if (!this.slugLocked) this.slugInputTarget.value = this.slugify(this.titleInputTarget.value)
    const slug = this.slugInputTarget.value || "adres-stati"
    const category = this.categoryInputTarget.selectedOptions[0]?.dataset.path || "категория"
    this.previewTitleTarget.textContent = title
    this.previewDescriptionTarget.textContent = description
    this.categoryPathTarget.textContent = `${category}/`
    this.previewUrlTarget.textContent = `https://goncharoff.pro/${category}/${slug}`
    this.seoCountTarget.textContent = `${this.seoTitleInputTarget.value.length} / 60`
    this.metaCountTarget.textContent = `${this.metaInputTarget.value.length} / 160`
  }

  slugify(value) {
    const letters = { а: "a", б: "b", в: "v", г: "g", д: "d", е: "e", ё: "yo", ж: "zh", з: "z", и: "i", й: "y", к: "k", л: "l", м: "m", н: "n", о: "o", п: "p", р: "r", с: "s", т: "t", у: "u", ф: "f", х: "h", ц: "ts", ч: "ch", ш: "sh", щ: "sch", ъ: "", ы: "y", ь: "", э: "e", ю: "yu", я: "ya" }
    return value.toLowerCase().split("").map((character) => letters[character] ?? character).join("").trim().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "")
  }

  renderVariables(value) {
    return value
      .replace(/\{YYYY\}/gi, String(this.currentYearValue))
      .replace(/\{MONTH_PRED\}/gi, this.currentMonthPredValue)
  }
}
