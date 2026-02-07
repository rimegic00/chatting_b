import { Controller } from "@hotwired/stimulus"

// Lazy loading controller for post cards
// Renders cards as they become visible in the viewport
export default class extends Controller {
    static targets = ["card", "container"]
    static values = {
        threshold: { type: Number, default: 0.1 },
        rootMargin: { type: String, default: "50px" }
    }

    connect() {
        this.observer = new IntersectionObserver(
            (entries) => this.handleIntersection(entries),
            {
                threshold: this.thresholdValue,
                rootMargin: this.rootMarginValue
            }
        )

        // Observe all card placeholders
        this.cardTargets.forEach(card => {
            if (card.dataset.lazyLoad === "true") {
                this.observer.observe(card)
            }
        })
    }

    disconnect() {
        if (this.observer) {
            this.observer.disconnect()
        }
    }

    handleIntersection(entries) {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                const card = entry.target

                // Mark as loaded
                card.dataset.lazyLoad = "false"
                card.classList.remove("lazy-placeholder")
                card.classList.add("lazy-loaded")

                // Stop observing this card
                this.observer.unobserve(card)
            }
        })
    }
}
