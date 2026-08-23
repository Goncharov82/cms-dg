import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["track", "slide", "pagination"]

  connect() {
    this.index = 0
    this.interval = 5000
    this.keydown = this.handleKeydown.bind(this)
    document.addEventListener("keydown", this.keydown)
    this.shuffleSlides()
    this.buildPagination()
    this.show(0, false)
    this.start()
  }

  disconnect() {
    this.stop()
    document.removeEventListener("keydown", this.keydown)
    document.body.classList.remove("home-modal-open")
  }

  previous() { this.show(this.index - 1) }
  next() { this.show(this.index + 1) }
  goTo(event) { this.show(Number(event.currentTarget.dataset.index)) }

  openAd(event) {
    event.preventDefault()
    event.stopPropagation()
    const modal = document.getElementById(event.currentTarget.dataset.modalId)
    if (!modal) return
    this.stop()
    this.activeModal = modal
    modal.hidden = false
    document.body.classList.add("home-modal-open")
    modal.querySelector(".home-ad-modal__close")?.focus()
  }

  closeAd() {
    if (!this.activeModal) return
    this.activeModal.hidden = true
    this.activeModal = null
    document.body.classList.remove("home-modal-open")
    this.start()
  }

  backdropClose(event) { if (event.target === event.currentTarget) this.closeAd() }
  handleKeydown(event) { if (event.key === "Escape" && this.activeModal) this.closeAd() }

  shuffleSlides() {
    const slides = [...this.slideTargets]
    for (let i = slides.length - 1; i > 0; i -= 1) {
      const j = Math.floor(Math.random() * (i + 1))
      ;[slides[i], slides[j]] = [slides[j], slides[i]]
    }
    slides.forEach((slide) => this.trackTarget.appendChild(slide))
  }

  buildPagination() {
    this.paginationTarget.replaceChildren()
    this.slideTargets.forEach((_, index) => {
      const button = document.createElement("button")
      button.type = "button"
      button.dataset.index = index
      button.dataset.action = "home-slider#goTo"
      button.setAttribute("aria-label", `Слайд ${index + 1}`)
      button.innerHTML = "<span></span>"
      this.paginationTarget.appendChild(button)
    })
  }

  show(index, restart = true) {
    const count = this.slideTargets.length
    this.index = (index + count) % count
    this.trackTarget.style.transform = `translate3d(-${this.index * 100}%, 0, 0)`
    this.paginationTarget.querySelectorAll("button").forEach((button, buttonIndex) => {
      const active = buttonIndex === this.index
      button.classList.toggle("is-active", active)
      button.setAttribute("aria-current", active ? "true" : "false")
    })
    if (restart) { this.stop(); this.start() }
  }

  start() {
    this.stop()
    this.timer = window.setInterval(() => this.show(this.index + 1, false), this.interval)
  }

  stop() {
    if (this.timer) window.clearInterval(this.timer)
    this.timer = null
  }
}
