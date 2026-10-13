/* الصيام — التقويم الهجري: كل أيام الصيام + أيام مخصّصة يضيفها المستخدم
   المخزَّن في store 'fast' = { rules:{...}, custom:[...], done:{ 'YYYY-MM-DD':1 } } */
const FS = () => { const f = store.get('fast', {}); return { rules: { ...W.fast.RULE_DEF, ...(f.rules || {}) }, custom: f.custom || [], done: f.done || {} } };
const upF = fn => { const f = FS(); fn(f); store.set('fast', f) };
const GL = d => `${d.getDate()} ${D.GMONTHS[d.getMonth()]} ${d.getFullYear()}`;
const sameDay = (a, b) => dkey(a) === dkey(b);
const dayDiff = (a, b) => Math.round((noon(b) - noon(a)) / 864e5);

W.fast = {
  RULE_DEF: { mt: true, bid: true, ashura: true, arafah: true, dhul: true, shawwal: true },
  RULES: [['mt', 'الاثنين والخميس'], ['bid', 'الأيام البيض (١٣–١٥ من كل شهر)'], ['ashura', 'تاسوعاء وعاشوراء'], ['arafah', 'يوم عرفة'], ['dhul', 'التسع الأوائل من ذي الحجة'], ['shawwal', 'ست من شوّال']],
  KIND: { fard: 'صيام فرض', sunna: 'صيام مستحب', bid: 'الأيام البيض', eid: 'يُمنع صيامه', custom: 'أيامي' },
  /* كل ما يخص يومًا واحدًا */
  info(date) {
    const F = FS(), R = F.rules, h = D.hj(date), dw = noon(date).getDay(), tags = [], key = dkey(date), isDh = h.m === 12;
    const add = (k, kind, t, note) => tags.push({ k, kind, t, note });
    if (h.m === 9) add('ram', 'fard', 'يوم من رمضان', 'صيام واجب على كل مسلم بالغ قادر');
    if (h.m === 10 && h.d === 1) add('fitr', 'eid', 'عيد الفطر', 'يحرم صيام هذا اليوم');
    if (isDh && h.d === 10) add('adha', 'eid', 'عيد الأضحى', 'يحرم صيام هذا اليوم');
    if (isDh && h.d >= 11 && h.d <= 13) add('tashreeq', 'eid', 'أيام التشريق', 'نُهي عن صيامها إلا لمن لم يجد الهدي');
    if (R.ashura && h.m === 1 && (h.d === 9 || h.d === 10)) add('ashura', 'sunna', h.d === 10 ? 'يوم عاشوراء' : 'تاسوعاء', 'صيام عاشوراء يكفّر السنة الماضية، ويُستحب صيام يوم قبله');
    if (R.arafah && isDh && h.d === 9) add('arafah', 'sunna', 'يوم عرفة', 'يكفّر السنة الماضية والباقية لغير الحاج');
    if (R.dhul && isDh && h.d >= 1 && h.d <= 8) add('dhul', 'sunna', `من عشر ذي الحجة`, 'العمل الصالح فيها أحب إلى الله، ويُستحب الصيام');
    if (R.shawwal && h.m === 10 && h.d >= 2 && h.d <= 7) add('shawwal', 'sunna', 'من ست شوّال', 'من صام رمضان ثم أتبعه ستًّا من شوال كان كصيام الدهر');
    if (R.bid && h.m !== 9 && h.d >= 13 && h.d <= 15 && !(isDh && h.d === 13)) add('bid', 'bid', 'من الأيام البيض', 'صيام ثلاثة أيام من كل شهر: ١٣ و١٤ و١٥');
    const mt = !!R.mt && (dw === 1 || dw === 4) && !tags.some(t => t.kind === 'eid' || t.kind === 'fard');
    if (mt) add('mt', 'mt', dw === 1 ? 'صيام الاثنين' : 'صيام الخميس', 'تُعرض الأعمال يومي الاثنين والخميس');
    const custom = F.custom.filter(c => c.on !== false && (c.type === 'once' ? c.date === key : c.type === 'week' ? (c.wd || []).includes(dw) : c.type === 'month' ? +c.hd === h.d : c.type === 'year' ? (+c.hm === h.m && +c.hd === h.d) : false));
    custom.forEach(c => add('c' + c.id, 'custom', c.title || 'يوم صيام', 'يوم أضفته أنت'));
    const eid = tags.some(t => t.kind === 'eid'), fard = tags.some(t => t.kind === 'fard');
    const main = eid ? 'eid' : fard ? 'fard' : tags.find(t => t.kind === 'sunna') ? 'sunna' : tags.find(t => t.kind === 'bid') ? 'bid' : custom.length ? 'custom' : '';
    return { h, date, tags, main, mt, custom, eid, fast: !eid && tags.length > 0, done: !!F.done[key] };
  },
  isFastDay(date) { return this.info(date).fast },
  /* أقرب يوم صيام من اليوم (يشمل اليوم لو لم يُصَم بعد) */
  next(from = new Date(), n = 60) { for (let i = 0; i < n; i++) { const d = D.addDays(from, i), f = this.info(d); if (f.fast && !(i === 0 && f.done)) return { ...f, in: i } } return null },
  /* مواسم قادمة */
  seasons() {
    const today = noon(new Date()), h = D.hj(today), out = [];
    const S = [['ramadan', 'شهر رمضان', 9, 1, 0], ['last10', 'العشر الأواخر وليلة القدر', 9, 21, 0], ['fitr', 'عيد الفطر', 10, 1, 1], ['six', 'ست من شوّال', 10, 2, 0], ['dhul', 'عشر ذي الحجة', 12, 1, 10], ['arafah', 'يوم عرفة', 12, 9, 9], ['adha', 'عيد الأضحى', 12, 10, 10], ['ashura', 'تاسوعاء وعاشوراء', 1, 9, 10], ['shaban', 'شهر شعبان', 8, 1, 0]];
    [h.y, h.y + 1].forEach(y => S.forEach(([k, name, m, d1, d2]) => {
      const M = D.hmonth(y, m); if (!M.days.length) return; const e = d2 || M.len, st = M.days[d1 - 1], en = M.days[Math.min(e, M.len) - 1]; if (!st || !en || en < today) return;
      out.push({ k, name, st, en, d1, d2: Math.min(e, M.len), m, y });
    }));
    /* الأيام البيض القادمة */
    for (let i = 0; i < 2; i++) { const m0 = h.m + i, y = h.y + (m0 > 12 ? 1 : 0), m = ((m0 - 1) % 12) + 1; if (m === 9) continue; const M = D.hmonth(y, m), st = M.days[12], en = M.days[14]; if (st && en && en >= today) { out.push({ k: 'bid', name: 'الأيام البيض', st, en, d1: 13, d2: 15, m, y }); break } }
    return out.sort((a, b) => a.st - b.st).slice(0, 6);
  }
};

