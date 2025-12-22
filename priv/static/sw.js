const CACHE_NAME = "wondrop-v1";
const ASSETS = [
  "/",
  "/app",
  "/assets/css/app.css",
  "/assets/js/app.js",
  "/manifest.json",
  "/images/logo.svg",
  "/images/icon-192.png",
  "/images/icon-512.png"
];

self.addEventListener("install", (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => cache.addAll(ASSETS))
  );
});

self.addEventListener("fetch", (event) => {
  // Simple offline fallback
  event.respondWith(
    fetch(event.request).catch(() => caches.match(event.request))
  );
});
