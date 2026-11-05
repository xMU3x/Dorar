/* الصفحات 2: الأذكار، التسبيح، الرقية (+ تخزين صفحات القرآن المقروءة للختمة) */
const QS = () => store.get('quran', { fav: [], marks: [], hl: {}, last: 1, pagesRead: {} });
const upQ = fn => store.upd('quran', { fav: [], marks: [], hl: {}, last: 1, pagesRead: {} }, fn);

/* ---------- الأذكار ---------- */
const AZ = () => store.get('azkar', { fav: [], c: {} });
const upA = fn => store.upd('azkar', { fav: [], c: {} }, fn);
W.az = {
  async cats() { return (await D.load('azkar')).categories },
  count(cat, zid) { return (AZ().c[TD()]?.[cat] || {})[zid] || 0 },
  async progress(catId) { const c = (await W.az.cats()).find(x => x.id === catId); if (!c) return { done: 0, total: 0 }; let d = 0; c.azkar.forEach(z => { if (W.az.count(catId, z.id) >= (z.count || 1)) d++ }); return { done: d, total: c.azkar.length } }
};
let zQ = '';
W.pages.azkar = {
  live: true,
  async render(el) {
    const cats = await W.az.cats(), hour = new Date().getHours(), hid = hour >= 15 || hour < 3 ? 'hisn-27e' : 'hisn-27', hc = cats.find(c => c.id === hid), pr = await W.az.progress(hid), A = AZ(), favN = A.fav.length;
    const catIcon = i => ({ wb_sunny: 'sun', nightlight_round: 'moon', bedtime: 'moon', mosque: 'mosque', water_drop: 'water', home: 'home', flight: 'pin' }[i] || 'spark');
    el.innerHTML = `${W.top('الأذكار', { back: false, left: `<button class="ib p" data-go="zfav" aria-label="المفضلة">${ico('fav')}</button>` })}
    <button class="hero" data-go="zikr/${hid}"><div class="row"><span class="ic" style="background:rgba(255,255,255,.18);color:inherit">${ico(hid === 'hisn-27e' ? 'moon' : 'sun')}</span><div class="g"><div class="sub">${num(hc.azkar.length)} من الأذكار</div><div style="font-size:22px;font-weight:700">${esc(hc.title)}</div></div></div>${W.MOSQUE}<div class="bar"><i style="width:${pr.total ? pr.done / pr.total * 100 : 0}%"></i></div><div class="sub" style="margin-top:6px">أنجزت ${num(pr.done)} من ${num(pr.total)}</div></button>
    <input id="zs" placeholder="ابحث عن ذكر أو دعاء..." value="${esc(zQ)}" style="margin:14px 0 4px"><div class="list" id="zl" style="margin-top:10px"></div>`;
    const draw = () => { const b = D.bare(zQ); let L = cats; let hits = []; if (b) { L = cats.filter(c => D.bare(c.title).includes(b)); if (b.length > 2) cats.forEach(c => c.azkar.forEach(z => { if (hits.length < 25 && D.bare(z.text).includes(b)) hits.push([c, z]) })) }
      $('#zl', el).innerHTML = L.map(c => `<button class="item" data-z="${c.id}"><span class="ic">${ico(catIcon(c.icon))}</span><span class="g"><b>${esc(c.title)}</b><span class="sub">${num(c.azkar.length)} ${c.azkar.length === 1 ? 'ذكر' : 'أذكار'}</span></span>${ico('chev', 'chev')}</button>`).join('') + (hits.length ? `<h2 style="font-size:15px">في كل الأذكار</h2>` + hits.map(([c, z]) => `<button class="item" data-z="${c.id}"><span class="g"><span style="font-family:var(--a);font-size:17px;line-height:1.9">${esc(z.text.slice(0, 110))}…</span><span class="sub">${esc(c.title)}</span></span></button>`).join('') : '') || '<p class="tip">لا توجد نتائج</p>'; $$('[data-z]', el).forEach(x => x.onclick = () => W.go('zikr/' + x.dataset.z)) };
    draw(); $('#zs', el).oninput = e => { zQ = e.target.value; draw() };
  }
};
let hideDone = false;
const ZSTEPS = [18, 21, 24, 27, 30, 33, 36, 39, 42];
const fontSheet = (key, apply, sample) => {
  const cur = ZSTEPS.reduce((a, b) => Math.abs(b - W.cfg.get(key)) < Math.abs(a - W.cfg.get(key)) ? b : a, 28);
  const s = W.sheet(`<h3 style="text-align:center">حجم الخط</h3><div class="fsw"><div class="fsp" id="fsp" style="font-size:${cur}px">${sample}</div><div class="fsr"><span style="font-size:15px">أ</span><input class="rg2 nh" id="fsr" type="range" min="0" max="8" step="1" value="${ZSTEPS.indexOf(cur)}"><span style="font-size:26px">أ</span></div></div>`);
  const r = $('#fsr', s); let last = +r.value; r.oninput = () => { const i = +r.value, v = ZSTEPS[i]; if (i !== last) { last = i; W.hap.tick() } $('#fsp', s).style.fontSize = v + 'px'; apply(v) };
  r.onchange = () => { W.cfg.set(key, ZSTEPS[+r.value]); W.hap.click() };
};
W.pages.zikr = {
  live: false,
  async render(el, [id]) {
    const c = (await W.az.cats()).find(x => x.id === id); if (!c) return W.go('azkar', true);
    const setFs = v => { const b = $('#zbody', el); if (b) b.style.setProperty('--zfs', v + 'px') };
    const draw = () => { const A = AZ(); let d = 0; const cards = c.azkar.map(z => { const n = W.az.count(id, z.id), t = z.count || 1, done = n >= t; if (done) d++; if (done && hideDone) return ''; const fav = A.fav.includes(id + ':' + z.id);
      return `<div class="card zc tap nh ${done ? 'done' : ''}" data-id="${z.id}"><div class="zt">${esc(z.text)}</div><div class="src">${esc(z.source || '')}</div><div class="zf"><button class="ib mut" data-cp="${z.id}" aria-label="نسخ">${ico('copy')}</button><button class="ib mut" data-s="${z.id}" aria-label="مشاركة">${ico('share')}</button><span class="g" style="flex:1"></span><button class="ib mut" data-u="${z.id}" aria-label="تراجع" style="${n ? '' : 'opacity:.35'}">${ico('undo')}</button><button class="ib" data-f="${z.id}" aria-label="مفضلة">${ico(fav ? 'fav' : 'favo')}</button><button class="cnt nr ${done ? 'done' : ''}" data-c="${z.id}" aria-label="عدّاد">${done ? ico('check') : num(t - n)}</button></div></div>` }).join('');
      $('#zbody', el).innerHTML = cards || '<p class="tip">كل أذكار هذا القسم مكتملة</p>'; $('#zbar', el).style.width = d / c.azkar.length * 100 + '%'; $('#zpr', el).textContent = `أنجزت ${num(d)} من ${num(c.azkar.length)}`; setFs(W.cfg.get('zfs')) };
    /* العدّ: لمس أي مكان في بطاقة الذكر يُنقص العدّاد مع اهتزاز */
    const bump = (zid, delta, card, ev) => { const z = c.azkar.find(x => x.id === zid), t = z.count || 1, n0 = W.az.count(id, zid); if (delta > 0 && n0 >= t) { W.hap.error(); return } if (delta < 0 && n0 <= 0) return;
      upA(a => { a.c[TD()] ||= {}; a.c[TD()][id] ||= {}; a.c[TD()][id][zid] = Math.max(0, n0 + delta) }); D.touch(); const n = W.az.count(id, zid), done = n >= t;
      if (delta > 0) { done ? (W.hap.success(), W.chal.check()) : W.hap.click(); if (W.cfg.get('tsound')) W.tick(done ? 'done' : 'tick') } else W.hap.tick();
      const cn = card.querySelector('.cnt'); cn.classList.toggle('done', done); cn.innerHTML = done ? ico('check') : num(t - n); card.classList.toggle('done', done); card.querySelector('[data-u]').style.opacity = n ? 1 : .35;
      card.classList.remove('pulse'); void card.offsetWidth; card.classList.add('pulse');
      if (ev && delta > 0) { const r = card.getBoundingClientRect(), sz = Math.max(r.width, r.height) * 1.6, d = document.createElement('span'); d.className = 'zrip'; d.style.cssText = `width:${sz}px;height:${sz}px;left:${ev.clientX - r.left - sz / 2}px;top:${ev.clientY - r.top - sz / 2}px`; card.appendChild(d); setTimeout(() => d.remove(), 600) }
      const dn = c.azkar.filter(x => W.az.count(id, x.id) >= (x.count || 1)).length; $('#zbar', el).style.width = dn / c.azkar.length * 100 + '%'; $('#zpr', el).textContent = `أنجزت ${num(dn)} من ${num(c.azkar.length)}`;
      if (done && delta > 0) { if (hideDone) { setTimeout(draw, 350) } else { const nx = card.nextElementSibling; if (nx && !nx.classList.contains('done')) setTimeout(() => nx.scrollIntoView({ behavior: 'smooth', block: 'center' }), 380) } } };
    el.innerHTML = `${W.top(esc(c.title), { left: `<button class="ib" id="zfs" aria-label="حجم الخط"><b style="font-size:16px;color:var(--gold)">Aa</b></button><button class="ib" id="zm" aria-label="المزيد">${ico('more')}</button>` })}<div class="card"><div class="bar" style="margin:0"><i id="zbar"></i></div><div class="sub" id="zpr" style="margin-top:8px"></div></div><p class="tip" style="padding:10px 0 0;font-size:12px">اضغط على الذكر نفسه لإنقاص العدّاد</p><div class="list" id="zbody" style="margin-top:10px"></div>`;
    const body = $('#zbody', el);
    body.onclick = e => { const card = e.target.closest('.zc'); if (!card) return; const zid = +card.dataset.id;
      const f = e.target.closest('[data-f]'), u = e.target.closest('[data-u]'), sh = e.target.closest('[data-s]'), cp = e.target.closest('[data-cp]');
      if (f) { const k = id + ':' + zid; upA(a => { a.fav = a.fav.includes(k) ? a.fav.filter(x => x !== k) : [...a.fav, k] }); const on = AZ().fav.includes(k); f.innerHTML = ico(on ? 'fav' : 'favo'); W.hap.click(); return }
      if (u) { bump(zid, -1, card); return }
      if (sh) { W.share(c.azkar.find(x => x.id === zid).text); return }
      if (cp) { W.copy(c.azkar.find(x => x.id === zid).text); return }
      bump(zid, 1, card, e) };
    $('#zfs', el).onclick = () => fontSheet('zfs', setFs, 'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ');
    $('#zm', el).onclick = e => W.menu(e.currentTarget, [['eye', hideDone ? 'إظهار المكتملة' : 'إخفاء المكتملة', () => { hideDone = !hideDone; draw() }], ['refresh', 'إعادة تعيين العداد', async () => { if (await W.dialog({ title: 'إعادة تعيين العداد؟', body: 'سيتم تصفير تقدّمك في هذا القسم.', ok: 'إعادة', danger: true })) { upA(a => { if (a.c[TD()]) delete a.c[TD()][id] }); draw() } }]]);
    draw();
  }
};
W.pages.zfav = {
  live: true,
  async render(el) {
    const cats = await W.az.cats(), A = AZ(), L = A.fav.map(k => { const [cid, zid] = k.split(':'); const c = cats.find(x => x.id === cid), z = c?.azkar.find(x => x.id == zid); return z && [c, z] }).filter(Boolean);
    el.innerHTML = `${W.top('أذكارك المفضلة')}${L.length ? L.map(([c, z]) => `<div class="card zc" style="margin-bottom:10px"><div class="zt">${esc(z.text)}</div><div class="src">${esc(c.title)}</div></div>`).join('') : '<p class="tip">لا يوجد أذكار مفضلة بعد<br>اضغط على القلب في أي ذكر لإضافته هنا</p>'}`;
  }
};