/* ---------- الصفحة ---------- */
let fv = null, fSel = null;
const MONTH_NOTES = { 1: 'المحرّم: أفضل الصيام بعد رمضان', 8: 'شعبان: كان النبي ﷺ يُكثر الصيام فيه', 9: 'رمضان: صيام الشهر كله فرض', 10: 'شوّال: يُستحب صيام ست أيام منه', 12: 'ذو الحجة: التسع الأوائل ويوم عرفة' };
W.pages.fasting = {
  live: true,
  after(el, args) { if (args[0] === 'add') { history.replaceState(null, '', '#/fasting'); if (W.cur) W.cur.key = 'fasting'; setTimeout(() => addSheet(), 250) } },
  render(el, a, p, refresh) {
    const now = new Date(), h0 = D.hj(now); if (!fv || (!refresh && !el._v)) fv = { y: h0.y, m: h0.m }; el._v = 1;
    const F = FS(), nx = W.fast.next(), seasons = W.fast.seasons(), adj = +W.cfg.get('hijriAdj') || 0;
    const yDone = Object.keys(F.done).filter(k => { const [y, m, d] = k.split('-').map(Number); return D.hj(new Date(y, m - 1, d)).y === h0.y }).length;
    const nxTxt = nx ? (nx.in === 0 ? 'اليوم' : nx.in === 1 ? 'غدًا' : `بعد ${AR(nx.in)} أيام`) : '';
    el.innerHTML = `${W.top('التقويم الهجري', { back: false, left: `<button class="ib" id="fr" aria-label="تخصيص">${ico('tune')}</button>` })}
    <div class="sub fsub">أيام الصيام والمواسم · ${esc(D.hijri(now))}</div>
    <div class="rhero fh"><div class="rh-t"><span class="rh-ic">${ico('moon')}</span><div class="g"><div class="rh-k">الصيام القادم</div><div class="rh-n">${nx ? esc(nx.tags.filter(t => t.kind !== 'eid').map(t => t.t)[0] || 'يوم صيام') : 'لا توجد أيام قريبة'}</div><div class="rh-w">${nx ? `${nxTxt} · ${D.WDAYS[nx.date.getDay()]} ${AR(nx.h.d)} ${D.HMONTHS[nx.h.m - 1]}` : ''}</div></div></div>
      <div class="rh-b"><button class="pillb" id="fadd">${ico('add')}يوم صيام</button><span class="pillb o">${ico('check')}صمتُ ${AR(yDone)} يوم هذا العام</span></div></div>
    <div class="card calc" id="cal"></div>
    <div class="secH"><i></i>المواسم القادمة</div>
    <div class="card seas" id="seas">${seasons.map((s, i) => { const df = dayDiff(now, s.st), on = df <= 0, rng = s.d1 === s.d2 ? `${AR(s.d1)}` : `${AR(s.d1)}–${AR(s.d2)}`; return `<div class="sr" style="--i:${i}"><span class="pl2 ${on ? 'on' : ''}">${on ? 'جارٍ الآن' : df === 1 ? 'غدًا' : `بعد ${AR(df)} يومًا`}</span><div class="g"><b>${esc(s.name)}</b><div class="sub">${rng} ${D.HMONTHS[s.m - 1]} ${AR(s.y)} هـ · ${s.st.getDate()} ${D.GMONTHS[s.st.getMonth()]}</div></div></div>` }).join('')}</div>
    <div class="card adjc"><div class="sub" style="margin-bottom:8px">تعديل التاريخ الهجري حسب رؤية الهلال في بلدك</div><label class="sel"><select id="fadj">${[[0, 'بلا تعديل (أم القرى)'], [-1, 'يوم أقل (−١)'], [1, 'يوم أكثر (+١)'], [-2, 'يومان أقل (−٢)'], [2, 'يومان أكثر (+٢)']].map(o => `<option value="${o[0]}" ${o[0] === adj ? 'selected' : ''}>${o[1]}</option>`).join('')}</select>${ico('chev', 'sc')}</label></div>`;
    W.countUp?.(el);
    const cal = $('#cal', el);
    const draw = dir => {
      const M = D.hmonth(fv.y, fv.m), off = (M.start.getDay() + 1) % 7, last = M.days[M.len - 1], g1 = M.start, g2 = last, today = dkey(now);
      const rng = g1.getMonth() === g2.getMonth() ? `${D.GMONTHS[g1.getMonth()]} ${g1.getFullYear()}` : `${D.GMONTHS[g1.getMonth()]} – ${D.GMONTHS[g2.getMonth()]} ${g2.getFullYear()}`;
      const cells = '<i class="cd e"></i>'.repeat(off) + M.days.map((g, i) => { const f = W.fast.info(g), k = dkey(g); return `<button class="cd ${f.main} ${k === today ? 'td' : ''} ${f.done ? 'dn' : ''} ${fSel === k ? 'sel' : ''}" data-d="${k}" style="--i:${i + off}"><b>${AR(i + 1)}</b><small>${g.getDate()}</small>${f.mt ? '<u class="dot"></u>' : ''}${f.custom.length ? '<u class="cs"></u>' : ''}${f.done ? `<span class="ck">${ico('check')}</span>` : ''}</button>` }).join('');
      const away = fv.y !== h0.y || fv.m !== h0.m;
      cal.innerHTML = `<div class="ch"><button class="ib" id="pv" aria-label="الشهر السابق">${ico('chevr')}</button><div class="g" style="text-align:center"><h3>${D.HMONTHS[fv.m - 1]} ${AR(fv.y)} هـ</h3><div class="sub">${rng}</div></div><button class="ib" id="nx" aria-label="الشهر التالي">${ico('chev')}</button></div>
      ${MONTH_NOTES[fv.m] ? `<div class="mnote">${MONTH_NOTES[fv.m]}</div>` : ''}
      <div class="cw">${['سبت', 'أحد', 'اثنين', 'ثلاثاء', 'أربعاء', 'خميس', 'جمعة'].map(x => `<span>${x}</span>`).join('')}</div>
      <div class="cg-w"><div class="cg ${dir ? 'sl' + dir : ''}">${cells}</div></div>
      <div class="lg"><span><i class="k fard"></i>فرض</span><span><i class="k sunna"></i>مستحب</span><span><i class="k bid"></i>أيام بيض</span><span><i class="k eid"></i>يُمنع الصيام</span><span><i class="k custom"></i>أيامي</span><span><u class="dot"></u>الاثنين والخميس</span></div>
      ${away ? '<button class="chip o" id="tdy" style="margin-top:10px">العودة إلى اليوم</button>' : ''}`;
      const go = d => { const m = fv.m + d; fv = { y: fv.y + (m > 12 ? 1 : m < 1 ? -1 : 0), m: ((m + 11) % 12) + 1 }; W.hap.select(); draw(d > 0 ? 'L' : 'R') };
      $('#pv', cal).onclick = () => go(-1); $('#nx', cal).onclick = () => go(1); $('#tdy', cal)?.addEventListener('click', () => { fv = { y: h0.y, m: h0.m }; W.hap.click(); draw(fv.m > 0 ? 'U' : '') });
      $$('.cd[data-d]', cal).forEach(b => b.onclick = () => { const [y, m, d] = b.dataset.d.split('-').map(Number); fSel = b.dataset.d; $$('.cd.sel', cal).forEach(x => x.classList.remove('sel')); b.classList.add('sel'); daySheet(new Date(y, m - 1, d, 12)) });
      let x0 = null; cal.ontouchstart = e => { x0 = e.touches[0].clientX }; cal.ontouchend = e => { if (x0 == null) return; const dx = e.changedTouches[0].clientX - x0; x0 = null; if (Math.abs(dx) > 70) go(dx < 0 ? 1 : -1) };
    };
    draw();
    el._draw = draw;
    $('#fadj', el).onchange = e => { W.cfg.set('hijriAdj', +e.target.value); D.hjClear(); W.hap.click(); W.notify.schedule(); W.refresh() };
    $('#fr', el).onclick = rulesSheet; $('#fadd', el).onclick = () => addSheet();
  }
};

