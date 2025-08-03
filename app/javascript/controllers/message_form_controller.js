import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content"]

  connect() {
    this.contentTarget.addEventListener("keydown", this.handleKeydown.bind(this))
  }

  disconnect() {
    this.contentTarget.removeEventListener("keydown", this.handleKeydown.bind(this))
  }

  handleKeydown(event) {
    if (event.key === "Enter" && !event.shiftKey) {
      event.preventDefault()
      this.element.requestSubmit()
    } else if (event.key === "Enter" && event.shiftKey) {
      // Shift + Enter: 줄바꿈
      const start = this.contentTarget.selectionStart
      const end = this.contentTarget.selectionEnd
      this.contentTarget.value = this.contentTarget.value.substring(0, start) + "\n" + this.contentTarget.value.substring(end)
      this.contentTarget.selectionStart = this.contentTarget.selectionEnd = start + 1
    }
  }
}