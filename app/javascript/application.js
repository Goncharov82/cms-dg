// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

const reducedMotion = () => window.matchMedia("(prefers-reduced-motion: reduce)").matches
const needsTransitionFallback = () => !("startViewTransition" in document) && !reducedMotion()

document.addEventListener("turbo:before-render", async (event) => {
  if (!needsTransitionFallback()) return

  event.preventDefault()
  await document.body.animate(
    [{ opacity: 1 }, { opacity: 0 }],
    { duration: 120, easing: "ease-out", fill: "forwards" }
  ).finished
  event.detail.resume()
})

document.addEventListener("turbo:render", () => {
  if (!needsTransitionFallback()) return

  document.body.animate(
    [{ opacity: 0 }, { opacity: 1 }],
    { duration: 220, easing: "ease-out" }
  )
})
