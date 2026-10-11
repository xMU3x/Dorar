/* محرّك التذكيرات: جدولة محلية متكرّرة عبر Capacitor (أسبوعيًا لكل يوم مختار) + تذكير الصيام بالتاريخ.
   المخزَّن في store 'reminders' = { o:{ id:{on,time,days} } , custom:[{id,nid,title,body,icon,time,days,on}] } */
const N = W.notify = {};
const LN = () => window.Capacitor?.Plugins?.LocalNotifications;
const isNative = () => !!window.Capacitor?.isNativePlatform?.() || !!LN();
const ALL = [0, 1, 2, 3, 4, 5, 6];
/* التذكيرات الجاهزة (قابلة للتعديل: الوقت والأيام والتفعيل) */
N.DEFAULTS = [
  { id: 'morning', n: 1, title: 'أذكار الصباح', body: 'أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ. ابدأ يومك بذكر الله', icon: 'sun', time: '06:00', days: ALL, on: true, go: 'zikr/hisn-27' },
  { id: 'evening', n: 2, title: 'أذكار المساء', body: 'أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ. اختم نهارك بالأذكار', icon: 'sunset', time: '17:00', days: ALL, on: true, go: 'zikr/hisn-27e' },
  { id: 'sleep', n: 3, title: 'أذكار النوم', body: 'باسمك اللهم أموت وأحيا. لا تنم قبل أذكار النوم', icon: 'moon', time: '22:30', days: ALL, on: true, go: 'zikr/hisn-28' },
  { id: 'wird', n: 4, title: 'ورد القرآن', body: 'وردك اليوم ينتظرك، ولو صفحة واحدة', icon: 'book', time: '21:00', days: ALL, on: true, go: 'khatma' },
  { id: 'chal', n: 5, title: 'تحديات اليوم', body: 'تحدٍّ واحد يكفي لتحافظ على سلسلتك', icon: 'check', time: '20:00', days: ALL, on: true, go: 'challenges' },
  { id: 'kahf', n: 6, title: 'سورة الكهف', body: 'يوم الجمعة · سورة الكهف وكثرة الصلاة على النبي ﷺ', icon: 'book', time: '09:00', days: [5], on: false, go: 'khatma' },
  { id: 'qiyam', n: 7, title: 'قيام الليل', body: 'الثلث الأخير من الليل · وقت الدعاء والاستغفار', icon: 'moon', time: '03:30', days: ALL, on: false },
  { id: 'fast', n: 8, title: 'تذكير الصيام', body: 'غدًا يوم صيام، انوِ الصيام من الليل', icon: 'moon', time: '20:00', days: ALL, on: false, go: 'fasting', special: 'fast' }
];
const NCH = 'werd_remind_v3';
N.status = { perm: 'unknown', exact: 'unknown' };
const RS = () => store.get('reminders', { o: {}, custom: [], seq: 100 });
const upR = fn => { const r = RS(); r.o ||= {}; r.custom ||= []; fn(r); store.set('reminders', r) };
N.list = () => { const r = RS(); return N.DEFAULTS.map(d => ({ ...d, ...(r.o?.[d.id] || {}), custom: false })) };
N.custom = () => (RS().custom || []).map(c => ({ icon: 'bell', days: ALL, ...c, custom: true }));
N.all = () => [...N.list(), ...N.custom()];
N.update = (it, patch) => { upR(r => { if (it.custom) { const c = r.custom.find(x => x.id === it.id); c && Object.assign(c, patch) } else r.o[it.id] = { ...(r.o[it.id] || {}), ...patch } }); N.schedule() };
N.addCustom = c => { upR(r => { r.seq = (r.seq || 100) + 1; r.custom.push({ id: 'c' + Date.now(), nid: r.seq, on: true, ...c }) }); N.schedule() };
N.remove = id => { upR(r => { r.custom = r.custom.filter(c => c.id !== id) }); N.schedule() };
N.reset = it => { upR(r => { delete r.o[it.id] }); N.schedule() };
N.count = () => N.all().filter(x => x.on).length;
N.fmt = time => { const [h, m] = time.split(':').map(Number); return D.fmtT(h, m) };
N.daysLabel = days => days.length === 7 ? 'كل يوم' : !days.length ? 'بدون أيام' : days.length === 2 && days.includes(1) && days.includes(4) ? 'الاثنين والخميس' : days.length === 1 ? D.WDAYS[days[0]] : [...days].sort((a, b) => ((a + 1) % 7) - ((b + 1) % 7)).map(d => D.WDAYS[d].replace('ال', '')).join('، ');

