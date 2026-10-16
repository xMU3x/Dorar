/// إعدادات Supabase تُمرَّر وقت البناء عبر --dart-define (لا مفاتيح سرية داخل الكود).
const String kSupabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://advzmtczixsjryvkfgiu.supabase.co',
);
const String kSupabaseKey = String.fromEnvironment('SUPABASE_ANON_KEY');
const String kNativeRedirect = 'com.dorar.dorar://auth';
const String kStorePrefix = 'werd2:';
const List<String> kSyncKeys = [
  'khatma', 'tasbih', 'azkar', 'quran', 'challenges',
  'activity', 'settings', 'reminders', 'fast', 'more',
];
