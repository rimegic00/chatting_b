// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

// v3.8: Turbo Drive 완전 비활성화 (모바일 딜레이 해결)
// aria-busy 상태로 인한 멈춤 현상을 방지하기 위해 SPA 방식 포기
Turbo.session.drive = false

// iOS 터치 지연 방지
document.addEventListener('touchstart', function () { }, { passive: true });
