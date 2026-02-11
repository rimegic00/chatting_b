import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["content", "container"]

    connect() {
        this.processLinkPreview()
    }

    processLinkPreview() {
        const content = this.contentTarget.textContent
        const url = this.extractUrl(content)

        if (!url) return

        const cacheKey = `lp:${this.hashUrl(url)}`
        const cachedData = this.getValidCache(cacheKey)

        if (cachedData) {
            this.renderCard(cachedData)
        } else {
            this.fetchPreview(url, cacheKey)
        }
    }

    extractUrl(text) {
        const urlRegex = /(https?:\/\/[^\s]+)/g
        const match = text.match(urlRegex)
        return match ? match[0] : null
    }

    hashUrl(url) {
        // Simple hash for cache key
        let hash = 0, i, chr
        if (url.length === 0) return hash
        for (i = 0; i < url.length; i++) {
            chr = url.charCodeAt(i)
            hash = ((hash << 5) - hash) + chr
            hash |= 0 // Convert to 32bit integer
        }
        return hash
    }

    getValidCache(key) {
        const json = localStorage.getItem(key)
        if (!json) return null

        try {
            const { data, expiresAt } = JSON.parse(json)
            if (Date.now() > expiresAt) {
                localStorage.removeItem(key)
                return null
            }
            return data
        } catch (e) {
            localStorage.removeItem(key)
            return null
        }
    }

    async fetchPreview(url, cacheKey) {
        try {
            const response = await fetch(`/api/link_preview?url=${encodeURIComponent(url)}`)
            if (!response.ok) throw new Error("Preview failed")

            const data = await response.json()

            // Cache for 7 days
            const expiresAt = Date.now() + (7 * 24 * 60 * 60 * 1000)
            localStorage.setItem(cacheKey, JSON.stringify({ data, expiresAt }))

            this.renderCard(data)
        } catch (error) {
            console.warn("Link preview failed:", error)
            // Negative cache for 1 hour to prevent retry storm
            const expiresAt = Date.now() + (60 * 60 * 1000)
            localStorage.setItem(cacheKey, JSON.stringify({ data: { url, error: true }, expiresAt }))

            // Fallback: Just show domain
            this.renderFallback(url)
        }
    }

    renderCard(data) {
        if (data.error) {
            this.renderFallback(data.url)
            return
        }

        const { title, description, image, url, site_name } = data
        const domain = new URL(url).hostname

        // Construct HTML safely
        const cardHtml = `
      <a href="${url}" target="_blank" rel="noopener noreferrer nofollow" class="block mt-4 mb-6 group">
        <div class="bg-neutral-800 border border-neutral-700 rounded-lg overflow-hidden hover:border-neutral-600 transition-colors">
          ${image ? `
            <div class="aspect-video w-full overflow-hidden bg-neutral-900 relative">
               <img src="${image}" alt="" loading="lazy" referrerpolicy="no-referrer" class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500" onerror="this.style.display='none'">
            </div>
          ` : ''}
          <div class="p-3 sm:p-4">
            <h3 class="text-sm sm:text-base font-bold text-gray-200 group-hover:text-white line-clamp-1 mb-1">${this.escapeHtml(title || url)}</h3>
            ${description ? `<p class="text-xs text-gray-400 line-clamp-2 mb-2">${this.escapeHtml(description)}</p>` : ''}
            <div class="flex items-center gap-2">
                ${site_name ? `<span class="text-xs text-green-500 font-medium">${this.escapeHtml(site_name)}</span>` : ''}
                <span class="text-xs text-gray-600">${domain}</span>
            </div>
          </div>
        </div>
      </a>
    `

        this.containerTarget.innerHTML = cardHtml
    }

    renderFallback(url) {
        const domain = new URL(url).hostname
        const cardHtml = `
      <a href="${url}" target="_blank" rel="noopener noreferrer nofollow" class="block mt-4 mb-6">
        <div class="bg-neutral-800 border border-neutral-700 rounded-lg p-3 sm:p-4 hover:border-neutral-600 transition-colors flex items-center gap-3">
           <div class="bg-neutral-700 p-2 rounded text-gray-400">🔗</div>
           <div>
             <h3 class="text-sm font-bold text-gray-300 break-all line-clamp-1">${this.escapeHtml(url)}</h3>
             <span class="text-xs text-gray-500">${domain}</span>
           </div>
        </div>
      </a>
      `
        this.containerTarget.innerHTML = cardHtml
    }

    escapeHtml(unsafe) {
        return unsafe
            .replace(/&/g, "&amp;")
            .replace(/</g, "&lt;")
            .replace(/>/g, "&gt;")
            .replace(/"/g, "&quot;")
            .replace(/'/g, "&#039;");
    }
}
