import 'dart:convert';

/// دمج آمن عند تعارض حقيقي بين جهازين: أكبر رقم، اتحاد المصفوفات، دمج الخرائط (مطابق لـ sync.js).
dynamic mergeValues(dynamic a, dynamic b) {
  if (a is num && b is num) return a > b ? a : b;
  if (a is List && b is List) {
    final seen = <String>{};
    final out = <dynamic>[];
    for (final x in [...a, ...b]) {
      final k = jsonEncode(x);
      if (seen.add(k)) out.add(x);
    }
    return out;
  }
  if (a is Map && b is Map) {
    final o = Map<String, dynamic>.from(a);
    b.forEach((k, v) {
      o[k as String] = o.containsKey(k) ? mergeValues(o[k], v) : v;
    });
    return o;
  }
  return a ?? b;
}
