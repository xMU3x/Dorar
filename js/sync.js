/* تسجيل الدخول (Google / Email) + المزامنة التلقائية عبر Supabase */
const S = W.sync = { client: null, user: null, status: 'off', last: 0, err: '' };
const CFG = window.WERD_CONFIG || {};
const NATIVE = !!(window.Capacitor && Capacitor.isNativePlatform && Capacitor.isNativePlatform());
const REDIRECT = NATIVE ? (CFG.NATIVE_REDIRECT || 'com.werd.habittracker://auth') : location.origin + location.pathname;
const lsj = (k, d) => { try { return JSON.parse(localStorage.getItem('werd2:' + k)) || d } catch { return d } };
const lss = (k, v) => localStorage.setItem('werd2:' + k, JSON.stringify(v));
const setStatus = (s, e = '') => { S.status = s; S.err = e; W.emit('sync', s); };

function merge(a, b) { /* دمج آمن عند تعارض حقيقي بين جهازين: أكبر رقم، اتحاد المصفوفات */
  if (typeof a === 'number' && typeof b === 'number') return Math.max(a, b);
  if (Array.isArray(a) && Array.isArray(b)) { const seen = new Set(), out = []; [...a, ...b].forEach(x => { const k = JSON.stringify(x); if (!seen.has(k)) { seen.add(k); out.push(x) } }); return out }
  if (a && b && typeof a === 'object' && typeof b === 'object') { const o = { ...a }; for (const k in b) o[k] = k in a ? merge(a[k], b[k]) : b[k]; return o }
  return a ?? b;
}

S.init = async () => {
  if (!CFG.SUPABASE_URL || !CFG.SUPABASE_KEY || !window.supabase) { setStatus('off'); return }
  S.client = supabase.createClient(CFG.SUPABASE_URL, CFG.SUPABASE_KEY, { auth: { flowType: 'pkce', persistSession: true, autoRefreshToken: true, detectSessionInUrl: !NATIVE } });
  S.client.auth.onAuthStateChange((ev, ses) => { const was = S.user?.id; S.user = ses?.user || null; W.emit('auth', S.user); if (S.user && S.user.id !== was) S.run(); if (!S.user) setStatus('off') });
  const { data } = await S.client.auth.getSession(); S.user = data.session?.user || null;
  if (S.user) S.run();
  if (NATIVE && Capacitor.Plugins.App) Capacitor.Plugins.App.addListener('appUrlOpen', async ({ url }) => {
    if (!url || !url.startsWith(REDIRECT)) return; try { Capacitor.Plugins.Browser?.close() } catch { }
    const u = new URL(url.replace('#', '?')), code = u.searchParams.get('code');
    if (code) { const { error } = await S.client.auth.exchangeCodeForSession(code); if (error) W.toast('تعذّر تسجيل الدخول') }
    else if (u.searchParams.get('access_token')) await S.client.auth.setSession({ access_token: u.searchParams.get('access_token'), refresh_token: u.searchParams.get('refresh_token') });
  });
  window.addEventListener('online', () => S.user && S.run());
  document.addEventListener('visibilitychange', () => { if (!document.hidden && S.user && Date.now() - S.last > 60000) S.run() });
};
S.google = async () => {
  if (!S.client) return W.toast('لم يتم ضبط Supabase بعد (js/config.js)');
  const { data, error } = await S.client.auth.signInWithOAuth({ provider: 'google', options: { redirectTo: REDIRECT, skipBrowserRedirect: NATIVE, queryParams: { prompt: 'select_account' } } });
  if (error) return W.toast('تعذّر بدء تسجيل الدخول بجوجل');
  if (NATIVE && data?.url) { const B = Capacitor.Plugins.Browser; B ? B.open({ url: data.url }) : (location.href = data.url) }
};
S.email = async (email, password, create) => {
  if (!S.client) return { error: { message: 'no-client' } };
  return create ? S.client.auth.signUp({ email, password, options: { emailRedirectTo: REDIRECT } }) : S.client.auth.signInWithPassword({ email, password });
};
S.logout = async () => { await S.client?.auth.signOut(); S.user = null; setStatus('off'); W.emit('auth', null) };
S.deleteAccount = async () => { if (!S.client || !S.user) return false; const { error } = await S.client.rpc('delete_my_account'); if (error) return false; await S.logout(); store.clearAll(); return true };

let busy = false, again = false;
S.run = async () => {
  if (!S.client || !S.user) return; if (busy) { again = true; return } busy = true; setStatus('syncing');
  try { if (!navigator.onLine) throw new Error('offline'); await pull(); await push(); S.last = Date.now(); lss('__last', S.last); setStatus('ok') }
  catch (e) { console.warn('sync', e); setStatus(navigator.onLine ? 'error' : 'offline', e.message || String(e)); setTimeout(() => S.user && S.run(), 30000) }
  finally { busy = false; if (again) { again = false; setTimeout(S.run, 500) } }
};
async function pull() {
  const { data, error } = await S.client.from('werd_sync').select('key,value,ts').eq('user_id', S.user.id); if (error) throw error;
  const pushed = lsj('__pushed', {}), pulled = lsj('__pulled', {});
  for (const r of data || []) {
    if (!W.SYNC_KEYS.includes(r.key)) continue; const lt = store.meta[r.key] || 0, unsynced = lt > (pushed[r.key] || 0), has = localStorage.getItem('werd2:' + r.key) != null;
    if (!has || (r.ts > lt && !unsynced)) store.applyRemote(r.key, r.value, r.ts);
    else if (unsynced && r.ts > (pulled[r.key] || 0) && r.ts !== lt) { store.set(r.key, merge(store.get(r.key), r.value)) } /* تعارض حقيقي → دمج ثم رفع */
    pulled[r.key] = r.ts;
  }
  lss('__pulled', pulled);
}
async function push() {
  const pushed = lsj('__pushed', {}), rows = [];
  W.SYNC_KEYS.forEach(k => { const t = store.meta[k] || 0; if (t > (pushed[k] || 0) && localStorage.getItem('werd2:' + k) != null) rows.push({ user_id: S.user.id, key: k, value: store.get(k), ts: t }) });
  if (!rows.length) return; const { error } = await S.client.from('werd_sync').upsert(rows, { onConflict: 'user_id,key' }); if (error) throw error;
  rows.forEach(r => { pushed[r.key] = r.ts }); lss('__pushed', pushed); const pl = lsj('__pulled', {}); rows.forEach(r => pl[r.key] = r.ts); lss('__pulled', pl);
}
let dt; W.on('change', k => { if (S.user && W.SYNC_KEYS.includes(k)) { clearTimeout(dt); dt = setTimeout(S.run, 2500) } });
S.lastSaved = () => lsj('__last', 0);
