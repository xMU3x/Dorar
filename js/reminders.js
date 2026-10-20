/* صفحة التذكيرات (على نمط التصميم المرجعي): بطاقة "التذكير القادم" + تذكيرات جاهزة + تذكيراتي + زر تذكير جديد */
const RIC = { sun: 'sun', sunset: 'sunset', moon: 'moon', book: 'book', check: 'check', bell: 'bell', spark: 'spark', water: 'water', hand: 'hand', fire: 'fire', clock: 'clock', flag: 'flag' };
const DAYL = [['س', 6], ['ح', 0], ['ن', 1], ['ث', 2], ['ر', 3], ['خ', 4], ['ج', 5]];
const timeHtml = it => { const t = W.notify.fmt(it.time); return `<span class="rt"><b class="tmv">${AR(t.t)}</b><small>${t.s}</small></span>` };
W.pages.reminders = {
  live: true,
  render(el) {
    const N = W.notify; N.check().then(() => { if (W.cur?.id === 'reminders' && !el._chk) { el._chk = 1; W.refresh() } });
    const nx = N.next(), list = N.list(), cust = N.custom(), on = N.count(), st = N.status, bad = st.perm !== 'granted' && st.perm !== 'unknown';
    const card = (it, i) => `<div class="rc ${it.on ? '' : 'off'}" data-id="${it.id}" role="button" style="--i:${i}"><span class="ric">${ico(RIC[it.icon] || 'bell')}</span><span class="g"><b>${esc(it.title)}</b><span class="sub">${N.daysLabel(it.days || [])}</span></span>${timeHtml(it)}<button class="sw ${it.on ? 'on' : ''}" data-t="${it.id}" aria-label="تفعيل ${esc(it.title)}"></button></div>`;
    el.innerHTML = `${W.top('التذكيرات')}
    <div class="rhero"><div class="rh-t"><span class="rh-ic bellr">${ico('bell')}</span><div class="g"><div class="rh-k">التذكير القادم</div><div class="rh-n">${nx ? esc(nx.it.title) : 'لا توجد تذكيرات مفعّلة'}</div><div class="rh-w">${nx ? N.when(nx.at) : 'فعّل تذكيرًا من القائمة'}</div></div></div>
      <div class="rh-b"><button class="pillb" id="rtest">${ico('send')}إشعار تجريبي</button><span class="pillb o">${ico('check')}<span data-count="${on}">${AR(on)}</span> مفعّل</span></div></div>
    ${bad ? `<div class="card warn"><b>الإشعارات غير مفعّلة</b><div class="sub" style="margin:4px 0 10px">اسمح بالإشعارات حتى تصلك التذكيرات في مواعيدها.</div><button class="btn" id="rperm">السماح بالإشعارات</button></div>` : st.exact === 'denied' ? `<div class="card warn"><b>التنبيه الدقيق غير مفعّل</b><div class="sub" style="margin:4px 0 10px">فعّل «المنبهات والتذكيرات» لتصل التذكيرات في موعدها بالضبط.</div><button class="btn" id="rex">فتح الإعداد</button></div>` : ''}
    <div class="secH"><i></i><div><b>الأذكار والعبادة</b><div class="sub">اضغط على التذكير لتعديل أيامه ووقته</div></div></div>
    <div class="rl">${list.map(card).join('')}</div>
    <div class="secH"><i></i><b>تذكيراتي</b></div>
    <div class="rl">${cust.length ? cust.map((c, i) => card(c, i)).join('') : `<button class="rempty" id="rnew0"><span class="ric big">${ico('alarmadd')}</span><b>أضف تذكيرك الخاص</b><span class="sub">صلاة الضحى، الاستغفار، قيام الليل… اختر ما يناسبك.</span></button>`}</div>
    <button class="fab" id="rnew">${ico('add')}<span>تذكير جديد</span></button><div style="height:70px"></div>`;
    W.countUp?.(el);
    $('#rtest', el).onclick = async () => { if (await N.test()) W.toast('أرسلنا إشعارًا تجريبيًا الآن'); };
    $('#rperm', el)?.addEventListener('click', async () => { await N.perm(); await N.schedule(); W.refresh() });
    $('#rex', el)?.addEventListener('click', async () => { await N.exact(true); N.schedule(); W.refresh() });
    const all = N.all();
    $$('.rc', el).forEach(c => c.onclick = async e => {
      const it = all.find(x => x.id === c.dataset.id), t = e.target.closest('[data-t]');
      if (t) { e.stopPropagation(); const v = !it.on; if (v && N.status.perm !== 'granted') { if (!(await N.perm())) W.toast('اسمح بالإشعارات من إعدادات النظام أولًا') } t.classList.toggle('on', v); c.classList.toggle('off', !v); W.hap.click(); N.update(it, { on: v }); setTimeout(() => W.refresh(), 220); return }
      editSheet(it);
    });
    const n0 = $('#rnew0', el); if (n0) n0.onclick = () => editSheet(null);
    $('#rnew', el).onclick = () => editSheet(null);
    const fab = $('#rnew', el); let ly = el.scrollTop; el.onscroll = () => { const y = el.scrollTop; fab.classList.toggle('mini', y > ly + 4 && y > 60); if (y < ly - 4) fab.classList.remove('mini'); ly = y };
  }
};
function editSheet(it) {
  const N = W.notify, isNew = !it, o = it || { title: '', body: '', icon: 'bell', time: '08:00', days: [0, 1, 2, 3, 4, 5, 6], on: true, custom: true };
  let days = [...(o.days || [])], icon = o.icon;
  const s = W.sheet(`<h3>${isNew ? 'تذكير جديد' : 'تعديل التذكير'}</h3>
    ${o.custom ? `<input id="et" placeholder="عنوان التذكير (مثال: صلاة الضحى)" maxlength="40" value="${esc(o.title)}" style="margin-bottom:10px"><input id="eb" placeholder="نص الإشعار (اختياري)" maxlength="90" value="${esc(o.body || '')}" style="margin-bottom:14px">
    <div class="chips icp" id="ei">${['bell', 'sun', 'moon', 'book', 'spark', 'water', 'hand', 'fire', 'flag'].map(k => `<button class="chip ic2 ${icon === k ? 'on' : ''}" data-i="${k}">${ico(k)}</button>`).join('')}</div>` : `<div class="sub" style="margin:-6px 0 12px">${esc(o.title)}</div>`}
    <label class="tbox"><span>الوقت</span><input id="etm" type="time" value="${o.time}"></label>
    <div class="sub" style="margin:14px 2px 8px">الأيام</div><div class="wdc" id="ed">${DAYL.map(([l, d]) => `<button class="dc ${days.includes(d) ? 'on' : ''}" data-d="${d}">${l}</button>`).join('')}</div>
    <div class="chips" style="margin:8px 0 0"><button class="chip" id="eall">كل يوم</button><button class="chip" id="emt">الاثنين والخميس</button><button class="chip" id="efr">الجمعة</button></div>
    <button class="btn" id="esv" style="margin-top:18px">حفظ</button>
    ${isNew ? '' : o.custom ? '<button class="btn d" id="edl" style="margin-top:10px">حذف التذكير</button>' : '<button class="btn o" id="erst" style="margin-top:10px">استعادة الإعدادات الافتراضية</button>'}`);
  const paint = () => $$('[data-d]', s).forEach(b => b.classList.toggle('on', days.includes(+b.dataset.d)));
  $$('[data-d]', s).forEach(b => b.onclick = () => { const d = +b.dataset.d; days = days.includes(d) ? days.filter(x => x !== d) : [...days, d]; W.hap.tick(); paint() });
  const set = a => () => { days = a; W.hap.select(); paint() };
  $('#eall', s).onclick = set([0, 1, 2, 3, 4, 5, 6]); $('#emt', s).onclick = set([1, 4]); $('#efr', s).onclick = set([5]);
  $$('[data-i]', s).forEach(b => b.onclick = () => { icon = b.dataset.i; $$('[data-i]', s).forEach(x => x.classList.toggle('on', x === b)); W.hap.tick() });
  $('#esv', s).onclick = async () => {
    const time = $('#etm', s).value || o.time; if (!days.length) return W.toast('اختر يومًا واحدًا على الأقل');
    if (o.custom) { const title = $('#et', s).value.trim(); if (!title) return W.toast('اكتب عنوان التذكير'); const p = { title, body: $('#eb', s).value.trim(), icon, time, days, on: true }; isNew ? N.addCustom(p) : N.update(it, p) }
    else N.update(it, { time, days, on: true });
    if (N.status.perm !== 'granted') await N.perm(); W.hap.success(); W.closeSheet(); W.toast(isNew ? 'تمت إضافة التذكير' : 'تم الحفظ'); W.refresh();
  };
  $('#edl', s)?.addEventListener('click', async () => { if (await W.dialog({ title: 'حذف التذكير؟', body: esc(o.title), ok: 'حذف', danger: true })) { N.remove(it.id); W.closeSheet(); W.refresh() } });
  $('#erst', s)?.addEventListener('click', () => { N.reset(it); W.closeSheet(); W.refresh() });
}
