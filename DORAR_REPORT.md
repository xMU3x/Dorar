# تقرير Dorar 3.4.4

## ما تم
- إعادة التسمية: الاسم الظاهر/المشروع Dorar، `pubspec name: dorar` (واستيرادات الاختبارات)، applicationId/namespace `com.dorar.dorar`، Deep Link `com.dorar.dorar://auth`، حزمة Kotlin `com.dorar.dorar`، قنوات الإشعارات وأيقونة الإشعار `ic_stat_dorar`، `DorarApp`، `DorarNative`، `DORAR_CONFIG`.
- `tool/setup_android.sh` + `tool/patch_gradle.py` يثبّتان applicationId/namespace صراحةً ويفشلان لو لم يتطابقا.
- GitHub Actions: الناتج `dist/Dorar.apk` + تحقق من اسم الحزمة عبر `aapt` + اسم الـ artifact والـ release.
- التصميم: لوحة ألوان خضراء/كريمي/ذهبي، ترويسة بأفق مساجد (`lib/ui/skyline.dart`)، شريط تنقل بتسميات وكبسولة، شرائح مقسّمة، بطاقات أنعم، رئيسية بشبكة 2×2، أيقونة التطبيق من العنابي إلى الأخضر (PNG + أيقونات الويب).

## محفوظ عمدًا (لحماية البيانات)
- جدول Supabase `werd_sync` ومفاتيح التخزين `werd2:` (مخطط بيانات وليس هوية).
- ملاحظة: تغيير applicationId يجعل الأندرويد يعتبره تطبيقًا جديدًا؛ البيانات المحلية القديمة لا تنتقل (المتزامنة عبر Supabase تعود بعد تسجيل الدخول). مفتاح التوقيع لم يُمسّ.

## يدويًا (لم أستطع تنفيذه)
- Supabase → Authentication → URL Configuration → Redirect URLs: أضف `com.dorar.dorar://auth`.
- Google Cloud: لا تغيير لازم لأن redirect URI يبقى `https://mckhvbkzcanjtjqiqqyd.supabase.co/auth/v1/callback`؛ تأكد فقط أنه مسجّل.
- لا توجد في التطبيق شاشة «استعادة كلمة المرور»، فلم يكن هناك رابط لتحديثه.

## الاختبارات — لم تُنفَّذ
بيئة العمل تحجب تنزيل Flutter/Dart وAndroid SDK، فلم يُشغَّل `dart format` ولا `flutter analyze` ولا `flutter test` ولا البناء، ولا يوجد `Dorar.apk`. نُفِّذ فقط: `node --check` لملفات JS (سليمة)، وفحص توازن الأقواس لملفات Dart، وبحث نصي يؤكد غياب الأسماء القديمة. شغّل الـ workflow أو `bash tool/setup_android.sh && flutter build apk --release` وراجع أخطاء الترجمة المحتملة في الملفات المعدّلة (`home.dart`, `widgets.dart`, `app.dart`, `skyline.dart`).
