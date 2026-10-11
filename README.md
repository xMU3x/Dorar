# وِرد (Habittly) — تطبيق Flutter أصلي

تطبيق أندرويد أصلي (ليس WebView) للأذكار، التسبيح، خطة الختمة، التحديات، الصيام والتقويم الهجري، التذكيرات، القرّاء، الرقية — بواجهة عربية RTL وتنقّل سفلي (أيقونات فقط، وتظهر التسمية أسفل الأيقونة المختارة)، واهتزاز أصلي، وعرض كامل الشاشة.

## البيانات والمزامنة (بدون أي تغيير في Supabase)
- نفس مشروع Supabase وجدول `werd_sync (user_id, key, value jsonb, ts bigint)` ونفس المفاتيح:
  `khatma, tasbih, azkar, quran, challenges, activity, settings, reminders, fast, more`.
- نفس منطق `js/sync.js`: سحب ← دمج عند التعارض (أكبر رقم / اتحاد المصفوفات) ← رفع upsert. لا حذف ولا إعادة إنشاء.
- تسجيل الدخول: Google (PKCE) + بريد/كلمة مرور، حذف الحساب عبر `rpc('delete_my_account')`.
- رابط العودة: `com.werd.habittracker://auth` (مسجّل مسبقًا في Supabase).
- هوية التطبيق: `com.werd.habittracker` (نفس تطبيق Capacitor السابق).

## البناء
المجلد `android/` يُولَّد بأداة Flutter المثبّتة (لتوافق Gradle/AGP/Kotlin) ثم تُطبَّق إعدادات التطبيق:
```bash
bash tool/setup_android.sh
flutter pub get && dart run flutter_launcher_icons
flutter build apk --release --dart-define=SUPABASE_ANON_KEY=<publishable key>
```
في GitHub Actions (`.github/workflows/android-release.yml`) يعمل تلقائيًا عند الدفع إلى `main` أو يدويًا:
`pub get` ← `dart format` ← `analyze` ← `test` ← `build apk --release` ← توقيع ← رفع Artifact + Release ثابت `latest`.

## الأسرار (Settings → Secrets and variables → Actions)
| السر | مطلوب؟ | الغرض |
|---|---|---|
| `SUPABASE_ANON_KEY` | اختياري | المفتاح العام (publishable). إن غاب يُقرأ من `js/config.js` الموجود أصلًا. |
| `KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD` | موصى به | نفس أسرار workflow القديم. بدونها يُوقَّع APK بمفتاح مؤقت ولن يُحدّث فوق نسخة موقّعة بمفتاح آخر. |

`versionCode = 1000 + رقم التشغيل` ليتفوّق على أي إصدار سابق.

## ملفات الويب القديمة
بقيت كما هي (PWA في الجذر) ولا يمسّها بناء Flutter.
