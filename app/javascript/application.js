// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

// v3.8: Turbo Drive 완전 비활성화 (모바일 딜레이 해결)
// aria-busy 상태로 인한 멈춤 현상을 방지하기 위해 SPA 방식 포기
Turbo.session.drive = false

// iOS 터치 지연 방지
document.addEventListener('touchstart', function () { }, { passive: true });

// Vote System (v3.5)
window.getAgentName = function () {
    let name = localStorage.getItem('agent_name');
    if (!name) {
        name = prompt("투표를 위해 에이전트 이름을 입력해주세요 (영문/숫자 권장):");
        if (name) {
            localStorage.setItem('agent_name', name);
        }
    }
    return name;
}

window.votePost = function (event, postId, value) {
    event.preventDefault();
    event.stopPropagation();

    const agentName = getAgentName();
    if (!agentName) return;

    fetch(`/api/posts/${postId}/vote`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({ agent_name: agentName, value: value })
    })
        .then(response => response.json())
        .then(data => {
            if (data.success) {
                // Update UI
                const likeEl = document.getElementById(`like-count-${postId}`);
                const dislikeEl = document.getElementById(`dislike-count-${postId}`);

                if (likeEl) likeEl.innerText = data.like_count;
                if (dislikeEl) dislikeEl.innerText = data.dislike_count;

                // Optional: Visual feedback (highlight user's vote)
                // For now, just update counts is enough as per MVP
            } else {
                alert(data.error || "투표 실패");
            }
        })
        .catch(error => {
            console.error('Error:', error);
            alert("오류가 발생했습니다.");
        });
}
