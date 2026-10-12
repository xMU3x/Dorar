/* الصفحات 3: خطة الختمة، التحديات، الإعدادات، الحساب */
/* ---------- الختمة ---------- */
const KH = () => store.get('khatma', { read: 0, goal: 5, done: 0, start: TD(), last: null });
W.khatma = {
  get: KH,
  add(n, fromReader) {
    store.upd('khatma', { read: 0, goal: 5, done: 0, start: TD() }, k => { k.last = n; k.read += n; if (k.read >= 604) { k.read = 0; k.done = (k.done || 0) + 1; k.start = TD(); W.toast('ما شاء الله! أتممت ختمة كاملة، تقبّل الله منك') } });
    if (!fromReader) D.addPages(n); W.chal.check()
  },
  undo() { const k = KH(); if (!k.last) return; const n = k.last; store.upd('khatma', {}, z => { z.read = Math.max(0, z.read - n); z.last = 0 }); D.addPages(-n) }
};
W.pages.khatma = {
  live: true,
  render(el) {
    const k = KH(), pg = D.pagesToday(), rem = 604 - k.read, days = Math.ceil(rem / k.goal), since = Math.max(1, Math.round((new Date(TD()) - new Date(k.start)) / 864e5) + 1), nextP = Math.min(604, k.read + 1), juz = D.juzOfPage(nextP);
    el.innerHTML = `${W.top('خطة الختمة')}
    <div class="hero"><div class="row"><div class="g"><div class="sub">ختمتك الحالية</div><div style="font-size:26px;font-weight:700">${num(k.read)} من ${num(604)} صفحة</div><div class="sub">مستمرة منذ ${num(since)} يوم</div></div><div class="ring">${W.ring(k.read / 604, 72, 8, '#fff', 'rgba(255,255,255,.18)')}<div class="t">${num(Math.round(k.read / 604 * 100))}%</div></div></div><div class="bar" style="margin-top:18px"><i style="width:${k.read / 604 * 100}%"></i></div></div>
    <div class="card" style="margin-top:14px"><div class="row"><b class="g" style="font-size:18px">ورد اليوم</b><span class="sub">${num(pg)}/${num(k.goal)} صفحة</span>${ico('cal', 'chev')}</div><div class="bar"><i style="width:${Math.min(100, pg / k.goal * 100)}%"></i></div><p class="sub" style="margin:10px 0">أضف ما قرأته اليوم حتى تتابع التزامك بوضوح.</p><div class="row" style="gap:8px">${[1, 5, 10, 20].map(n => `<button class="chip o" data-a="${n}" style="flex:1">+${num(n)}</button>`).join('')}<button class="ib" id="ku" ${k.last ? '' : 'disabled style="opacity:.4"'}>${ico('undo')}</button></div></div>
    <div class="card" style="margin-top:14px"><div class="row" style="margin-bottom:6px">${ico('book')}<b style="font-size:18px">الخطوة التالية</b></div><div class="sub" style="font-size:15px">الصفحة القادمة في ختمتك: ${num(nextP)} — الجزء ${num(juz)}</div></div>
    <h2>ملخص خطتك <button class="l" id="kr" aria-label="إعادة">${ico('refresh')}</button></h2>
    <div class="grid2">${[['flag', num(rem), 'صفحة · المتبقي'], ['cal', num(days), 'يوم · المدة المتوقعة'], ['book', num(juz) , 'من ' + num(30) + ' · الجزء الحالي'], ['trophy', num(k.done || 0), 'ختمة · ختمات مكتملة']].map(x => `<div class="card" style="min-height:120px;justify-content:space-between"><span style="color:var(--pri)">${ico(x[0])}</span><div style="font-size:30px;font-weight:700">${x[1]}</div><div class="sub">${x[2]}</div></div>`).join('')}</div>
    <div class="card" style="margin-top:14px"><div class="row"><span style="color:var(--pri)">${ico('tune')}</span><div class="g"><b>عدّل الخطة حسب وقتك</b><div class="sub">هدفك الحالي ${num(k.goal)} صفحات يوميًا، وتستطيع تغييره في أي وقت.</div></div><button id="ke" style="color:var(--pri);font-weight:700;padding:10px">تعديل</button></div></div>`;
    $$('[data-a]', el).forEach(b => b.onclick = () => { W.khatma.add(+b.dataset.a); W.vib(15) }); $('#ku', el).onclick = () => W.khatma.undo();
    $('#kr', el).onclick = async () => { if (await W.dialog({ title: 'إعادة الختمة؟', body: 'سيُصفَّر تقدّم ختمتك الحالية.', ok: 'إعادة', danger: true })) store.upd('khatma', {}, z => { z.read = 0; z.start = TD(); z.last = 0 }) };
    $('#ke', el).onclick = async () => { const r = await W.dialog({ title: 'الهدف اليومي', body: `<input id="kg" type="number" inputmode="numeric" value="${k.goal}" min="1" max="604">`, ok: 'حفظ' }); if (r) store.upd('khatma', {}, z => { z.goal = Math.max(1, Math.min(604, +$('#kg').value || 5)) }) };
  }
};