N.fastBody = d => { const f = W.fast?.info(d); const t = f?.tags.find(x => x.kind !== 'eid'); return t ? `غدًا ${t.t} — انوِ الصيام من الليل` : 'غدًا يوم صيام، انوِ الصيام من الليل' };
N.occurrences = (it, from = new Date(), days = 8) => {
  const [h, m] = it.time.split(':').map(Number), out = [];
  for (let i = 0; i < days; i++) {
    const d = new Date(from.getFullYear(), from.getMonth(), from.getDate() + i, h, m, 0, 0);
    if (d <= from) continue;
    if (it.special === 'fast') { if (W.fast?.isFastDay(D.addDays(d, 1))) out.push(d) } else if ((it.days || ALL).includes(d.getDay())) out.push(d);
  }
  return out;
};
N.next = () => { const now = new Date(); let best = null; N.all().filter(x => x.on).forEach(it => { const o = N.occurrences(it, now, it.special ? 30 : 8)[0]; if (o && (!best || o < best.at)) best = { it, at: o } }); return best };
N.when = at => { const df = dayDiff(new Date(), at), t = N.fmt(`${pad(at.getHours())}:${pad(at.getMinutes())}`); return `${df === 0 ? 'اليوم' : df === 1 ? 'غدًا' : D.WDAYS[at.getDay()]} ${AR(t.t)} ${t.s}` };

/* ---------- الأذونات والقناة ---------- */
N.channels = async () => { const l = LN(); if (!l?.createChannel) return; await l.createChannel({ id: NCH, name: 'التذكيرات والأذكار', description: 'أذكار الصباح والمساء والنوم وورد القرآن وغيرها', importance: 4, visibility: 1, lights: true, lightColor: '#2F6B52', vibration: true }).catch(e => console.warn('channel', e)) };
N.check = async () => {
  const l = LN(); if (!l) { N.status.perm = 'Notification' in window ? (Notification.permission === 'default' ? 'prompt' : Notification.permission) : 'denied'; return N.status }
  try { N.status.perm = (await l.checkPermissions()).display } catch { }
  try { if (l.checkExactNotificationSetting) N.status.exact = (await l.checkExactNotificationSetting()).exact_alarm } catch { N.status.exact = 'granted' }
  return N.status;
};
N.perm = async () => {
  const l = LN();
  if (l) { try { let r = await l.checkPermissions(); if (r.display !== 'granted') r = await l.requestPermissions(); N.status.perm = r.display; return r.display === 'granted' } catch (e) { console.warn(e); return false } }
  if ('Notification' in window) return (await Notification.requestPermission()) === 'granted';
  return false;
};
N.exact = async (ask = true) => {
  const l = LN(); if (!l?.checkExactNotificationSetting) return true;
  try {
    let r = await l.checkExactNotificationSetting(); if (r.exact_alarm === 'granted') return true; if (!ask) return false;
    const ok = await W.dialog({ title: 'السماح بالتنبيه في الوقت الدقيق', body: '<p class="sub">لكي تصل التذكيرات في موعدها بالضبط، فعّل «المنبهات والتذكيرات» لتطبيق وِرد في الصفحة التالية.</p>', ok: 'فتح الإعداد', cancel: 'لاحقًا' });
    if (ok) { await l.changeExactNotificationSetting(); r = await l.checkExactNotificationSetting() } return r.exact_alarm === 'granted';
  } catch { return true }
};
N.init = async () => {
  await N.channels(); await N.check();
  const l = LN(); l?.addListener?.('localNotificationActionPerformed', e => { const go = e?.notification?.extra?.go; if (go) W.go(go) });
  if (isNative() && N.count() && N.status.perm !== 'granted' && !store.get('notif_asked', false)) { store.set('notif_asked', true, true); await N.perm() }
  await N.schedule();
  if (isNative() && N.status.perm === 'granted' && N.status.exact === 'denied' && !store.get('exact_asked', false)) { store.set('exact_asked', true, true); setTimeout(() => N.exact(true).then(() => N.schedule()), 1200) }
};