/* ---------- الرقية الشرعية ---------- */
const RUQYA = [['سورة الفاتحة', 1, 1, 7, 1], ['أول سورة البقرة', 2, 1, 5, 1], ['آية الكرسي', 2, 255, 255, 1], ['خواتيم سورة البقرة', 2, 284, 286, 1], ['سورة الإخلاص', 112, 1, 4, 3], ['سورة الفلق', 113, 1, 5, 3], ['سورة الناس', 114, 1, 6, 3]];
W.pages.ruqya = {
  live: false,
  async render(el) {
    const q = await D.quran(), done = {}; const draw = () => { $('#rb', el).innerHTML = RUQYA.map((r, i) => { const t = q.ayahs.filter(a => a[0] === r[1] && a[1] >= r[2] && a[1] <= r[3]).map(a => a[2] + ` ﴿${num(a[1])}﴾`).join(' '), n = done[i] || 0, ok = n >= r[4]; return `<div class="card zc ${ok ? 'done' : ''}" style="margin-bottom:10px"><b style="color:var(--pri)">${r[0]}</b><div class="mushaf" style="font-size:24px">${esc((r[1] !== 1 && r[2] === 1 && r[1] !== 9 ? q.basmala + ' ' : '') + t)}</div><div class="zf"><button class="cnt ${ok ? 'done' : ''}" data-i="${i}">${ok ? ico('check') : num(r[4] - n)}</button><span class="sub">يُقال ${r[4] === 1 ? 'مرة واحدة' : 'ثلاث مرات'}</span></div></div>` }).join(''); $$('[data-i]', el).forEach(b => b.onclick = () => { done[b.dataset.i] = (done[b.dataset.i] || 0) + 1; W.vib(12); draw() }) };
    el.innerHTML = `${W.top('الرقية الشرعية', { left: `<button class="ib" id="rr">${ico('refresh')}</button>` })}<div id="rb"></div>`; $('#rr', el).onclick = () => { Object.keys(done).forEach(k => delete done[k]); draw() }; draw();
  }
};

