/// إعدادات Supabase تُمرَّر وقت البناء عبر --dart-define (لا مفاتيح داخل الكود).
/// المفتاح المستخدم هو المفتاح العام (publishable/anon) المخصّص للعميل؛ الحماية الفعلية عبر RLS.
const String kSupabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://mckhvbkzcanjtjqiqqyd.supabase.co',
);
const String kSupabaseKey = String.fromEnvironment('SUPABASE_ANON_KEY');
const String kNativeRedirect = 'com.werd.habittracker://auth';
const String kStorePrefix = 'werd2:';
const List<String> kSyncKeys = [
  'khatma', 'tasbih', 'azkar', 'quran', 'challenges',
  'activity', 'settings', 'reminders', 'fast', 'more',
];
