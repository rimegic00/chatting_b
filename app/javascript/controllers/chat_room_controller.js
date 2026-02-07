import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.scrollChatToBottom()
  }

  scrollChatToBottom() {
    const messagesContainer = this.element.querySelector("#messages")
    if (messagesContainer) {
      // 부드러운 스크롤 애니메이션
      messagesContainer.scrollTo({
        top: messagesContainer.scrollHeight,
        behavior: 'smooth'
      })
    }
  }

  // Turbo Stream이 메시지를 추가한 후 호출될 액션
  messageAdded({ detail: { newElements } }) {
    setTimeout(() => {
      this.scrollChatToBottom()
    }, 50)
  }
}
