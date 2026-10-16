// Only cache the public application shell. Never cache private health data or videos.
const CACHE_NAME = 'physioplan-shell-v1'
const STATIC_FILES = ['/', '/manifest.webmanifest', '/icon.svg']
self.addEventListener('install', (event) => {
  event.waitUntil(caches.open(CACHE_NAME).then((cache) => cache.addAll(STATIC_FILES)))
})
self.addEventListener('activate', (event) => {
  event.waitUntil(caches.keys().then((keys) => Promise.all(keys.filter((key) => key !== CACHE_NAME).map((key) => caches.delete(key)))))
})
self.addEventListener('fetch', (event) => {
  const request = event.request
  const url = new URL(request.url)
  if (request.method !== 'GET' || url.origin !== self.location.origin) return
  if (url.pathname.startsWith('/api/')) return
  if (request.mode === 'navigate') {
    event.respondWith(fetch(request).catch(() => caches.match('/')))
    return
  }
  if (url.pathname.startsWith('/assets/') || STATIC_FILES.includes(url.pathname)) {
    event.respondWith(caches.match(request).then((cached) => cached || fetch(request).then((response) => {
      if (response.ok) {
        const responseCopy = response.clone()
        caches.open(CACHE_NAME).then((cache) => cache.put(request, responseCopy))
      }
      return response
    })))
  }
})
