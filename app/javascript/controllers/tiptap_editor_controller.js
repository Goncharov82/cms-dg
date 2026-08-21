import { Controller } from "@hotwired/stimulus"
import { Editor, StarterKit, Image, TableKit } from "tiptap"
import { createCodeMirror, codeValue, formatHtmlSource, replaceCode } from "lib/code_mirror"

export default class extends Controller {
  static targets = ["editor", "source", "codeEditor", "toolbar", "visualButton", "htmlButton", "command"]

  connect() {
    this.editor = new Editor({
      element: this.editorTarget,
      extensions: [
        StarterKit.configure({
          heading: { levels: [2, 3, 4] },
          link: { openOnClick: false, defaultProtocol: "https" }
        }),
        Image.configure({ allowBase64: false }),
        TableKit.configure({ table: { resizable: true } })
      ],
      content: this.sourceTarget.value || "",
      editorProps: { attributes: { class: "tiptap-prose" } },
      onUpdate: () => this.sync(),
      onSelectionUpdate: () => this.refreshToolbar()
    })
    this.codeMirror = createCodeMirror({
      parent: this.codeEditorTarget,
      textarea: this.sourceTarget,
      language: "html"
    })
    this.currentMode = "visual"

    this.boundSubmit = () => this.syncForSubmit()
    this.element.closest("form")?.addEventListener("submit", this.boundSubmit)
    this.refreshToolbar()
  }

  disconnect() {
    this.element.closest("form")?.removeEventListener("submit", this.boundSubmit)
    this.codeMirror?.destroy()
    this.editor?.destroy()
  }

  showVisual() {
    this.preservePagePosition(() => {
      const sourceHeight = this.codeEditorTarget.getBoundingClientRect().height
      this.sourceTarget.value = codeValue(this.codeMirror)
      this.editor.commands.setContent(this.sourceTarget.value || "", { emitUpdate: false })
      this.editorTarget.hidden = false
      if (sourceHeight > 0) this.editorTarget.style.height = `${sourceHeight}px`
      this.toolbarTarget.hidden = false
      this.codeEditorTarget.hidden = true
      this.currentMode = "visual"
      this.setMode("visual")
    })
  }

  showHtml() {
    this.preservePagePosition(() => {
      const editorHeight = this.editorTarget.getBoundingClientRect().height
      this.sync()
      const formatted = formatHtmlSource(this.sourceTarget.value || "")
      this.sourceTarget.value = formatted
      replaceCode(this.codeMirror, formatted)
      this.editorTarget.hidden = true
      this.toolbarTarget.hidden = true
      this.codeEditorTarget.hidden = false
      if (editorHeight > 0) this.codeEditorTarget.style.height = `${editorHeight}px`
      this.codeMirror.requestMeasure()
      this.currentMode = "html"
      this.setMode("html")
    })
  }

  command(event) {
    event.preventDefault()
    const chain = this.editor.chain().focus()

    switch (event.currentTarget.dataset.command) {
      case "paragraph": chain.setParagraph().run(); break
      case "heading2": chain.toggleHeading({ level: 2 }).run(); break
      case "heading3": chain.toggleHeading({ level: 3 }).run(); break
      case "bold": chain.toggleBold().run(); break
      case "italic": chain.toggleItalic().run(); break
      case "underline": chain.toggleUnderline().run(); break
      case "bulletList": chain.toggleBulletList().run(); break
      case "orderedList": chain.toggleOrderedList().run(); break
      case "blockquote": chain.toggleBlockquote().run(); break
      case "undo": chain.undo().run(); break
      case "redo": chain.redo().run(); break
      case "clear": chain.unsetAllMarks().clearNodes().run(); break
    }

    this.refreshToolbar()
  }

  addLink(event) {
    event.preventDefault()
    const current = this.editor.getAttributes("link").href || "https://"
    const href = window.prompt("Введите адрес ссылки", current)
    if (href === null) return

    if (href.trim() === "") this.editor.chain().focus().extendMarkRange("link").unsetLink().run()
    else this.editor.chain().focus().extendMarkRange("link").setLink({ href: href.trim() }).run()

    this.refreshToolbar()
  }

  sync() {
    if (!this.editor || this.currentMode !== "visual") return
    this.sourceTarget.value = this.editor.getHTML()
    this.sourceTarget.dispatchEvent(new Event("input", { bubbles: true }))
  }

  syncForSubmit() {
    if (this.currentMode === "html") this.sourceTarget.value = codeValue(this.codeMirror)
    else {
      this.sync()
      this.sourceTarget.value = formatHtmlSource(this.sourceTarget.value)
    }
  }

  refreshToolbar() {
    if (!this.editor) return
    const active = {
      paragraph: this.editor.isActive("paragraph"),
      heading2: this.editor.isActive("heading", { level: 2 }),
      heading3: this.editor.isActive("heading", { level: 3 }),
      bold: this.editor.isActive("bold"),
      italic: this.editor.isActive("italic"),
      underline: this.editor.isActive("underline"),
      bulletList: this.editor.isActive("bulletList"),
      orderedList: this.editor.isActive("orderedList"),
      blockquote: this.editor.isActive("blockquote")
    }

    this.commandTargets.forEach((button) => {
      button.classList.toggle("is-active", Boolean(active[button.dataset.command]))
    })
  }

  setMode(mode) {
    this.visualButtonTarget.classList.toggle("is-active", mode === "visual")
    this.htmlButtonTarget.classList.toggle("is-active", mode === "html")
  }

  preservePagePosition(callback) {
    const left = window.scrollX
    const top = window.scrollY
    callback()
    requestAnimationFrame(() => window.scrollTo({ left, top, behavior: "auto" }))
  }
}