function daySheet(date) {
  const f = W.fast.info(date), key = dkey(date), wd = D.WDAYS[date.getDay()];
  const tags = f.tags.length ? f.tags.map(t => `<div class="tg2 ${t.kind}"><i class="k ${t.kind === 'mt' ? 'sunna' : t.kind}"></i><div class="g"><b>${esc(t.t)}</b><div class="sub">${esc(t.note)}</div></div></div>`).join('') : '<p class="sub" style="padding:6px 2px 2px">لا يوجد صيام مستحب محدد لهذا اليوم، ويمكنك إضافته كيوم مخصّص.</p>';
  const s = W.sheet(`<h3>${wd} ${AR(f.h.d)} ${D.HMONTHS[f.h.m - 1]} ${AR(f.h.y)} هـ</h3><div class="sub" style="margin:-8px 0 12px">${GL(date)} م</div>${tags}
    ${f.eid ? '' : `<button class="btn ${f.done ? 'o' : ''}" id="dd" style="margin-top:14px">${ico('check')}${f.done ? 'تم تسجيل الصيام · إلغاء' : 'صمتُ هذا اليوم'}</button>`}
    <button class="btn o" id="da" style="margin-top:10px">${ico('add')}إضافة صيام مخصّص لهذا اليوم</button>`);
  $('#dd', s)?.addEventListener('click', () => { upF(F => { f.done ? delete F.done[key] : F.done[key] = 1 }); D.touch(); f.done ? W.hap.tick() : W.hap.success(); W.closeSheet(); W.toast(f.done ? 'تم إلغاء التسجيل' : 'تقبّل الله صيامك'); W.refresh() });
  $('#da', s).onclick = () => addSheet(key);
}