/* ---------- الجدولة ---------- */
let timers = [], nBusy = false, nAgain = false;
const chunk = (a, n) => { const r = []; for (let i = 0; i < a.length; i += n) r.push(a.slice(i, i + n)); return r };
const base = it => it.custom ? 1000 + (it.nid || 0) * 10 : 100 + it.n * 10;
N.build = () => {
  const out = [], now = new Date();
  N.all().filter(x => x.on).forEach(it => {
    const [h, m] = it.time.split(':').map(Number), extra = it.go ? { go: it.go } : {};
    if (it.special === 'fast') { N.occurrences(it, now, 30).slice(0, 14).forEach((at, i) => out.push({ id: 9000 + i, title: it.title, body: N.fastBody(D.addDays(at, 1)), at, extra })); return }
    if ((it.days || ALL).length === 7) out.push({ id: base(it), title: it.title, body: it.body || '', on: { hour: h, minute: m }, extra });
    else (it.days || []).forEach(d => out.push({ id: base(it) + d + 1, title: it.title, body: it.body || '', on: { weekday: d + 1, hour: h, minute: m }, extra }));
  });
  return out;
};
N.schedule = async () => {
  if (nBusy) { nAgain = true; return } nBusy = true;
  try {
    const items = N.build(), l = LN(), now = new Date();
    if (l) {
      const st = await N.check();
      try { const p = await l.getPending(); if (p.notifications?.length) await l.cancel({ notifications: p.notifications.map(x => ({ id: x.id })) }) } catch (e) { console.warn('cancel', e) }
      if (st.perm !== 'granted') { N.scheduled = 0; return }
      let ok = 0;
      for (const part of chunk(items, 40)) {
        const mk = x => ({ id: x.id, title: x.title, body: x.body, channelId: NCH, smallIcon: 'ic_stat_werd', iconColor: '#2F6B52', extra: x.extra, schedule: x.at ? { at: x.at, allowWhileIdle: true } : { on: x.on, allowWhileIdle: true } });
        try { await l.schedule({ notifications: part.map(mk) }); ok += part.length } catch (e) { console.warn('LN schedule', e); for (const one of part) { try { await l.schedule({ notifications: [mk(one)] }); ok++ } catch { } } }
      }
      N.scheduled = ok;
    } else {
      timers.forEach(clearTimeout); timers = [];
      N.all().filter(x => x.on).forEach(it => N.occurrences(it, now, 2).forEach(at => { if (at - now < 864e5) timers.push(setTimeout(() => { if ('Notification' in window && Notification.permission === 'granted') new Notification(it.title, { body: it.special ? N.fastBody(D.addDays(at, 1)) : it.body, icon: 'icons/icon-192.png' }) }, at - now)) }));
      N.scheduled = timers.length;
    }
  } finally { nBusy = false; if (nAgain) { nAgain = false; N.schedule() } }
};
N.test = async () => {
  if (!(await N.perm())) { W.toast('الإشعارات غير مسموحة. فعّلها من إعدادات النظام.'); return false }
  const l = LN();
  if (l) { await N.channels(); try { await l.schedule({ notifications: [{ id: 1, title: 'وِرد', body: 'التذكيرات تعمل بنجاح ✓', channelId: NCH, smallIcon: 'ic_stat_werd', schedule: { at: new Date(Date.now() + 1500), allowWhileIdle: true } }] }); return true } catch (e) { W.toast('تعذّر إرسال الإشعار: ' + (e?.message || e)); return false } }
  new Notification('وِرد', { body: 'التذكيرات تعمل بنجاح', icon: 'icons/icon-192.png' }); return true;
};
W.on('change', k => { if (k === 'reminders' || k === 'fast') { clearTimeout(N._t); N._t = setTimeout(N.schedule, 1200) } });
