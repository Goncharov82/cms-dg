import { Controller } from "@hotwired/stimulus"
export default class extends Controller {
  static targets = ["label", "slug", "typeValue", "typeButton", "targetPanel", "targetLabel", "targetUrl", "url", "preview"]
  connect() { this.selectType({ currentTarget: this.typeButtonTargets.find(b => b.classList.contains("is-active")) || this.typeButtonTargets[0] }); this.update() }
  selectType(event) { const type = event.currentTarget.dataset.type; this.typeValueTarget.value = type; this.typeButtonTargets.forEach(b => b.classList.toggle("is-active", b.dataset.type === type)); this.targetPanelTargets.forEach(p => { p.hidden = p.dataset.menuItemFormType !== type }); this.update() }
  generateSlug() { this.slugTarget.value = this.slugify(this.labelTarget.value); this.update() }
  update() { const type = this.typeValueTarget.value || "page"; const slug = this.slugTarget.value || this.slugify(this.labelTarget.value); this.urlTarget.value = type === "external" ? (this.hasTargetUrlTarget ? this.targetUrlTarget.value : "") : (type === "page" ? `/${slug}` : `/blog/${slug}`); if (this.hasPreviewTarget) this.previewTarget.querySelector("span").textContent = this.targetLabelTargets.find(x => !x.closest("[hidden]"))?.value || this.labelTarget.value || "Новый пункт" }
  slugify(value) { return value.toString().toLowerCase().replace(/[^a-zа-яё0-9]+/gi,"-").replace(/[а-яё]/gi,c => ({а:"a",б:"b",в:"v",г:"g",д:"d",е:"e",ё:"e",ж:"zh",з:"z",и:"i",й:"y",к:"k",л:"l",м:"m",н:"n",о:"o",п:"p",р:"r",с:"s",т:"t",у:"u",ф:"f",х:"h",ц:"c",ч:"ch",ш:"sh",щ:"sch",ъ:"",ы:"y",ь:"",э:"e",ю:"yu",я:"ya"}[c]||c)).replace(/^-|-$/g,"") }
}