function rulesSheet() {
  const F = FS();
  const s = W.sheet(`<h3>تخصيص أيام الصيام</h3><div class="sub" style="margin:-8px 0 10px">اختر ما يظهر في التقويم. رمضان والأعياد تظهر دائمًا.</div><div class="list">${W.fast.RULES.map(([k, t]) => `<div class="item"><span class="g"><b>${t}</b></span><button class="sw ${F.rules[k] ? 'on' : ''}" data-r="${k}" aria-label="${t}"></button></div>`).join('')}</div>
    <h3 style="margin-top:18px">أيامي المخصّصة</h3><div class="list" id="cl">${F.custom.length ? F.custom.map(c => `<div class="item"><span class="g"><b>${esc(c.title || 'يوم صيام')}</b><span class="sub">${customDesc(c)}</span></span><button class="ib" data-del="${c.id}" aria-label="حذف" style="color:#A8332B">${ico('del')}</button></div>`).join('') : '<p class="sub" style="padding:4px 2px">لم تضف أي يوم بعد.</p>'}</div><button class="btn" id="ca" style="margin-top:12px">${ico('add')}يوم صيام</button>`);
  $$('[data-r]', s).forEach(b => b.onclick = () => { const k = b.dataset.r, v = !FS().rules[k]; upF(f => { f.rules[k] = v }); b.classList.toggle('on', v); W.hap.click(); W.notify.schedule(); W.refresh() });
  $$('[data-del]', s).forEach(b => b.onclick = async () => { if (await W.dialog({ title: 'حذف اليوم المخصّص؟', ok: 'حذف', danger: true })) { upF(f => { f.custom = f.custom.filter(c => c.id !== b.dataset.del) }); W.closeSheet(); W.notify.schedule(); W.refresh() } });
  $('#ca', s).onclick = () => addSheet();
}
const customDesc = c => c.type === 'once' ? `مرة واحدة · ${c.date}` : c.type === 'week' ? 'كل أسبوع · ' + (c.wd || []).map(d => D.WDAYS[d]).join('، ') : c.type === 'month' ? `يوم ${AR(c.hd)} من كل شهر هجري` : `${AR(c.hd)} ${D.HMONTHS[c.hm - 1]} من كل عام`;

