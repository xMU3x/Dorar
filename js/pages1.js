/* الصفحات 1: الرئيسية، القرّاء (+ مشغّل الصوت) */
const HADITH = [
  ['إِنَّمَا الأَعْمَالُ بِالنِّيَّاتِ، وَإِنَّمَا لِكُلِّ امْرِئٍ مَا نَوَى', 'متفق عليه · البخاري ١ ومسلم ١٩٠٧'], ['مِنْ حُسْنِ إِسْلَامِ الْمَرْءِ تَرْكُهُ مَا لَا يَعْنِيهِ', 'الترمذي ٢٣١٧'],
  ['لَا يُؤْمِنُ أَحَدُكُمْ حَتَّى يُحِبَّ لِأَخِيهِ مَا يُحِبُّ لِنَفْسِهِ', 'متفق عليه · البخاري ١٣ ومسلم ٤٥'], ['مَنْ كَانَ يُؤْمِنُ بِاللَّهِ وَالْيَوْمِ الْآخِرِ فَلْيَقُلْ خَيْرًا أَوْ لِيَصْمُتْ', 'متفق عليه'],
  ['الدِّينُ النَّصِيحَةُ', 'مسلم ٥٥'], ['أَحَبُّ الْأَعْمَالِ إِلَى اللَّهِ أَدْوَمُهَا وَإِنْ قَلَّ', 'متفق عليه · البخاري ٦٤٦٤ ومسلم ٧٨٣'],
  ['كَلِمَتَانِ خَفِيفَتَانِ عَلَى اللِّسَانِ، ثَقِيلَتَانِ فِي الْمِيزَانِ، حَبِيبَتَانِ إِلَى الرَّحْمَنِ: سُبْحَانَ اللَّهِ وَبِحَمْدِهِ، سُبْحَانَ اللَّهِ الْعَظِيمِ', 'متفق عليه · البخاري ٦٤٠٦ ومسلم ٢٦٩٤'],
  ['تَبَسُّمُكَ فِي وَجْهِ أَخِيكَ لَكَ صَدَقَةٌ', 'الترمذي ١٩٥٦'], ['خَيْرُكُمْ مَنْ تَعَلَّمَ الْقُرْآنَ وَعَلَّمَهُ', 'البخاري ٥٠٢٧'], ['الطُّهُورُ شَطْرُ الْإِيمَانِ', 'مسلم ٢٢٣'],
  ['مَنْ سَلَكَ طَرِيقًا يَلْتَمِسُ فِيهِ عِلْمًا سَهَّلَ اللَّهُ لَهُ بِهِ طَرِيقًا إِلَى الْجَنَّةِ', 'مسلم ٢٦٩٩'], ['لَيْسَ الشَّدِيدُ بِالصُّرَعَةِ، إِنَّمَا الشَّدِيدُ الَّذِي يَمْلِكُ نَفْسَهُ عِنْدَ الْغَضَبِ', 'متفق عليه · البخاري ٦١١٤ ومسلم ٢٦٠٩']
];
const dayN = () => Math.floor((Date.now() - new Date(new Date().getFullYear(), 0, 0)) / 864e5);
const accBtn = () => `<button class="ib p" data-go="account" aria-label="حسابي">${W.sync.user ? `<b>${esc((W.sync.user.user_metadata?.full_name || W.sync.user.email || 'M')[0].toUpperCase())}</b>` : ico('user')}</button>`;

