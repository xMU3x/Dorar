# وِرد — الإعداد

## 1) Supabase (مرة واحدة)
1. **SQL Editor** ← الصق محتوى `supabase/schema.sql` ← Run.
2. **Authentication → Providers → Google**: فعّله وضع Client ID/Secret من Google Cloud
   (OAuth client من نوع *Web*، و Authorized redirect URI = `https://mckhvbkzcanjtjqiqqyd.supabase.co/auth/v1/callback`).
3. **Authentication → URL Configuration**: أضف في *Redirect URLs*:
   - رابط موقعك (مثل `https://your-site.pages.dev/**`) و `http://localhost:8080/**` للتجربة
   - `com.werd.habittracker://auth` (لتطبيق الأندرويد)
4. المشروع والمفتاح العام (publishable) موجودان في `js/config.js` — غيّرهما لو تستخدم مشروعًا آخر.

## 2) التشغيل
- **ويب/PWA**: ارفع المجلد كما هو على Cloudflare Pages / Netlify / GitHub Pages (لا يوجد build).
  للتجربة محليًا: `npm run serve`.
- **أندرويد**: `npm install` ثم `npm run prepare:www` ثم `npx cap add android && node scripts/patch-android.js && npx cap sync android`
  أو ادفع للفرع `main` وسيبني GitHub Actions ملف APK تلقائيًا (`.github/workflows/android-build.yml`).

## 3) كيف تعمل المزامنة
- التطبيق يحفظ محليًا أولًا، وبعد تسجيل الدخول يرفع التغييرات تلقائيًا (بعد ~2.5 ثانية من آخر تغيير) ويسحب أحدثها عند الفتح/عودة الإنترنت.
- المفاتيح المتزامنة: `khatma, tasbih, azkar, quran, challenges, activity, settings, reminders, fast, more`.
- عند تعارض حقيقي بين جهازين يتم الدمج (أكبر عدّاد/اتحاد القوائم) بدل فقدان بيانات.
- كل صف محمي بـ RLS: المستخدم يرى بياناته فقط.
