// Garde la page sur le téléphone pour qu'elle s'ouvre même sans réseau.
// Les notes elles-mêmes ne passent jamais par ce cache : elles vont directement à la base.
const CACHE = 'bulletins-v7';
const FICHIERS = [
  './',
  './index.html',
  './manifest.json',
  'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2.45.4/dist/umd/supabase.js'
];

self.addEventListener('install', e => {
  e.waitUntil(caches.open(CACHE).then(c => c.addAll(FICHIERS)).then(() => self.skipWaiting()));
});

self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys()
      .then(ks => Promise.all(ks.filter(k => k !== CACHE).map(k => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', e => {
  const req = e.request;
  if (req.method !== 'GET') return;
  const url = new URL(req.url);
  if (url.hostname.endsWith('supabase.co')) return; // base de données : jamais en cache

  if (url.origin === location.origin) {
    // La page : on prend la version en ligne si possible, sinon celle gardée sur le téléphone
    e.respondWith(
      fetch(req)
        .then(res => { const copie = res.clone(); caches.open(CACHE).then(c => c.put(req, copie)); return res; })
        .catch(() => caches.match(req).then(m => m || caches.match('./index.html')))
    );
    return;
  }
  // Bibliothèques et polices : version gardée d'abord
  e.respondWith(
    caches.match(req).then(m => m || fetch(req).then(res => {
      const copie = res.clone(); caches.open(CACHE).then(c => c.put(req, copie)); return res;
    }))
  );
});