/* ---------- التحديات ---------- */
const CH = () => store.get('challenges', { done: {} });
const CATS = { quran: ['القرآن', 'book'], dhikr: ['ذكر', 'spark'], prayer: ['صلاة', 'mosque'], good: ['أعمال خير', 'hand'], manners: ['أخلاق', 'user'], habits: ['عادات يومية', 'sun'], self: ['تطوير النفس', 'flag'], worship: ['عبادة', 'star'] };
const PTS = { day: 10, week: 30, month: 100 }, PN = { day: 'تحديات اليوم', week: 'تحديات الأسبوع', month: 'أهداف الشهر' };
const weekStart = d => { const x = new Date(d); x.setHours(12); x.setDate(x.getDate() - ((x.getDay() + 1) % 7)); return x };
const periodKey = (p, d = new Date()) => p === 'day' ? dkey(d) : p === 'week' ? 'w' + dkey(weekStart(d)) : 'm' + dkey(d).slice(0, 7);
const periodDays = (p, d = new Date()) => { const out = [], t = new Date(d); t.setHours(12); if (p === 'day') return [dkey(t)]; if (p === 'week') { const s = weekStart(t); for (let i = 0; i < 7; i++) { const x = new Date(s); x.setDate(s.getDate() + i); out.push(dkey(x)) } return out } const m = t.getMonth(); const x = new Date(t.getFullYear(), m, 1, 12); while (x.getMonth() === m) { out.push(dkey(x)); x.setDate(x.getDate() + 1) } return out };
const seeded = (arr, seed, n) => { let s = 0; for (const c of seed) s = (s * 31 + c.charCodeAt(0)) >>> 0; const a = [...arr]; for (let i = a.length - 1; i > 0; i--) { s = (s * 1664525 + 1013904223) >>> 0; const j = s % (i + 1);[a[i], a[j]] = [a[j], a[i]] } return a.slice(0, n) };
const TMAP = { subhan: ['subhan', 'subhanh'], hamd: ['hamd'], akbar: ['akbar'], istighfar: ['istighfar'], tahlil: ['tahlil'], salawat: ['salawat'], all: 'all' }, ZMAP = { morning: 'hisn-27', evening: 'hisn-27e', sleep: 'hisn-28' };
async function autoVal(c, p) {
  const days = periodDays(p); if (!c.auto) return null;
  if (c.auto === 'pages') { const pr = QS().pagesRead; return days.reduce((a, d) => a + (pr[d] || 0), 0) }
  if (c.auto.startsWith('tasbeeh:')) return days.reduce((a, d) => a + W.tas.daySum(TMAP[c.auto.slice(8)], d), 0);
  if (c.auto.startsWith('azkar:')) { const id = ZMAP[c.auto.slice(6)], cat = (await W.az.cats()).find(x => x.id === id); if (!cat) return 0; const A = AZ().c; return days.filter(d => cat.azkar.every(z => ((A[d] || {})[id] || {})[z.id] >= (z.count || 1))).length }
  return null
}
const chList = async () => (await D.load('challenges')).challenges;
const pick = async p => { const L = (await chList()).filter(c => c.period === p), n = p === 'day' ? 5 : p === 'week' ? 3 : 2; return seeded(L, periodKey(p), n) };
W.chal = {
  async state(p) { const L = await pick(p), S = CH().done, pk = periodKey(p); const out = []; for (const c of L) { const v = await autoVal(c, p), t = c.target || 1, ok = !!S[c.id + ':' + pk] || (v != null && v >= t); out.push({ c, v, t, ok }) } return out },
  async today() { const s = await W.chal.state('day'); return { done: s.filter(x => x.ok).length, total: s.length } },
  async check() { /* يثبّت إنجاز التحديات التلقائية ويعطي إشعارًا */ let changed = false, got = 0; for (const p of ['day', 'week', 'month']) { const s = await W.chal.state(p), pk = periodKey(p); for (const x of s) if (x.ok && !CH().done[x.c.id + ':' + pk]) { store.upd('challenges', { done: {} }, z => { z.done[x.c.id + ':' + pk] = Date.now() }); changed = true; got++ } } if (got) { W.toast('أحسنت، أنجزت تحديًا جديدًا'); W.vib(40) } return changed },
  total() { const d = CH().done, n = Object.keys(d).length; let pts = 0; Object.keys(d).forEach(k => { const id = k.split(':')[0], pk = k.split(':')[1]; pts += pk[0] === 'w' ? PTS.week : pk[0] === 'm' ? PTS.month : PTS.day }); return { n, pts } }
};
let cTab = 'day';
W.pages.challenges = {
  live: true,
  async render(el) {
    await W.chal.check(); const S = await W.chal.state(cTab), done = S.filter(x => x.ok).length, st = D.streak(), act = store.get('activity', { days: {} }).days, ws = weekStart(new Date()), tot = W.chal.total(), lvl = Math.floor(tot.pts / 100) + 1, pn = 100 - tot.pts % 100;
    const nextIdx = S.findIndex(x => !x.ok), WD = ['س', 'ح', 'ن', 'ث', 'ر', 'خ', 'ج'];
    el.innerHTML = `${W.top('التحديات')}
    <div class="hero cl"><div class="row"><div class="g"><div style="font-family:var(--a);font-size:26px;font-weight:700">${done >= S.length ? 'ما شاء الله! أتممت الكل' : done ? 'أحسنت، واصل' : 'ابدأ بأسهل تحدٍّ'}</div><div class="sub" style="margin-top:6px">خطوة صغيرة اليوم تصنع عادة دائمة.</div></div><div class="ring">${W.ring(S.length ? done / S.length : 0, 92, 10, 'var(--pri)', 'rgba(60,106,62,.15)')}<div class="t" style="flex-direction:column;display:grid;text-align:center;font-size:26px">${num(done)}<small class="sub" style="font-size:12px;font-weight:400">من ${num(S.length)}</small></div></div></div>
      <div class="wk" style="margin-top:16px">${WD.map((l, i) => { const d = new Date(ws); d.setDate(ws.getDate() + i); const k = dkey(d); return `<div><i class="${act[k] ? 'd' : ''}">${act[k] ? ico('check') : ''}</i>${l}</div>` }).join('')}</div>
      <div class="row" style="margin-top:14px;font-weight:700"><span style="color:var(--pri);display:flex;gap:6px;align-items:center">${ico('fire')} ${num(st.cur)} يوم متواصل</span><span class="g"></span><span class="sub">أفضل سلسلة ${num(st.best)}</span></div></div>
    <div class="chips" style="margin-top:14px">${['day', 'week', 'month'].map(p => `<button class="chip ${cTab === p ? 'on' : ''}" data-p="${p}">${PN[p]}</button>`).join('')}</div>
    <h2 style="margin-top:8px">${PN[cTab]}</h2><p class="sub" style="margin:-8px 4px 12px">ابدأ بما تستطيع، فالخطوة الصغيرة تكفي</p>
    <div class="list">${S.map((x, i) => { const cat = CATS[x.c.cat] || ['', 'star']; return `<button class="item ${i === nextIdx ? 'next' : ''}" data-i="${i}" style="display:block">${i === nextIdx ? `<div class="lbl">${ico('flag')} خطوتك التالية</div>` : ''}<div class="row" style="margin-top:${i === nextIdx ? 8 : 0}px"><span class="chk ${x.ok ? 'on' : ''}">${ico('check')}</span><span class="g" style="text-align:start"><b>${esc(x.c.title)}</b><span class="sub" style="display:flex;gap:6px;align-items:center">${ico(cat[1])} ${cat[0]}${x.v != null && !x.ok ? ` · ${num(Math.min(x.v, x.t))}/${num(x.t)}` : ''}</span></span><span class="pts">+${PTS[cTab]}</span></div></button>` }).join('')}</div>
    <h2>الإنجازات <small>المستوى ${num(lvl)} · ${num(pn)} نقطة للمستوى التالي</small></h2><div class="grid2">${achievements(tot, st).map(a => `<div class="card" style="opacity:${a.ok ? 1 : .5};align-items:center;text-align:center"><span class="ic">${ico(a.ok ? 'trophy' : 'lock')}</span><b style="font-size:14px">${a.t}</b></div>`).join('')}</div>
    <p class="tip">التحديات للتذكير والمتابعة، وليست أحكامًا شرعية</p>`;
    $$('[data-p]', el).forEach(b => b.onclick = () => { cTab = b.dataset.p; W.refresh() });
    $$('[data-i]', el).forEach(b => b.onclick = () => { const x = S[b.dataset.i]; if (x.c.auto && x.v != null && !x.ok) { W.toast('يُحتسب هذا التحدي تلقائيًا عند إنجازه'); return } const k = x.c.id + ':' + periodKey(cTab); store.upd('challenges', { done: {} }, z => { z.done[k] ? delete z.done[k] : z.done[k] = Date.now() }); D.touch(); W.vib(20) });
  }
};
function achievements(tot, st) { const pr = QS().pagesRead, pages = Object.values(pr).reduce((a, b) => a + b, 0), T = TS(), tasb = Object.values(T.total).reduce((a, b) => a + b, 0); return [['إنجاز ١٠ تحديات', tot.n >= 10], ['إنجاز ٥٠ تحديًا', tot.n >= 50], ['إنجاز ١٠٠ تحدٍّ', tot.n >= 100], ['نشاط ٣ أيام متتالية', st.best >= 3], ['نشاط ٧ أيام متتالية', st.best >= 7], ['نشاط ٣٠ يومًا متتالية', st.best >= 30], ['قراءة ١٠ صفحات', pages >= 10], ['قراءة ١٠٠ صفحة', pages >= 100], ['قراءة ٦٠٤ صفحات', pages >= 604], ['١٬٠٠٠ تسبيحة', tasb >= 1000], ['١٠٬٠٠٠ تسبيحة', tasb >= 1e4]].map(x => ({ t: x[0], ok: x[1] })) }