function addSheet(date) {
  const h = D.hj(date ? new Date(date + 'T12:00:00') : new Date());
  let type = date ? 'once' : 'week', wd = [1, 4];
  const s = W.sheet(`<h3>إضافة يوم صيام</h3><input id="ft" placeholder="الاسم (مثال: صيام نذر، يوم من أيام داود)" maxlength="40" style="margin-bottom:12px">
    <div class="chips" id="ty">${[['once', 'مرة واحدة'], ['week', 'كل أسبوع'], ['month', 'كل شهر هجري'], ['year', 'كل عام هجري']].map(t => `<button class="chip ${type === t[0] ? 'on' : ''}" data-t="${t[0]}">${t[1]}</button>`).join('')}</div>
    <div id="fb" style="margin:12px 0"></div><button class="btn" id="fs">حفظ</button>`);
  const body = () => {
    const b = $('#fb', s);
    if (type === 'once') b.innerHTML = `<input id="fd" type="date" value="${date || dkey(new Date())}">`;
    else if (type === 'week') b.innerHTML = `<div class="wdc">${[6, 0, 1, 2, 3, 4, 5].map(d => `<button class="dc ${wd.includes(d) ? 'on' : ''}" data-w="${d}">${['أحد', 'اثنين', 'ثلاث', 'أربع', 'خميس', 'جمعة', 'سبت'][d]}</button>`).join('')}</div>`;
    else if (type === 'month') b.innerHTML = `<div class="row"><span class="g">اليوم من الشهر الهجري</span><input id="fh" type="number" min="1" max="30" value="${h.d}" style="width:90px;text-align:center"></div>`;
    else b.innerHTML = `<div class="row"><label class="sel g"><select id="fm">${D.HMONTHS.map((m, i) => `<option value="${i + 1}" ${i + 1 === h.m ? 'selected' : ''}>${m}</option>`).join('')}</select>${ico('chev', 'sc')}</label><input id="fh" type="number" min="1" max="30" value="${h.d}" style="width:90px;text-align:center"></div>`;
    $$('[data-w]', b).forEach(x => x.onclick = () => { const d = +x.dataset.w; wd = wd.includes(d) ? wd.filter(z => z !== d) : [...wd, d]; x.classList.toggle('on'); W.hap.tick() });
  };
  body();
  $$('[data-t]', s).forEach(x => x.onclick = () => { type = x.dataset.t; $$('[data-t]', s).forEach(z => z.classList.toggle('on', z === x)); W.hap.select(); body() });
  $('#fs', s).onclick = () => {
    const c = { id: 'c' + Date.now(), title: $('#ft', s).value.trim(), type, on: true };
    if (type === 'once') { c.date = $('#fd', s).value; if (!c.date) return W.toast('اختر التاريخ') }
    else if (type === 'week') { if (!wd.length) return W.toast('اختر يومًا واحدًا على الأقل'); c.wd = wd }
    else { c.hd = Math.max(1, Math.min(30, +$('#fh', s).value || 1)); if (type === 'year') c.hm = +$('#fm', s).value }
    upF(f => { f.custom.push(c) }); W.hap.success(); W.closeSheet(); W.toast('تمت إضافة يوم الصيام'); W.notify.schedule(); W.refresh();
  };
}
