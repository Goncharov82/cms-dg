import { Controller } from "@hotwired/stimulus"
export default class extends Controller {
  static targets = ["label", "slug", "typeValue", "typeButton", "targetPanel", "targetLabel", "targetCategory", "targetUrl"]
  connect() {
    this.slugLocked = this.slugTarget.value.length > 0 && this.slugTarget.value !== this.slugify(this.labelTarget.value)
    this.selectType({ currentTarget: this.typeButtonTargets.find(button => button.classList.contains("is-active")) || this.typeButtonTargets[0] })
    this.update()
  }
  selectType(event) {
    const type = event.currentTarget.dataset.type
    this.typeValueTarget.value = type
    this.typeButtonTargets.forEach(button => button.classList.toggle("is-active", button.dataset.type === type))
    this.targetPanelTargets.forEach(panel => {
      const active = panel.dataset.menuItemFormType === type
      panel.hidden = !active
      panel.querySelectorAll("input, select, textarea").forEach(field => { field.disabled = !active })
    })
    this.update()
  }
  lockSlug() { this.slugLocked = true }
  selectCategory() {
    const option = this.targetCategoryTarget.selectedOptions[0]
    if (!this.slugTarget.value && option?.dataset.slug) this.slugTarget.value = option.dataset.slug
    this.update()
  }
  update() {
    if (!this.slugLocked) this.slugTarget.value = this.slugify(this.labelTarget.value)
  }
  slugify(value) { return value.toString().toLowerCase().replace(/[^a-zа-яё0-9]+/gi,"-").replace(/[а-яё]/gi,c => ({а:"a",б:"b",в:"v",г:"g",д:"d",е:"e",ё:"e",ж:"zh",з:"z",и:"i",й:"y",к:"k",л:"l",м:"m",н:"n",о:"o",п:"p",р:"r",с:"s",т:"t",у:"u",ф:"f",х:"h",ц:"c",ч:"ch",ш:"sh",щ:"sch",ъ:"",ы:"y",ь:"",э:"e",ю:"yu",я:"ya"}[c]||c)).replace(/^-|-$/g,"") }
}