/* ---------- التسبيح والسبحة ---------- */
const TDEF = [['subhanh', 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ', 100], ['subhan', 'سُبْحَانَ اللَّهِ', 33], ['hamd', 'الْحَمْدُ لِلَّهِ', 33], ['akbar', 'اللَّهُ أَكْبَرُ', 34], ['istighfar', 'أَسْتَغْفِرُ اللَّهَ الْعَظِيمَ', 100], ['tahlil', 'لَا إِلَهَ إِلَّا اللَّهُ', 100], ['salawat', 'اللَّهُمَّ صَلِّ عَلَى سَيِّدِنَا مُحَمَّدٍ وَعَلَى آلِهِ وَصَحْبِهِ وَسَلِّمْ', 100]];
const TS = () => { const t = store.get('tasbih', null) || { items: TDEF.map(x => ({ id: x[0], text: x[1], goal: x[2] })), cur: 'subhan', n: {}, total: {}, rounds: {}, day: {} }; return t };
const upT = (fn, quiet) => { const t = TS(); fn(t); store.set('tasbih', t, quiet) };
W.tas = { daySum(ids, date = TD()) { const d = TS().day[date] || {}; return ids === 'all' ? Object.values(d).reduce((a, b) => a + b, 0) : ids.reduce((a, k) => a + (d[k] || 0), 0) } };
const TNAME = x => x.text.replace(/[\u064B-\u065F\u0670]/g, '').replace(/ وبحمده$/, ' وبحمده');
W.pages.tasbih = {
  live: false,
  render(el) {
    const T = TS(), it = T.items.find(x => x.id === T.cur) || T.items[0], R = 289, vib = W.cfg.get('vibrate'), snd = W.cfg.get('tsound');
    const today = () => W.tas.daySum('all');
    el.innerHTML = `<div class="tpg"><div class="top"><button class="ib" data-back aria-label="رجوع">${ico('chevr')}</button><h1 style="text-align:start">التسبيح</h1><span class="tday" id="tday"></span></div>
    <div class="chips" id="tch">${T.items.map(x => `<button class="chip ${x.id === it.id ? 'on' : ''}" data-i="${x.id}">${esc(TNAME(x).slice(0, 22))}</button>`).join('')}<button class="chip o" id="tadd">+ ذكر مخصص</button></div>
    <div class="tdh" id="tdh">${esc(it.text)}</div>
    <div class="tarea nh" id="tarea"><div class="tz" id="tz"><svg class="rg" viewBox="0 0 100 100"><circle cx="50" cy="50" r="46" stroke="var(--surf2)" stroke-width="3.6"/><circle class="pr" id="tpr" cx="50" cy="50" r="46" stroke="var(--gold)" stroke-width="3.6" stroke-dasharray="${R}" stroke-dashoffset="${R}"/></svg><span class="ripple"></span><div class="in"><div class="n" id="tn">٠</div><div class="of" id="tof"></div></div></div><div class="tleft" id="tlf"></div></div>
    <div class="tacts"><button id="tg">${ico('flag')}الهدف</button><button id="tr">${ico('refresh')}إعادة العدّ</button></div>
    <div class="ttg"><div><span>الاهتزاز</span><button class="sw g2 ${vib ? 'on' : ''}" id="tv" aria-label="الاهتزاز"></button></div><div><span>الصوت</span><button class="sw g2 ${snd ? 'on' : ''}" id="ts" aria-label="الصوت"></button></div></div></div>`;
    const paint = (animate) => { const T2 = TS(), n = T2.n[it.id] || 0; $('#tn', el).textContent = num(n); $('#tof', el).textContent = `من ${num(it.goal)}`; $('#tlf', el).textContent = `المتبقي ${num(Math.max(0, it.goal - n))}`; $('#tpr', el).style.strokeDashoffset = R * (1 - n / it.goal); $('#tday', el).textContent = `اليوم · ${num(today())}`;
      if (animate) { const e = $('#tn', el); e.classList.remove('bump'); void e.offsetWidth; e.classList.add('bump') } };
    paint(false);
    const tap = () => { let done = false; upT(T => { const n = (T.n[it.id] || 0) + 1; T.total[it.id] = (T.total[it.id] || 0) + 1; T.day[TD()] ||= {}; T.day[TD()][it.id] = (T.day[TD()][it.id] || 0) + 1; if (n >= it.goal) { T.n[it.id] = 0; T.rounds[it.id] = (T.rounds[it.id] || 0) + 1; done = true } else T.n[it.id] = n }, true);
      const z = $('#tz', el); z.classList.remove('pulse'); void z.offsetWidth; z.classList.add('pulse');
      if (done) { $('#tn', el).textContent = num(it.goal); $('#tpr', el).style.strokeDashoffset = 0; W.hap.success(); if (W.cfg.get('tsound')) W.tick('done'); W.toast('أتممت الجولة، تقبّل الله منك'); store.set('tasbih', TS()); W.chal.check(); setTimeout(() => paint(true), 420) }
      else { const n = TS().n[it.id] || 0; (n % 33 === 0 || n % 10 === 0) ? W.hap.heavy() : W.hap.click(); if (W.cfg.get('tsound')) W.tick(); paint(true); if (n % 10 === 0) store.set('tasbih', TS()) }
      D.touch(); clearTimeout(W._tsv); W._tsv = setTimeout(() => { store.set('tasbih', TS()); W.chal.check() }, 1200) };
    /* العدّ لحظة اللمس (بدون تأخير) في كامل المنطقة الوسطى */
    const area = $('#tarea', el), z = $('#tz', el); let down = false;
    area.addEventListener('pointerdown', e => { if (e.pointerType === 'mouse' && e.button) return; down = true; z.classList.add('press'); tap() });
    ['pointerup', 'pointercancel', 'pointerleave'].forEach(t => area.addEventListener(t, () => { down = false; z.classList.remove('press') }));
    area.addEventListener('contextmenu', e => e.preventDefault());
    $$('[data-i]', el).forEach(b => b.onclick = () => { upT(T => { T.cur = b.dataset.i }); W.hap.select(); W.pages.tasbih.render(el) });
    $('#tadd', el).onclick = async () => { const r = await W.dialog({ title: 'إضافة ذكر مخصص', body: '<input id="dt" placeholder="نص الذكر" style="margin-bottom:10px"><input id="dg" type="number" value="33" inputmode="numeric">', ok: 'إضافة' }); if (!r) return; const t = $('#dt')?.value?.trim() || '', g = +$('#dg')?.value || 33; if (!t) return W.toast('اكتب شيئًا أولًا.'); const id = 'c' + Date.now(); upT(T => { T.items.push({ id, text: t, goal: g, custom: true }); T.cur = id }); W.pages.tasbih.render(el) };
    $$('[data-i]', el).forEach(b => { if (!TS().items.find(x => x.id === b.dataset.i)?.custom) return; let tm; const del = async () => { if (await W.dialog({ title: 'حذف الذكر المخصص؟', body: esc(b.textContent), ok: 'حذف', danger: true })) { upT(T => { T.items = T.items.filter(x => x.id !== b.dataset.i); if (T.cur === b.dataset.i) T.cur = T.items[0].id }); W.pages.tasbih.render(el) } }; b.addEventListener('contextmenu', e => { e.preventDefault(); del() }); b.addEventListener('pointerdown', () => { tm = setTimeout(del, 700) }); ['pointerup', 'pointerleave', 'pointercancel'].forEach(t => b.addEventListener(t, () => clearTimeout(tm))) });
    $('#tv', el).onclick = e => { const v = !W.cfg.get('vibrate'); W.cfg.set('vibrate', v); e.currentTarget.classList.toggle('on', v); if (v) W.hap.click(true) };
    $('#ts', el).onclick = e => { const v = !W.cfg.get('tsound'); W.cfg.set('tsound', v); e.currentTarget.classList.toggle('on', v); if (v) W.tick() };
    $('#tr', el).onclick = async () => { if (await W.dialog({ title: 'إعادة تعيين العداد؟', body: `سيُصفَّر عدّ «${esc(it.text.slice(0, 24))}»`, ok: 'إعادة', danger: true })) { upT(T => { T.n[it.id] = 0 }); W.hap.heavy(); paint(false) } };
    $('#tg', el).onclick = () => { const s = W.sheet(`<h3>الهدف (عدد التسبيحات في الجولة)</h3><div class="chips" style="flex-wrap:wrap">${[33, 99, 100, 313, 1000].map(g => `<button class="chip ${g === it.goal ? 'on' : ''}" data-g="${g}" style="min-width:60px">${num(g)}</button>`).join('')}</div><input id="gv" type="number" inputmode="numeric" value="${it.goal}" style="text-align:center;font-size:22px;margin:14px 0"><button class="btn" id="gs">حفظ</button>`);
      $$('[data-g]', s).forEach(b => b.onclick = () => { $('#gv', s).value = b.dataset.g; $$('[data-g]', s).forEach(x => x.classList.toggle('on', x === b)) }); $('#gs', s).onclick = () => { const v = Math.max(1, Math.min(100000, +$('#gv', s).value || 33)); upT(T => { T.items.find(x => x.id === it.id).goal = v; T.n[it.id] = Math.min(T.n[it.id] || 0, v - 1) }); W.closeSheet(); W.pages.tasbih.render(el) } };
  }
};
