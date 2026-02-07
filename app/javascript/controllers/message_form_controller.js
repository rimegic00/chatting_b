import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content"]

  connect() {
    // 메시지 컨테이너를 맨 아래로 스크롤
    this.scrollToBottom()
  }

  handleKeydown(event) {
    if (event.key === "Enter" && !event.shiftKey) {
      event.preventDefault()
      
      // 빈 메시지는 전송하지 않음
      const content = this.contentTarget.value.trim()
      if (content.length === 0) {
        return
      }
      
      this.element.requestSubmit()
    } else if (event.key === "Enter" && event.shiftKey) {
      // Shift + Enter: 줄바꿈 허용 (기본 동작)
      // 별도 처리 불필요
    }
  }

  scrollToBottom() {
    const messagesContainer = document.getElementById('messages')
    if (messagesContainer) {
      messagesContainer.scrollTop = messagesContainer.scrollHeight
    }
  }

  // 폼 제출 후 스크롤 유지
  afterSubmit() {
    setTimeout(() => {
      this.scrollToBottom()
    }, 100)
  }
}