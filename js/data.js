/* بيانات + مواقيت الصلاة */
const D = W.D = { _c: {} };
D.load = async n => D._c[n] ||= fetch(`data/${n}.json`).then(r => { if (!r.ok) throw new Error(n); return r.json() });
/* quran: ayahs = [surah, ayah, text, juz, page, hizbQuarter, sajda]; surahs = [n, name, meccan, count] */
D.quran = async () => { const q = await D.load('quran'); if (!q._idx) { q._idx = {}; q.ayahs.forEach((a, i) => { (q._idx[a[4]] ||= []).push(i) }); q._first = {}; q.ayahs.forEach((a, i) => { if (a[1] === 1) q._first[a[0]] = i }) } return q };
D.sName = (q, n) => q.surahs[n - 1][1].replace(/^سُورَةُ\s*/, '');
D.bare = s => s.replace(/[\u064B-\u065F\u0670\u06D6-\u06ED\u0640]/g, '').replace(/[آأإٱ]/g, 'ا').replace(/ى/g, 'ي').replace(/ة/g, 'ه');
D.JUZ_START_PAGE = [1, 22, 42, 62, 82, 102, 121, 142, 162, 182, 201, 222, 242, 262, 282, 302, 322, 342, 362, 382, 402, 422, 442, 462, 482, 502, 522, 542, 562, 582];
D.juzOfPage = p => { let j = 1; D.JUZ_START_PAGE.forEach((s, i) => { if (p >= s) j = i + 1 }); return j };

/* ---------- التقويم الهجري (أم القرى عبر Intl + تعديل الرؤية) ---------- */
const HFMT = new Intl.DateTimeFormat('en-u-ca-islamic-umalqura-nu-latn', { day: 'numeric', month: 'numeric', year: 'numeric' });
const hjCache = {};
const noon = d => new Date(d.getFullYear(), d.getMonth(), d.getDate(), 12);
D.addDays = (d, n) => { const x = noon(d); x.setDate(x.getDate() + n); return x };
/* {y,m,d} هجري لتاريخ ميلادي (مع تصحيح الرؤية من الإعدادات) */
D.hj = (date = new Date()) => {
  const adj = +W.cfg.get('hijriAdj') || 0, g = D.addDays(date, adj), k = dkey(g);
  if (hjCache[k]) return hjCache[k];
  const o = {}; HFMT.formatToParts(g).forEach(p => { if (p.type === 'day' || p.type === 'month' || p.type === 'year') o[p.type[0]] = +p.value });
  return hjCache[k + ''] = { y: o.y, m: o.m, d: o.d };
};
D.hjClear = () => { Object.keys(hjCache).forEach(k => delete hjCache[k]); mCache = {} };
D.HMONTHS = ['محرّم', 'صفر', 'ربيع الأول', 'ربيع الآخر', 'جمادى الأولى', 'جمادى الآخرة', 'رجب', 'شعبان', 'رمضان', 'شوّال', 'ذو القعدة', 'ذو الحجة'];
D.GMONTHS = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
D.WDAYS = ['الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];
const hidx = h => h.y * 12 + h.m - 1;
let mCache = {};
/* بيانات شهر هجري: {y,m,start:Date,len,days:[Date]} */
D.hmonth = (y, m) => {
  const key = y + '-' + m; if (mCache[key]) return mCache[key];
  const t = y * 12 + m - 1, today = new Date(), h0 = D.hj(today);
  let g = D.addDays(today, Math.round((t - hidx(h0)) * 29.530588) - (h0.d - 1));
  for (let i = 0; i < 80; i++) { const h = D.hj(g), x = hidx(h); if (x > t) g = D.addDays(g, -Math.max(1, Math.min(25, (x - t) * 28))); else if (x < t) g = D.addDays(g, Math.max(1, Math.min(25, (t - x) * 28))); else if (h.d > 1) g = D.addDays(g, -(h.d - 1)); else break }
  const days = []; let x = g; while (hidx(D.hj(x)) === t && days.length < 31) { days.push(x); x = D.addDays(x, 1) }
  return mCache[key] = { y, m, start: g, len: days.length, days };
};
D.hijri = (date = new Date()) => { try { const h = D.hj(date), ar = W.cfg.get('arDigits'); return `${ar ? AR(h.d) : h.d} ${D.HMONTHS[h.m - 1]} ${ar ? AR(h.y) : h.y} هـ` } catch { return '' } };
D.fmtT = (h, mi) => ({ t: `${h % 12 || 12}:${pad(mi)}`, s: h >= 12 ? 'م' : 'ص' });

/* ---------- activity / streak / points ---------- */
D.touch = () => store.upd('activity', { days: {} }, a => { a.days[TD()] = (a.days[TD()] || 0) + 1 });
D.streak = () => { const a = store.get('activity', { days: {} }).days; let d = new Date(), n = 0; if (!a[dkey(d)]) d.setDate(d.getDate() - 1); while (a[dkey(d)]) { n++; d.setDate(d.getDate() - 1) } const best = Math.max(n, store.get('activity', {}).best || 0); return { cur: n, best } };
D.pagesToday = () => (store.get('quran', {}).pagesRead || {})[TD()] || 0;
D.addPages = n => { store.upd('quran', {}, q => { q.pagesRead ||= {}; q.pagesRead[TD()] = Math.max(0, (q.pagesRead[TD()] || 0) + n) }); D.touch() };