/* ---------- الرئيسية ---------- */
W.pages.home = {
  live: true,
  async render(el) {
    const kh = W.khatma.get(), pg = D.pagesToday(), st = D.streak(), h = HADITH[dayN() % HADITH.length], q = await D.quran(), ai = (dayN() * 37) % q.ayahs.length, ay = q.ayahs[ai];
    const ch = await W.chal.today(), nf = W.fast.next(), rn = W.notify.next(), now = new Date(), hj = D.hj(now);
    const nfWhen = nf ? (nf.in === 0 ? 'اليوم' : nf.in === 1 ? 'غدًا' : `بعد ${num(nf.in)} أيام`) : '';
    const qa = [['spark', 'التسبيح', 'tasbih'], ['trophy', 'التحديات', 'challenges'], ['flag', 'خطة الختمة', 'khatma'], ['water', 'الرقية', 'ruqya'], ['bell', 'التذكيرات', 'reminders'], ['cal', 'التقويم', 'fasting'], ['music', 'القرّاء', 'reciters'], ['grid', 'المزيد', 'more']];
    el.innerHTML = `<div class="top start"><div class="g" style="flex:1"><div class="sub">${esc(D.hijri())}</div><h1 style="font-size:21px">السلام عليكم 👋</h1></div><button class="ib" data-go="settings" aria-label="الإعدادات">${ico('tune')}</button>${accBtn()}</div>
    <button class="hero" data-go="fasting" style="margin-top:6px"><div class="row"><div class="g"><div class="row" style="gap:8px;font-weight:700">${ico('moon')}الصيام القادم</div><div class="sub" style="margin-top:4px">${ico('cal')} ${D.WDAYS[now.getDay()]} · ${AR(hj.d)} ${D.HMONTHS[hj.m - 1]} ${AR(hj.y)} هـ</div></div></div>
      <div class="row" style="margin:18px 0 6px"><div class="g" style="text-align:start"><div style="font-size:26px;font-weight:700;line-height:1.4">${nf ? esc(nf.tags.filter(t => t.kind !== 'eid')[0]?.t || 'يوم صيام') : 'لا توجد أيام قريبة'}</div><div class="sub" style="margin-top:2px">${nf ? `${nfWhen} · ${D.WDAYS[nf.date.getDay()]} ${AR(nf.h.d)} ${D.HMONTHS[nf.h.m - 1]}` : ''}</div></div>${nf ? `<div class="big" style="text-align:end">${num(nf.in)}<div class="sub" style="font-size:12px;font-weight:400">${nf.in === 0 ? 'اليوم' : 'يوم'}</div></div>` : ''}</div></button>
    <button class="card" data-go="reminders" style="margin-top:14px"><div class="row"><div class="ic">${ico('bell')}</div><div class="g"><b>التذكير القادم</b><div class="sub">${rn ? `${esc(rn.it.title)} · ${W.notify.when(rn.at)}` : 'لا توجد تذكيرات مفعّلة'}</div></div>${ico('chev', 'chev')}</div></button>
    <button class="card" data-go="khatma" style="margin-top:14px"><div class="row"><div class="ring">${W.ring(kh.read / 604, 72, 8, 'var(--pri)')}<div class="t">${Math.round(kh.read / 604 * 100)}%</div></div><div class="g"><div class="sub">ختمتي الحالية</div><div style="font-size:20px;font-weight:700">${kh.read} من 604 صفحة</div><div class="sub">ورد اليوم: ${pg}/${kh.goal} صفحة</div><div class="bar"><i style="width:${Math.min(100, pg / kh.goal * 100)}%"></i></div></div>${ico('chev', 'chev')}</div></button>
    <button class="card" data-go="challenges" style="margin-top:14px"><div class="row"><div class="ic">${ico('trophy')}</div><div class="g"><b>تحديات اليوم</b><div class="sub">${ch.done} من ${ch.total} · ${ico('fire')} ${num(st.cur)} يوم متواصل</div></div>${ico('chev', 'chev')}</div></button>
    <div class="hero" style="margin-top:14px"><div class="row" style="font-weight:700;margin-bottom:10px">${ico('spark')} حديث اليوم</div><p style="font-family:var(--a);font-size:22px;line-height:2">${esc(h[0])}</p><div class="sub" style="margin-top:8px">${esc(h[1])}</div></div>
    <div class="card" style="margin-top:14px"><div class="row" style="margin-bottom:8px"><b class="g">آية اليوم</b><button class="ib" id="hshare" style="width:40px;height:40px">${ico('share')}</button></div><p class="mushaf" style="font-size:24px;text-align:center">${esc(ay[2])} <span class="an">﴿${num(ay[1])}﴾</span></p><div class="sub" style="text-align:center">${esc(D.sName(q, ay[0]))} · الآية ${num(ay[1])}</div></div>
    <h2>الوصول السريع</h2><div class="grid3" style="grid-template-columns:repeat(4,1fr)">${qa.map(x => `<button class="card qa" data-go="${x[2]}" style="padding:14px 4px"><span class="ic">${ico(x[0])}</span>${x[1]}</button>`).join('')}</div>`;
    $('#hshare').onclick = e => { e.stopPropagation(); W.share(`﴿${ay[2]}﴾\n— ${D.sName(q, ay[0])}: ${ay[1]}`) };
  }
};

