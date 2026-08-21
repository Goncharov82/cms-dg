import { Controller } from "@hotwired/stimulus"
import { createCodeMirror, formatCode, formatHtmlSource, replaceCode } from "lib/code_mirror"

export default class extends Controller {
  static targets = ["title", "slug", "route", "html", "css", "js", "htmlEditor", "cssEditor", "jsEditor", "codeTab", "preview", "previewTitle", "previewUrl", "codeFooter"]

  connect() {
    this.htmlTarget.value = formatHtmlSource(this.htmlTarget.value)
    this.codeEditors = {
      html: createCodeMirror({ parent: this.htmlEditorTarget, textarea: this.htmlTarget, language: "html", onChange: () => this.codeChanged("html") }),
      css: createCodeMirror({ parent: this.cssEditorTarget, textarea: this.cssTarget, language: "css", onChange: () => this.codeChanged("css") }),
      js: createCodeMirror({ parent: this.jsEditorTarget, textarea: this.jsTarget, language: "javascript", onChange: () => this.codeChanged("js") })
    }
    this.initialCode = { html: this.htmlTarget.value, css: this.cssTarget.value, js: this.jsTarget.value }
    this.activeCode = "html"
    this.slugLocked = this.slugTarget.value.length > 0 && this.slugTarget.value !== this.slugify(this.titleTarget.value)
    this.update()
    this.renderPreview()
    this.updateCodeFooter()
  }

  disconnect() {
    Object.values(this.codeEditors || {}).forEach((editor) => editor.destroy())
  }

  update() {
    if (!this.slugLocked) this.slugTarget.value = this.slugify(this.titleTarget.value)
    if (this.hasRouteTarget) this.routeTarget.value = this.slugTarget.value
    if (this.hasPreviewTitleTarget) this.previewTitleTarget.textContent = this.titleTarget.value || "Новая страница"
    if (this.hasPreviewUrlTarget) this.previewUrlTarget.textContent = this.slugTarget.value === "/" ? "https://goncharoff.pro/" : "https://goncharoff.pro/" + (this.slugTarget.value || "novaya-stranitsa")
    this.renderPreview()
  }

  lockSlug() {
    this.slugLocked = true
    this.update()
  }

  selectCode(event) {
    const selected = event.currentTarget.dataset.code
    this.activeCode = selected
    this.codeTabTargets.forEach((tab) => tab.classList.toggle("is-active", tab.dataset.code === selected))
    ;["html", "css", "js"].forEach((name) => { this[`${name}EditorTarget`].hidden = name !== selected })
    this.codeEditors[selected].requestMeasure()
    this.updateCodeFooter()
  }

  formatCurrentCode() {
    formatCode(this.codeEditors[this.activeCode], this.activeCode)
  }

  resetCurrentCode() {
    if (!window.confirm(`Вернуть исходный ${this.activeCode.toUpperCase()}-код?`)) return
    replaceCode(this.codeEditors[this.activeCode], this.initialCode[this.activeCode] || "")
  }

  codeChanged() {
    this.renderPreview()
    this.updateCodeFooter()
  }

  updateCodeFooter() {
    if (!this.hasCodeFooterTarget) return
    const textarea = this[`${this.activeCode}Target`]
    const lines = (textarea.value || "").split("\n").length
    this.codeFooterTarget.textContent = `${this.activeCode.toUpperCase()}  •  ${lines} ${this.lineWord(lines)}  •  изменения синхронизированы`
  }

  lineWord(count) {
    const lastTwo = count % 100
    const last = count % 10
    if (lastTwo >= 11 && lastTwo <= 14) return "строк"
    if (last === 1) return "строка"
    if (last >= 2 && last <= 4) return "строки"
    return "строк"
  }

  renderPreview() {
    if (!this.hasPreviewTarget || !this.hasHtmlTarget) return
    const previewCss = "*,*::before,*::after{box-sizing:border-box}body{margin:0;color:#101b3a;font-family:Arial,sans-serif}.site-header{height:54px;display:flex;align-items:center;padding:0 22px;border-bottom:1px solid #ff6800;background:#fff}.site-header strong{font-size:13px;letter-spacing:.03em}.site-header nav{display:flex;gap:28px;margin-left:auto}.site-header a{color:#626d85;text-decoration:none;font-size:12px}.home-page{background:#fff}.hero{min-height:244px;padding:34px 25px 24px;text-align:center}.hero .eyebrow{display:none}.hero h1{max-width:350px;margin:0 auto;color:#0d1a38;font-size:31px;line-height:1.12;letter-spacing:-.9px}.hero h1::after{content:'Практика, инструменты и опыт создания медиа';display:block;max-width:270px;margin:16px auto 21px;color:#69748a;font-size:14px;line-height:1.45;letter-spacing:0;font-weight:400}.hero a{display:inline-flex;align-items:center;justify-content:center;min-height:40px;padding:0 26px;border-radius:7px;color:#fff;background:#ff6800;text-decoration:none;font-size:13px;font-weight:700}.latest{min-height:126px;padding:15px 20px;background:#f7f7f8;text-align:left}.latest h2{margin:0 0 12px;font-size:14px}.latest-grid{display:grid;grid-template-columns:1fr 1fr;gap:10px}.latest-card{height:61px;display:grid;grid-template-columns:58px 1fr;gap:10px;padding:9px;border-radius:7px;background:#fff}.latest-card i{border-radius:5px;background:#e9ebef}.latest-lines{padding-top:3px}.latest-lines span{display:block;height:6px;margin-bottom:7px;border-radius:5px;background:#eceef2}.latest-lines span:last-child{width:65%}"
    const header = "<header class=\"site-header\"><strong>GONCHAROFF.PRO</strong><nav><a href=\"/reviews\">Статьи</a><a href=\"/about\">О проекте</a></nav></header>"
    const latest = "<section class=\"latest\"><h2>Последние материалы</h2><div class=\"latest-grid\"><div class=\"latest-card\"><i></i><div class=\"latest-lines\"><span></span><span></span><span></span></div></div><div class=\"latest-card\"><i></i><div class=\"latest-lines\"><span></span><span></span><span></span></div></div></div></section>"
    const document = "<!doctype html><html><head><meta charset=\"utf-8\"><style>" + previewCss + (this.cssTarget.value || "") + "</style></head><body>" + header + (this.htmlTarget.value || "") + latest + "<script>" + (this.jsTarget.value || "") + "<\\/script></body></html>"
    this.previewTarget.srcdoc = document
  }

  slugify(value) {
    return value.toString().toLowerCase().replace(/[^a-zа-яё0-9]+/gi, "-").replace(/[а-яё]/gi, (character) => ({ а: "a", б: "b", в: "v", г: "g", д: "d", е: "e", ё: "yo", ж: "zh", з: "z", и: "i", й: "y", к: "k", л: "l", м: "m", н: "n", о: "o", п: "p", р: "r", с: "s", т: "t", у: "u", ф: "f", х: "h", ц: "ts", ч: "ch", ш: "sh", щ: "sch", ъ: "", ы: "y", ь: "", э: "e", ю: "yu", я: "ya" }[character] || character)).replace(/^-|-$/g, "")
  }
}
