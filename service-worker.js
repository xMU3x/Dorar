// وِرد — Service Worker (v6): تخزين التطبيق والبيانات للعمل بدون إنترنت
const V = 'werd-v6', CORE = ['./', 'index.html', 'offline.html', 'manifest.json', 'css/app.css', 'js/config.js', 'js/vendor/supabase.js', 'js/core.js', 'js/data.js', 'js/sync.js', 'js/notify.js', 'js/pages1.js', 'js/pages2.js', 'js/pages3.js', 'js/fasting.js', 'js/reminders.js', 'js/more.js', 'js/app.js',
  'fonts/Tajawal-Regular.ttf', 'fonts/Tajawal-Medium.ttf', 'fonts/Tajawal-Bold.ttf', 'fonts/Amiri-Regular.ttf', 'fonts/Amiri-Bold.ttf', 'fonts/AmiriQuran-Regular.ttf', 'brand/app_icon.png', 'icons/icon-192.png', 'icons/icon-512.png', 'data/quran.json', 'data/azkar.json', 'data/challenges.json'];
const LATE = [];
self.addEventListener('install', e => { e.waitUntil(caches.open(V).then(async c => { await Promise.allSettled(CORE.map(u => c.add(u))); Promise.allSettled(LATE.map(u => c.add(u))) }).then(() => self.skipWaiting())) });
self.addEventListener('activate', e => { e.waitUntil(caches.keys().then(k => Promise.all(k.filter(x => x !== V).map(x => caches.delete(x)))).then(() => self.clients.claim())) });
self.addEventListener('fetch', e => {
  const r = e.request, u = new URL(r.url); if (r.method !== 'GET') return;
  if (u.origin !== location.origin) return; // API/الصوت/Supabase تذهب للشبكة مباشرة
  if (r.headers.has('range')) return;
  e.respondWith(fetch(r).then(res => { if (res.ok) { const cp = res.clone(); caches.open(V).then(c => c.put(r, cp)) } return res }).catch(() => caches.match(r).then(m => m || (r.mode === 'navigate' ? caches.match('offline.html') : Response.error()))));
});