/* ---------- مشغّل الصوت (القرّاء) ---------- */
const AP = W.player = { a: new Audio(), cur: null, queue: [], i: 0 };
AP.a.preload = 'none';
AP.play = (item, queue = [item]) => { AP.cur = item; AP.queue = queue; AP.i = Math.max(0, queue.indexOf(item)); AP.a.src = item.url; AP.a.play().catch(() => W.toast('تعذّر تشغيل هذا الملف. جرّب سورة أخرى.')); renderBar(); try { navigator.mediaSession.metadata = new MediaMetadata({ title: item.title, artist: item.sub || 'وِرد', artwork: [{ src: 'icons/icon-512.png', sizes: '512x512', type: 'image/png' }] }); navigator.mediaSession.setActionHandler('nexttrack', AP.next); navigator.mediaSession.setActionHandler('previoustrack', AP.prev) } catch { } };
AP.toggle = () => AP.a.paused ? AP.a.play() : AP.a.pause(); AP.next = () => { if (AP.queue.length > 1 && AP.i < AP.queue.length - 1) AP.play(AP.queue[AP.i + 1], AP.queue) }; AP.prev = () => { if (AP.i > 0) AP.play(AP.queue[AP.i - 1], AP.queue) };
AP.a.onended = () => { AP.next(); renderBar() }; AP.a.onplay = AP.a.onpause = () => renderBar(); AP.a.onerror = () => W.toast('تعذّر تشغيل هذا الملف');
function renderBar() { const b = $('#pbar'); if (!AP.cur) { b.classList.remove('on'); return } b.classList.add('on'); b.innerHTML = `<div class="row" style="width:100%"><button class="ib p" id="pp" style="width:44px;height:44px">${ico(AP.a.paused ? 'play' : 'pause')}</button><div class="g" style="min-width:0"><b style="display:block;white-space:nowrap;overflow:hidden;text-overflow:ellipsis">${esc(AP.cur.title)}</b><span class="sub">${esc(AP.cur.sub || '')}</span></div>${AP.queue.length > 1 ? `<button class="ib" id="pn" style="width:40px;height:40px">${ico('prev')}</button><button class="ib" id="pv" style="width:40px;height:40px">${ico('next')}</button>` : ''}<button class="ib" id="px" style="width:40px;height:40px">${ico('close')}</button></div>`; $('#pp').onclick = AP.toggle; $('#px').onclick = () => { AP.a.pause(); AP.cur = null; renderBar() }; $('#pn') && ($('#pn').onclick = AP.next, $('#pv').onclick = AP.prev) }
const API = 'https://www.mp3quran.net/api/v3/';
const cached = async (k, url, ttl = 6048e5) => { try { const c = JSON.parse(localStorage.getItem('werd2:c_' + k) || 'null'); if (c && Date.now() - c.t < ttl) return c.d } catch { } try { const d = await (await fetch(url)).json(); localStorage.setItem('werd2:c_' + k, JSON.stringify({ t: Date.now(), d })); return d } catch { try { return JSON.parse(localStorage.getItem('werd2:c_' + k)).d } catch { return null } } };

/* ---------- القرّاء ---------- */
let RC = null;
W.pages.reciters = {
  async render(el) {
    el.innerHTML = `${W.top('القرآن صوتيًا', { back: false })}<div class="row"><input id="rq" placeholder="ابحث عن قارئ" style="flex:1"></div><div class="list" id="rl" style="margin-top:12px"><p class="tip">جارٍ التحميل…</p></div>`;
    const j = RC || await cached('reciters', API + 'reciters?language=ar'); RC = j; const rl = $('#rl', el);
    if (!j) return rl.innerHTML = '<p class="tip">تعذّر الاتصال. تأكد من الإنترنت ثم أعد المحاولة.</p>';
    const draw = q => { const b = D.bare(q || ''), L = j.reciters.filter(r => !b || D.bare(r.name).includes(b)).slice(0, 120); rl.innerHTML = L.map(r => `<button class="item" data-r="${r.id}"><span class="ic">${ico('music')}</span><span class="g"><b>${esc(r.name)}</b><span class="sub">${esc(r.moshaf[0]?.name || '')}${r.moshaf.length > 1 ? ' · +' + (r.moshaf.length - 1) : ''}</span></span>${ico('chev', 'chev')}</button>`).join('') || '<p class="tip">لا توجد نتائج</p>'; $$('[data-r]', rl).forEach(b => b.onclick = () => W.go('reciter/' + b.dataset.r)) };
    draw(); $('#rq', el).oninput = e => draw(e.target.value);
  }
};
W.pages.reciter = {
  async render(el, [id, mi]) {
    const j = RC || await cached('reciters', API + 'reciters?language=ar'), r = j?.reciters.find(x => x.id == id); if (!r) { el.innerHTML = W.top('القارئ') + '<p class="tip">تعذّر التحميل</p>'; return }
    const m = r.moshaf[+mi || 0], q = await D.quran(), list = m.surah_list.split(',').map(Number);
    const items = list.map(n => ({ n, title: D.sName(q, n), sub: r.name, url: m.server + pad(n).padStart(3, '0') + '.mp3' }));
    el.innerHTML = `${W.top(esc(r.name))}${r.moshaf.length > 1 ? `<div class="chips">${r.moshaf.map((x, i) => `<button class="chip ${i === (+mi || 0) ? 'on' : ''}" data-mi="${i}">${esc(x.name)}</button>`).join('')}</div>` : `<div class="sub" style="margin:0 4px 10px">${esc(m.name)}</div>`}<div class="list">${items.map(x => `<button class="item" data-n="${x.n}"><span class="ic" style="font-weight:700">${num(x.n)}</span><span class="g"><b>${esc(x.title)}</b></span>${ico('play', 'chev')}</button>`).join('')}</div><div style="height:70px"></div>`;
    $$('[data-n]', el).forEach(b => b.onclick = () => { const it = items.find(x => x.n == b.dataset.n); AP.play(it, items); D.touch() }); $$('[data-mi]', el).forEach(b => b.onclick = () => W.go(`reciter/${id}/${b.dataset.mi}`));
  }
};
