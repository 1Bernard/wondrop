const CACHE_NAME = "wondrop-v1";
const OFFLINE_URL = "/app";

// These will be replaced by the build script
const ASSETS_TO_CACHE = [
  "/",
  "/app",
  "/manifest.json",
  "/assets/js/app-ea34310b83bbe00362983eb41480d2f2.js",
  "/assets/css/app-e18b30e99642b43293f342422dba216d.css",
  "/images/logo-06a11be1f2cdde2c851763d00bdd2e80.svg",
  "/images/icon-192-e707fcad5be71a627ab2d59dcbb2e400.png",
  "/images/icon-512-d82f3168192fa5d76d6ebe05ab3f9f12.png"
];

self.addEventListener("install", (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      return cache.addAll(ASSETS_TO_CACHE);
    })
  );
  self.skipWaiting();
});

self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames.map((cacheName) => {
          if (cacheName !== CACHE_NAME) {
            return caches.delete(cacheName);
          }
        })
      );
    })
  );
  self.clients.claim();
});

self.addEventListener("fetch", (event) => {
  if (event.request.mode === "navigate") {
    event.respondWith(
      fetch(event.request).catch(() => {
        return caches.match(OFFLINE_URL);
      })
    );
    return;
  }

  event.respondWith(
    caches.match(event.request).then((response) => {
      return response || fetch(event.request);
    })
  );
});
