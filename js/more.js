/* صفحة «المزيد» — كل شيء يُضاف لاحقًا يوضع هنا.
   ─ لإضافة صفحة جديدة: 1) اكتب الصفحة بـ  W.pages.<id> = { render(el){…} }  2) أضف عنصرًا في أي قسم أدناه (go = رقم الصفحة).
   ─ لإضافة قسم: أضف كائنًا جديدًا في W.more.categories.   ─ الترتيب = ترتيب المصفوفة.
   ─ يمكن أيضًا من داخل التطبيق: زر «ترتيب» أعلى الصفحة لإخفاء/إظهار وتحريك الأقسام والعناصر (يُحفظ ويُزامَن).
   ─ size: 'half' بطاقة نصف عرض  |  'full' صف بعرض كامل مع سهم. */
W.more = {
  categories: [
    { id: 'daily', title: 'العبادة اليومية', items: [
      { id: 'reminders', title: 'التذكيرات', sub: 'تنبيهات الأذكار', icon: 'bell', go: 'reminders' },
      { id: 'challenges', title: 'التحديات', sub: 'أهدافك وإنجازاتك', icon: 'trophy', go: 'challenges' },
      { id: 'tasbih', title: 'التسبيح', sub: 'سبحة إلكترونية', icon: 'spark', go: 'tasbih' },
      { id: 'khatma', title: 'خطة الختمة', sub: 'تابع وردك اليومي', icon: 'flag', go: 'khatma' }
    ] },
    { id: 'dua', title: 'القرآن والدعاء', items: [
      { id: 'ruqya', title: 'الرقية الشرعية', sub: 'آيات وأذكار', icon: 'water', go: 'ruqya' },
      { id: 'zfav', title: 'الأذكار المفضلة', sub: 'ما حفظته من الأذكار', icon: 'fav', go: 'zfav' }
    ] },
    { id: 'fast', title: 'الصيام والتقويم', items: [
      { id: 'cal', title: 'التقويم الهجري', sub: 'أيام الصيام والمواسم', icon: 'cal', go: 'fasting' },
      { id: 'fnext', title: 'إضافة يوم صيام', sub: 'أيام مخصّصة بتكرار', icon: 'add', go: 'fasting/add' }
    ] },
    { id: 'app', title: 'الحساب والتطبيق', items: [
      { id: 'account', title: 'حسابي والمزامنة', sub: 'احفظ تقدّمك على أي جهاز', icon: 'user', go: 'account', size: 'full' },
      { id: 'settings', title: 'الإعدادات', sub: 'المظهر والاهتزاز والتاريخ الهجري', icon: 'tune', go: 'settings', size: 'full' },
      { id: 'about', title: 'عن التطبيق', sub: 'المصادر والإصدار', icon: 'info', go: 'about', size: 'full' }
    ] }
  ],
  add(catId, item) { const c = this.categories.find(x => x.id === catId); c ? c.items.push(item) : this.categories.push({ id: catId, title: catId, items: [item] }) }
};
const MS = () => store.get('more', { hide: [], ord: {}, cats: [] });
const upM = fn => { const m = MS(); m.hide ||= []; m.ord ||= {}; m.cats ||= []; fn(m); store.set('more', m) };
const sortBy = (arr, order, key = x => x.id) => { if (!order?.length) return arr; const ix = id => { const i = order.indexOf(id); return i < 0 ? 999 : i }; return [...arr].sort((a, b) => ix(key(a)) - ix(key(b))) };
let mEdit = false;
W.pages.more = {
  live: true,
  render(el) {
    const M = MS(), cats = sortBy(W.more.categories, M.cats);
    el.innerHTML = `<div class="top start"><div class="g" style="flex:1"><h1 style="font-size:26px">المزيد</h1><div class="sub">كل أدواتك الإسلامية في مكان واحد</div></div><button class="ib ${mEdit ? 'p' : ''}" id="mec" aria-label="ترتيب">${ico(mEdit ? 'check' : 'sort')}</button></div>
    ${cats.map((c, ci) => { const items = sortBy(c.items, M.ord[c.id]).filter(x => mEdit || !M.hide.includes(x.id)); if (!items.length) return ''; const half = items.filter(x => x.size !== 'full'), full = items.filter(x => x.size === 'full');
      const card = (x, i) => `<div class="mc ${x.size === 'full' ? 'full' : ''} ${M.hide.includes(x.id) ? 'hid' : ''}" data-go="${mEdit ? '' : x.go}" style="--i:${ci * 2 + i}" role="button"><span class="mic">${ico(x.icon)}</span><span class="g"><b>${esc(x.title)}</b><span class="sub">${esc(x.sub || '')}</span></span>${mEdit ? `<span class="med"><button data-up="${c.id}:${x.id}" aria-label="أعلى">${ico('up')}</button><button data-dn="${c.id}:${x.id}" aria-label="أسفل">${ico('down')}</button><button data-hd="${x.id}" aria-label="إخفاء">${ico(M.hide.includes(x.id) ? 'eyeoff' : 'eye')}</button></span>` : x.size === 'full' ? ico('chev', 'chev') : ''}</div>`;
      return `<div class="mcat" style="--i:${ci}"><div class="secH"><i></i><b class="g">${esc(c.title)}</b>${mEdit ? `<span class="med"><button data-cu="${c.id}" aria-label="أعلى">${ico('up')}</button><button data-cd="${c.id}" aria-label="أسفل">${ico('down')}</button></span>` : ''}</div>${half.length ? `<div class="mg">${half.map(card).join('')}</div>` : ''}${full.length ? `<div class="mf">${full.map((x, i) => card(x, i + half.length)).join('')}</div>` : ''}</div>` }).join('')}
    ${mEdit ? '<button class="btn o" id="mrs" style="margin-top:16px">إعادة الترتيب الافتراضي</button>' : ''}<div style="height:12px"></div>`;
    $('#mec', el).onclick = () => { mEdit = !mEdit; W.hap.click(); W.pages.more.render(el) };
    $$('.mc', el).forEach(c => c.onclick = e => { if (e.target.closest('.med')) return; const g = c.dataset.go; if (g) W.go(g) });
    const mv = (arr, id, d) => { const i = arr.indexOf(id), j = i + d; if (i < 0 || j < 0 || j >= arr.length) return arr; [arr[i], arr[j]] = [arr[j], arr[i]]; return arr };
    const redraw = () => { W.hap.tick(); W.pages.more.render(el) };
    $$('[data-up],[data-dn]', el).forEach(b => b.onclick = () => { const [cid, id] = (b.dataset.up || b.dataset.dn).split(':'), d = b.dataset.up ? -1 : 1, cat = W.more.categories.find(x => x.id === cid); upM(m => { const cur = sortBy(cat.items, m.ord[cid]).map(x => x.id); m.ord[cid] = mv(cur, id, d) }); redraw() });
    $$('[data-cu],[data-cd]', el).forEach(b => b.onclick = () => { const id = b.dataset.cu || b.dataset.cd, d = b.dataset.cu ? -1 : 1; upM(m => { const cur = sortBy(W.more.categories, m.cats).map(x => x.id); m.cats = mv(cur, id, d) }); redraw() });
    $$('[data-hd]', el).forEach(b => b.onclick = () => { const id = b.dataset.hd; upM(m => { m.hide = m.hide.includes(id) ? m.hide.filter(x => x !== id) : [...m.hide, id] }); redraw() });
    $('#mrs', el)?.addEventListener('click', () => { upM(m => { m.hide = []; m.ord = {}; m.cats = [] }); redraw() });
  }
};