/* ---------- الإعدادات ---------- */
W.pages.settings = {
  live: true,
  render(el) {
    const c = k => W.cfg.get(k), seg = (k, opts) => `<div class="chips">${opts.map(o => `<button class="chip ${c(k) === o[0] ? 'on' : ''}" data-s="${k}" data-v="${o[0]}">${o[1]}</button>`).join('')}</div>`, tg = (k, t, s = '') => `<div class="row" style="padding:10px 0"><span class="g"><b>${t}</b><div class="sub">${s}</div></span><button class="sw ${c(k) ? 'on' : ''}" data-t="${k}"></button></div>`;
    el.innerHTML = `${W.top('الإعدادات')}<h2 style="margin-top:4px">المظهر</h2><div class="card"><b>الوضع</b>${seg('mode', [['auto', 'تلقائي'], ['light', 'فاتح'], ['dark', 'داكن']])}<div class="sub">التلقائي يتبع وضع الجهاز (فاتح أو داكن)</div><b style="display:block;margin-top:14px">اللون</b>${seg('pal', [['burgundy', 'عنابي'], ['green', 'أخضر']])}${tg('arDigits', 'الأرقام العربية', '١٢٣ بدل 123')}</div>
    <h2>التفاعل والتاريخ</h2><div class="card">${tg('vibrate', 'الاهتزاز', 'اهتزاز خفيف عند اللمس والتنقل')}<div class="row" style="padding:10px 0"><span class="g"><b>تصحيح التاريخ الهجري</b><div class="sub">لموافقة الرؤية في بلدك</div></span><button class="ib" id="hm">−</button><b style="min-width:26px;text-align:center">${num(c('hijriAdj'))}</b><button class="ib" id="hp">+</button></div></div>
    <h2>روابط</h2><div class="list"><button class="item" data-go="reminders"><span class="ic">${ico('bell')}</span><span class="g"><b>التذكيرات</b></span>${ico('chev', 'chev')}</button><button class="item" data-go="account"><span class="ic">${ico('user')}</span><span class="g"><b>حسابي والمزامنة</b></span>${ico('chev', 'chev')}</button><button class="item" data-go="about"><span class="ic">${ico('info')}</span><span class="g"><b>عن التطبيق</b></span>${ico('chev', 'chev')}</button></div>`;
    $$('[data-s]', el).forEach(b => b.onclick = () => { W.cfg.set(b.dataset.s, b.dataset.v); W.refresh() }); $$('[data-t]', el).forEach(b => b.onclick = () => { W.cfg.set(b.dataset.t, !c(b.dataset.t)); W.refresh() });
    $('#hm', el).onclick = () => { W.cfg.set('hijriAdj', Math.max(-2, c('hijriAdj') - 1)); D.hjClear(); W.notify.schedule(); W.refresh() }; $('#hp', el).onclick = () => { W.cfg.set('hijriAdj', Math.min(2, c('hijriAdj') + 1)); D.hjClear(); W.notify.schedule(); W.refresh() };
  }
};
W.pages.about = {
  render(el) { el.innerHTML = `${W.top('عن التطبيق')}<div class="gb" style="min-height:auto;padding:20px 0"><img class="lg" src="brand/app_icon.png" alt=""><h1>وِرد</h1><p class="sub">كل أدواتك الإسلامية في مكان واحد: الأذكار والتذكيرات والصيام والتقويم الهجري والتحديات.</p></div><div class="card"><b>المصادر</b><p class="sub" style="line-height:1.9;margin-top:6px">الأذكار: حصن المسلم (hisnmuslim.com) · التلاوات: mp3quran.net · التقويم الهجري: أم القرى</p></div><p class="tip">تحتفظ ببياناتك على جهازك، وعند تسجيل الدخول تُزامَن تلقائيًا مع حسابك.</p>` }
};

