import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';

/// تخزين محلي أولًا بنفس صيغة تطبيق الويب: مفاتيح `werd2:<key>` بقيم JSON،
/// وطابع زمني لكل مفتاح مزامَن (`__meta`) لتتوافق المزامنة مع جدول werd_sync.
class Store extends ChangeNotifier {
  late SharedPreferences _p;
  Map<String, int> meta = {};
  final _ch = StreamController<String>.broadcast();
  Stream<String> get changes => _ch.stream;

  Future<void> init() async {
    _p = await SharedPreferences.getInstance();
    meta = readIntMap('__meta');
  }

  Map<String, int> readIntMap(String k) {
    final s = _p.getString('$kStorePrefix$k');
    if (s == null) return {};
    try {
      return (jsonDecode(s) as Map).map((a, b) => MapEntry(a as String, (b as num).toInt()));
    } catch (_) {
      return {};
    }
  }

  void writeIntMap(String k, Map<String, int> m) => _p.setString('$kStorePrefix$k', jsonEncode(m));

  bool has(String k) => _p.containsKey('$kStorePrefix$k');

  dynamic get(String k, [dynamic d]) {
    final v = _p.getString('$kStorePrefix$k');
    if (v == null) return d;
    try {
      return jsonDecode(v);
    } catch (_) {
      return d;
    }
  }

  final Map<String, (String, dynamic)> _dc = {};

  /// قراءة سريعة للقراءة فقط: تُخزَّن النتيجة المفكوكة في الذاكرة ولا تُنسخ.
  /// لا تعدّل القيمة المرجعة (استخدم getMap/upd للتعديل).
  dynamic peek(String k, [dynamic d]) {
    final raw = _p.getString('$kStorePrefix$k');
    if (raw == null) return d;
    final c = _dc[k];
    if (c != null && (identical(c.$1, raw) || c.$1 == raw)) return c.$2;
    try {
      final v = jsonDecode(raw);
      _dc[k] = (raw, v);
      return v;
    } catch (_) {
      return d;
    }
  }

  Map<String, dynamic> peekMap(String k, [Map<String, dynamic>? d]) {
    final v = peek(k);
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v);
    return d ?? const <String, dynamic>{};
  }

  Map<String, dynamic> getMap(String k, [Map<String, dynamic>? d]) {
    final v = get(k);
    if (v is Map) return Map<String, dynamic>.from(v);
    return d == null ? <String, dynamic>{} : Map<String, dynamic>.from(jsonDecode(jsonEncode(d)) as Map);
  }

  void set(String k, dynamic v, {bool quiet = false}) {
    _p.setString('$kStorePrefix$k', jsonEncode(v));
    if (kSyncKeys.contains(k)) {
      meta[k] = DateTime.now().millisecondsSinceEpoch;
      writeIntMap('__meta', meta);
    }
    if (!quiet) _emit(k);
  }

  /// تطبيق قيمة قادمة من السيرفر دون رفع الطابع المحلي فوق طابع السيرفر.
  void applyRemote(String k, dynamic v, int ts) {
    _p.setString('$kStorePrefix$k', jsonEncode(v));
    meta[k] = ts;
    writeIntMap('__meta', meta);
    _emit(k);
  }

  Map<String, dynamic> upd(String k, Map<String, dynamic> d, void Function(Map<String, dynamic>) fn, {bool quiet = false}) {
    final v = getMap(k, d);
    fn(v);
    set(k, v, quiet: quiet);
    return v;
  }

  void _emit(String k) {
    _ch.add(k);
    notifyListeners();
  }

  Future<void> clearAll() async {
    for (final k in _p.getKeys().where((x) => x.startsWith(kStorePrefix)).toList()) {
      await _p.remove(k);
    }
    meta = {};
    notifyListeners();
  }
}

final Store store = Store();

class Cfg {
  static const Map<String, dynamic> def = {
    'mode': 'auto', 'pal': 'green', 'zfs': 28, 'tsound': false,
    'arDigits': false, 'vibrate': true, 'hijriAdj': 0,
  };
  dynamic get(String k) {
    final s = store.peekMap('settings');
    return s.containsKey(k) ? s[k] : def[k];
  }

  void set(String k, dynamic v) {
    final s = store.getMap('settings');
    s[k] = v;
    store.set('settings', s);
  }
}

final Cfg cfg = Cfg();
