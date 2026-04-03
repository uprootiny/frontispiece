import "phoenix_html"
import { Socket } from "phoenix"
import { LiveSocket } from "phoenix_live_view"

// -- Hooks --

const Hooks = {}

// Swipe navigation for episode journey (mobile)
Hooks.SwipeNav = {
  mounted() {
    let startX = 0
    let startY = 0
    const threshold = 60

    this._onTouchStart = (e) => {
      startX = e.changedTouches[0].screenX
      startY = e.changedTouches[0].screenY
    }

    this._onTouchEnd = (e) => {
      const dx = e.changedTouches[0].screenX - startX
      const dy = e.changedTouches[0].screenY - startY

      // Only trigger on horizontal swipes (not vertical scroll)
      if (Math.abs(dx) > threshold && Math.abs(dx) > Math.abs(dy) * 1.5) {
        this.pushEvent("swipe", { direction: dx > 0 ? "right" : "left" })
      }
    }

    this.el.addEventListener("touchstart", this._onTouchStart, { passive: true })
    this.el.addEventListener("touchend", this._onTouchEnd, { passive: true })
  },

  destroyed() {
    this.el.removeEventListener("touchstart", this._onTouchStart)
    this.el.removeEventListener("touchend", this._onTouchEnd)
  }
}

// Asciinema player embed
Hooks.AsciinemaPlayer = {
  mounted() {
    const src = this.el.dataset.src
    if (window.AsciinemaPlayer) {
      this._player = window.AsciinemaPlayer.create(src, this.el, {
        theme: "monokai",
        fit: "width",
        autoPlay: false,
        fontSize: "14px"
      })
    }
  },

  destroyed() {
    // AsciinemaPlayer doesn't expose a dispose method,
    // but clearing innerHTML prevents memory leaks
    this.el.innerHTML = ""
    this._player = null
  }
}

// Level navigation — read hash on mount, scroll tabs into view
Hooks.LevelNav = {
  mounted() {
    // Activate level from URL hash on initial load
    const hash = window.location.hash
    if (hash && hash.startsWith("#level-")) {
      const level = hash.replace("#level-", "")
      this.pushEvent("set_level", { level })
    }

    // Scroll active tab into view
    this._scrollActive()
  },

  updated() {
    this._scrollActive()
  },

  _scrollActive() {
    const active = this.el.querySelector('[aria-selected="true"]')
    if (active) {
      active.scrollIntoView({ behavior: "smooth", inline: "center", block: "nearest" })
    }
  }
}

// -- Clipboard helpers --

function copyText(text) {
  return navigator.clipboard.writeText(text).then(() => {
    if (navigator.vibrate) navigator.vibrate(10)
  }).catch(() => {
    // Fallback for older browsers / non-HTTPS
    const textarea = document.createElement("textarea")
    textarea.value = text
    textarea.style.position = "fixed"
    textarea.style.opacity = "0"
    document.body.appendChild(textarea)
    textarea.select()
    document.execCommand("copy")
    document.body.removeChild(textarea)
  })
}

function flashButton(el, original) {
  el.textContent = "✓"
  setTimeout(() => { el.textContent = original }, 800)
}

// -- Events --

// Copy text to clipboard (from server push — episode_live rerun results)
window.addEventListener("phx:copy-text", (e) => {
  copyText(e.detail.text)
})

// Copy well content by well ID (from journey_live)
window.addEventListener("phx:copy-to-clipboard", (e) => {
  const wellId = e.detail.well_id
  const btn = document.querySelector(`[phx-value-id="${wellId}"]`)
  if (btn) {
    const pre = btn.closest(".rounded-xl")?.querySelector("pre code")
    if (pre) {
      copyText(pre.textContent).then(() => flashButton(btn, "copy"))
    }
  }
})

// -- LiveSocket --

const csrfToken = document.querySelector("meta[name='csrf-token']")?.getAttribute("content")
const liveSocket = new LiveSocket("/live", Socket, {
  hooks: Hooks,
  params: { _csrf_token: csrfToken }
})

liveSocket.connect()
window.liveSocket = liveSocket
