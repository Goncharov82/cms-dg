import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["name", "slug", "slugPreview", "seoSlugPreview", "shortDescription", "descriptionCount", "seoTitle", "metaDescription", "seoTitlePreview", "seoDescriptionPreview"]

  connect() {
    this.slugLocked = this.slugTarget.value.length > 0 && this.slugTarget.value !== this.slugify(this.nameTarget.value)
    this.updatePreview()
    this.updateCount()
    this.updateSeo()
  }

  suggestSlug() {
    if (!this.slugLocked) this.slugTarget.value = this.slugify(this.nameTarget.value)
    this.updatePreview()
    this.updateSeo()
  }

  lockSlug() {
    this.slugLocked = this.slugTarget.value.length > 0
    this.updatePreview()
  }

  updateCount() { this.descriptionCountTarget.textContent = `${this.shortDescriptionTarget.value.length} / 300` }

  updateSeo() {
    this.seoTitlePreviewTarget.textContent = this.seoTitleTarget.value || this.nameTarget.value || "Название категории"
    this.seoDescriptionPreviewTarget.textContent = this.metaDescriptionTarget.value || this.shortDescriptionTarget.value || "Описание категории для поисковой выдачи."
  }

  updatePreview() {
    const slug = this.slugTarget.value || "adres-kategorii"
    this.slugPreviewTarget.textContent = slug
    this.seoSlugPreviewTarget.textContent = slug
  }

  slugify(value) {
    const letters = { а: "a", б: "b", в: "v", г: "g", д: "d", е: "e", ё: "yo", ж: "zh", з: "z", и: "i", й: "y", к: "k", л: "l", м: "m", н: "n", о: "o", п: "p", р: "r", с: "s", т: "t", у: "u", ф: "f", х: "h", ц: "ts", ч: "ch", ш: "sh", щ: "sch", ъ: "", ы: "y", ь: "", э: "e", ю: "yu", я: "ya" }
    return value.toLowerCase().split("").map((character) => letters[character] ?? character).join("").trim().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "")
  }
}