/* ---------- الحساب / تسجيل الدخول ---------- */
const stIcon = { off: ['cloudoff', 'غير مفعّلة'], syncing: ['sync', 'جارٍ المزامنة…'], ok: ['check', 'تمت المزامنة'], error: ['cloudoff', 'تعذّرت المزامنة، سنحاول مرة أخرى تلقائيًا'], offline: ['cloudoff', 'لا يوجد اتصال، ستتم المزامنة عند عودته'] };
W.pages.account = {
  live: false,
  render(el) { W.sync.user ? profile(el) : loginView(el) }
};
W.on('auth', () => { if (W.cur?.id === 'account') W.pages.account.render($('#p-account')) });
W.on('sync', () => { if (W.cur?.id === 'account') { const e = $('#p-account'); e && W.sync.user && profile(e) } });
function loginView(el) {
  let create = false;
  const draw = () => {
    el.innerHTML = `${W.top('تسجيل الدخول')}<div class="gb"><img class="lg" src="brand/app_icon.png" alt=""><div><h1 style="font-size:26px">مزامنة تقدّمك</h1><p class="sub" style="margin-top:6px">سجّل الدخول لتُحفظ ختمتك وسبحتك وأذكارك وعلاماتك على حسابك وتظهر على أي جهاز.</p></div>
      <button class="gbtn" id="g">${GLOGO} المتابعة بحساب Google</button><div class="sep">أو بالبريد الإلكتروني</div>
      <div style="width:100%;display:grid;gap:10px"><input id="em" type="email" placeholder="البريد الإلكتروني" autocomplete="email" dir="ltr" style="text-align:start"><input id="pw" type="password" placeholder="كلمة المرور (6 أحرف على الأقل)" autocomplete="${create ? 'new-password' : 'current-password'}" dir="ltr"><div class="err" id="er"></div><button class="btn" id="go">${create ? 'إنشاء الحساب' : 'تسجيل الدخول'}</button></div>
      <button id="tg" class="sub" style="padding:8px">${create ? 'لديك حساب؟ سجل الدخول' : 'ليس لديك حساب؟ أنشئ حسابًا'}</button><button id="sk" style="color:var(--on2);padding:8px">تخطي · استخدام التطبيق بدون حساب</button></div>`;
    $('#g', el).onclick = () => W.sync.google(); $('#tg', el).onclick = () => { create = !create; draw() }; $('#sk', el).onclick = () => { localStorage.setItem('werd2:__seen', '1'); W.go('home', true) };
    $('#go', el).onclick = async () => { const e = $('#em').value.trim(), p = $('#pw').value, er = $('#er'); if (!/^\S+@\S+\.\S+$/.test(e)) return er.textContent = 'أدخل بريدًا إلكترونيًا صحيحًا.'; if (p.length < 6) return er.textContent = 'كلمة المرور يجب أن تكون 6 أحرف على الأقل.'; er.textContent = ''; const b = $('#go'); b.disabled = true; const { data, error } = await W.sync.email(e, p, create); b.disabled = false;
      if (error) return er.textContent = /already|registered/i.test(error.message) ? 'هذا البريد مسجل بالفعل.' : /invalid|credentials/i.test(error.message) ? 'البريد أو كلمة المرور غير صحيحة.' : error.message === 'no-client' ? 'لم يتم ضبط Supabase بعد (js/config.js).' : 'تعذّر إكمال العملية الآن، حاول مرة أخرى.';
      if (create && !data.session) { er.className = 'ok'; er.textContent = 'تم إنشاء الحساب. افحص بريدك الإلكتروني لتأكيد الحساب.' } else { localStorage.setItem('werd2:__seen', '1'); W.go('home', true) } }
  }; draw();
}
function profile(el) {
  const u = W.sync.user, nm = u.user_metadata?.full_name || u.user_metadata?.name || u.email.split('@')[0], prov = (u.app_metadata?.provider || 'email') === 'google' ? 'حساب Google' : 'حساب بريد إلكتروني', s = stIcon[W.sync.status] || stIcon.off, last = W.sync.lastSaved();
  el.innerHTML = `${W.top('حسابي')}<div class="card"><div class="row" style="gap:16px"><span class="acc">${esc(nm[0].toUpperCase())}</span><div class="g"><b style="font-size:20px">${esc(nm)}</b><div class="sub" dir="ltr" style="text-align:start">${esc(u.email)}</div><div class="sub">${prov}</div></div></div></div>
  <div class="card" style="margin-top:14px"><div class="row" style="margin-bottom:8px"><b class="g" style="font-size:18px">مزامنة التقدّم</b><span style="color:${W.sync.status === 'ok' ? 'var(--ok)' : W.sync.status === 'syncing' ? 'var(--pri)' : '#A8332B'}">${ico(s[0])}</span></div><div style="color:${W.sync.status === 'ok' || W.sync.status === 'syncing' ? 'var(--on2)' : '#A8332B'};font-size:14px">${s[1]}${last && W.sync.status === 'ok' ? ` · ${new Date(last).toLocaleTimeString('ar-EG', { hour: '2-digit', minute: '2-digit' })}` : ''}</div><p class="sub" style="margin:10px 0 14px;line-height:1.9">الختمة • التسبيح • الأذكار (المفضلة والعدّادات) • التذكيرات • أيام الصيام المخصّصة • التحديات والإعدادات</p><button class="btn o" id="sn2">${ico('sync')} مزامنة الآن</button></div>
  <div class="card" style="margin-top:14px;padding:0"><button class="item" id="lo" style="border:0;border-radius:28px 28px 0 0"><span class="g"><b>تسجيل الخروج</b></span>${ico('logout')}</button><div style="height:1px;background:var(--line)"></div><button class="item" id="dl" style="border:0;border-radius:0 0 28px 28px;color:#A8332B"><span class="g"><b>حذف الحساب</b></span>${ico('del')}</button></div>`;
  $('#sn2', el).onclick = () => W.sync.run(); $('#lo', el).onclick = async () => { await W.sync.run(); await W.sync.logout(); W.toast('تم تسجيل الخروج'); W.go('home', true) };
  $('#dl', el).onclick = async () => { if (await W.dialog({ title: 'مسح الحساب نهائيًا؟', body: 'سيتم حذف حسابك وكل بياناتك المحفوظة على السيرفر. لا يمكن التراجع عن هذا الإجراء.', ok: 'مسح الحساب نهائيًا', danger: true })) { const ok = await W.sync.deleteAccount(); W.toast(ok ? 'تم مسح حسابك.' : 'تعذر مسح الحساب. حاول مرة أخرى.'); if (ok) W.go('home', true) } };
}
W.pages.login = { render: (el) => loginView(el) };
