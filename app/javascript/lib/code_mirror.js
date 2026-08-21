import {
  EditorView,
  basicSetup,
  html,
  css,
  javascript,
  indentSelection,
  oneDark
} from "codemirror-editor"

const languageSupport = {
  html: () => html({ matchClosingTags: true, autoCloseTags: true }),
  css: () => css(),
  javascript: () => javascript()
}

const cmsTheme = EditorView.theme({
  "&": {
    height: "100%",
    color: "#eaf0fb",
    backgroundColor: "#071a36"
  },
  ".cm-scroller": {
    fontFamily: "ui-monospace, SFMono-Regular, Consolas, monospace",
    fontSize: "13px",
    lineHeight: "1.65"
  },
  ".cm-content": { padding: "14px 0" },
  ".cm-gutters": {
    color: "#aebbd0",
    backgroundColor: "#08172e",
    borderRight: "1px solid #253a59"
  },
  ".cm-activeLine, .cm-activeLineGutter": { backgroundColor: "rgba(69, 104, 153, .18)" },
  ".cm-selectionBackground, &.cm-focused .cm-selectionBackground": { backgroundColor: "rgba(88, 132, 194, .48)" },
  ".cm-cursor": { borderLeftColor: "#ffffff" },
  ".cm-foldPlaceholder": { color: "#dce5f4", backgroundColor: "#243957", border: "0" }
}, { dark: true })

export function createCodeMirror({ parent, textarea, language = "html", onChange }) {
  const support = languageSupport[language] || languageSupport.html
  const view = new EditorView({
    doc: textarea.value || "",
    parent,
    extensions: [
      basicSetup,
      support(),
      oneDark,
      cmsTheme,
      EditorView.updateListener.of((update) => {
        if (!update.docChanged) return
        textarea.value = update.state.doc.toString()
        textarea.dispatchEvent(new Event("input", { bubbles: true }))
        onChange?.(textarea.value, update)
      })
    ]
  })

  return view
}

export function codeValue(view) {
  return view.state.doc.toString()
}

export function replaceCode(view, value) {
  const current = codeValue(view)
  if (current === (value || "")) return
  view.dispatch({ changes: { from: 0, to: current.length, insert: value || "" } })
}

const blockTags = new Set([
  "address", "article", "aside", "blockquote", "details", "dialog", "div", "dl", "dt", "dd",
  "fieldset", "figcaption", "figure", "footer", "form", "h1", "h2", "h3", "h4", "h5", "h6",
  "header", "main", "nav", "ol", "p", "picture", "section", "summary", "table", "tbody", "td",
  "tfoot", "th", "thead", "tr", "ul", "li"
])

export function formatHtmlSource(source) {
  if (!source?.trim()) return source || ""

  const protectedBlocks = []
  let html = source.replace(/<(pre|script|style|textarea)\b[^>]*>[\s\S]*?<\/\1>/gi, (value) => {
    const index = protectedBlocks.push(value) - 1
    return `<dg-cms-raw data-index="${index}" />`
  })

  html = html.replace(/>\s*</g, ">\n<")
  let depth = 0
  const formatted = html.split(/\r?\n/).map((line) => {
    const content = line.trim()
    if (!content) return null

    const leadingClose = content.match(/^<\/([a-z0-9-]+)\b/i)
    const displayDepth = leadingClose && blockTags.has(leadingClose[1].toLowerCase()) ? Math.max(depth - 1, 0) : depth
    const openings = [...content.matchAll(/<([a-z0-9-]+)\b[^>]*>/gi)].filter((match) => blockTags.has(match[1].toLowerCase())).length
    const closings = [...content.matchAll(/<\/([a-z0-9-]+)\s*>/gi)].filter((match) => blockTags.has(match[1].toLowerCase())).length
    depth = Math.max(depth + openings - closings, 0)
    return `${"  ".repeat(displayDepth)}${content}`
  }).filter(Boolean).join("\n")

  return formatted.replace(/<dg-cms-raw data-index="(\d+)"\s*\/>/g, (_match, index) => protectedBlocks[Number(index)])
}

export function formatCode(view, language = "html") {
  if (language === "html") replaceCode(view, formatHtmlSource(codeValue(view)))
  const length = view.state.doc.length
  view.dispatch({ selection: { anchor: 0, head: length } })
  indentSelection(view)
  view.dispatch({ selection: { anchor: 0 } })
  view.focus()
}
