/* تشغيل التطبيق */
(async function () {
  W.applyTheme(); W.initNative();
  $$('nav button').forEach(b => b.onclick = () => W.go(b.dataset.t));
  try { await W.sync.init() } catch (e) { console.warn(e) }
  if (!location.hash && !localStorage.getItem('werd2:__seen') && !W.sync.user && window.WERD_CONFIG?.SUPABASE_URL) location.hash = '#/login'; /* أول تشغيل: صفحة الدخول (يمكن تخطيها) */
  await W.route();
  W.chal.check().catch(() => { });
  W.notify.init().catch(e => console.warn(e));
  if ('serviceWorker' in navigator && location.protocol.startsWith('http') && location.hostname !== 'localhost') navigator.serviceWorker.register('service-worker.js').catch(() => { });
  const A = window.Capacitor?.Plugins?.App;
  if (A) A.addListener('backButton', () => { if (document.querySelector('.sheet.on,.dlg.on,.menu')) return W.closeSheet(); if (W.tabs.includes(W.cur?.id)) { if (W.cur.id === 'home') A.exitApp(); else W.go('home') } else W.back() });
  document.addEventListener('visibilitychange', () => { if (!document.hidden) { W.refresh(); W.notify.schedule(); W.initNative() } });
})();
