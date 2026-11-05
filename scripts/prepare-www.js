// يجهّز مجلد www لتطبيق الأندرويد (Capacitor): ينسخ ملفات الويب كما هي
const fs = require('fs'), path = require('path'), ROOT = process.cwd(), OUT = path.join(ROOT, 'www');
fs.rmSync(OUT, { recursive: true, force: true }); fs.mkdirSync(OUT, { recursive: true });
for (const f of ['index.html', 'offline.html', 'manifest.json', 'service-worker.js', 'favicon.ico']) fs.copyFileSync(path.join(ROOT, f), path.join(OUT, f));
for (const d of ['css', 'js', 'data', 'fonts', 'brand', 'icons']) fs.cpSync(path.join(ROOT, d), path.join(OUT, d), { recursive: true });
console.log('www جاهز ✔');
