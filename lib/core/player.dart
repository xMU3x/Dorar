import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:path_provider/path_provider.dart';

class Track {
  /// [title] اسم السورة، [sub] اسم القارئ، [extra] الرواية (مثل «حفص عن عاصم - مرتل»).
  final String title, sub, url;
  final String? extra;
  final int? surah;
  /// محاضرة/موعظة (لا تُسبق بكلمة «سورة»).
  final bool lecture;
  Track(this.title, this.sub, this.url, {this.surah, this.extra, this.lecture = false});
  String get label => lecture ? title : 'سورة $title';
}

enum RepeatKind { off, one, all }

/// مشغّل القرآن الصوتي (mp3quran.net).
/// يعمل كخدمة أمامية (Foreground Service) عبر just_audio_background: يستمر بالتشغيل والشاشة مطفأة،
/// ويعرض إشعار تحكم (تشغيل/إيقاف/التالي/السابق/شريط التقدّم) في شريط الإشعارات وشاشة القفل.
/// الخدمة تعمل فقط أثناء التشغيل، فلا استهلاك للبطارية عند التوقف.
/// قائمة التشغيل مصدر واحد متسلسل (ConcatenatingAudioSource) فينتقل للسورة التالية تلقائيًا حتى مع الشاشة المقفلة.
class PlayerService extends ChangeNotifier {
  final AudioPlayer _a = AudioPlayer();
  List<Track> queue = [];
  int index = 0;
  String? error;
  bool loading = false;
  RepeatKind repeat = RepeatKind.off;
  DateTime? sleepAt;
  Timer? _sleep;
  Uri? _art;
  bool _triedHttp = false;
  String _queueSig = '';

  PlayerService() {
    _a.playerStateStream.listen((s) {
      loading = s.processingState == ProcessingState.loading || s.processingState == ProcessingState.buffering;
      if (s.processingState == ProcessingState.completed) _onDone();
      notifyListeners();
    });
    _a.currentIndexStream.listen((i) {
      if (i != null && i != index && i >= 0 && i < queue.length) {
        index = i;
        notifyListeners();
      }
    });
    _a.playbackEventStream.listen((_) {}, onError: (Object e, StackTrace st) => _onError(e));
  }

  Track? get cur => queue.isEmpty || index >= queue.length ? null : queue[index];
  bool get playing => _a.playing;
  Stream<Duration> get positionStream => _a.positionStream;
  Stream<Duration?> get durationStream => _a.durationStream;
  Stream<Duration> get bufferedStream => _a.bufferedPositionStream;
  Duration get position => _a.position;
  Duration? get duration => _a.duration;

  Future<Uri?> _artUri() async {
    if (_art != null) return _art;
    try {
      final dir = await getTemporaryDirectory();
      final f = File('${dir.path}/dorar_cover.png');
      if (!await f.exists()) {
        final b = await rootBundle.load('assets/brand/app_icon.png');
        await f.writeAsBytes(b.buffer.asUint8List(), flush: true);
      }
      return _art = Uri.file(f.path);
    } catch (_) {
      return null;
    }
  }

  Future<ConcatenatingAudioSource> _source(List<Track> q, bool https) async {
    final art = await _artUri();
    return ConcatenatingAudioSource(
      useLazyPreparation: true,
      children: [
        for (final t in q)
          AudioSource.uri(
            Uri.parse(https ? t.url.replaceFirst('http://', 'https://') : t.url),
            tag: MediaItem(
              id: t.url,
              title: t.label,
              artist: t.sub,
              album: t.extra ?? 'Dorar',
              artUri: art,
            ),
          ),
      ],
    );
  }

  String _sig(List<Track> q) => '${q.length}|${q.isEmpty ? '' : q.first.url}|${q.isEmpty ? '' : q.last.url}';

  Future<void> _onError(Object e) async {
    // بعض الخوادم لا تدعم https: نعيد المحاولة بالروابط الأصلية مرة واحدة من نفس الموضع
    if (_triedHttp || queue.isEmpty) {
      error = 'تعذّر تشغيل هذا الملف، تحقق من الإنترنت';
      loading = false;
      notifyListeners();
      return;
    }
    _triedHttp = true;
    final i = index, pos = _a.position;
    try {
      await _a.setAudioSource(await _source(queue, false), initialIndex: i, initialPosition: pos);
      unawaited(_a.play());
    } catch (_) {
      error = 'تعذّر تشغيل هذا الملف، تحقق من الإنترنت';
      loading = false;
      notifyListeners();
    }
  }

  Future<void> _onDone() async {
    // آخر عنصر في القائمة انتهى ولا تكرار: نعود لبداية السورة الأولى متوقفين
    await _a.pause();
    await _a.seek(Duration.zero, index: 0);
    index = 0;
    notifyListeners();
  }

  /// يشغّل [q] بدءًا من العنصر [i]. إن كانت نفس القائمة تعمل فقط ينتقل للعنصر.
  Future<void> play(List<Track> q, int i) async {
    error = null;
    final sig = _sig(q);
    if (sig == _queueSig && _a.audioSource != null) {
      index = i;
      notifyListeners();
      await _a.seek(Duration.zero, index: i);
      unawaited(_a.play());
      return;
    }
    queue = q;
    index = i;
    _queueSig = sig;
    _triedHttp = false;
    loading = true;
    notifyListeners();
    try {
      try {
        await _a.setAudioSource(await _source(q, true), initialIndex: i, initialPosition: Duration.zero);
      } catch (_) {
        _triedHttp = true;
        await _a.setAudioSource(await _source(q, false), initialIndex: i, initialPosition: Duration.zero);
      }
      await _a.setLoopMode(_loop());
      unawaited(_a.play());
    } catch (e) {
      error = 'تعذّر تشغيل هذا الملف، تحقق من الإنترنت';
      loading = false;
      notifyListeners();
    }
  }

  LoopMode _loop() => switch (repeat) { RepeatKind.off => LoopMode.off, RepeatKind.one => LoopMode.one, RepeatKind.all => LoopMode.all };

  Future<void> toggle() async {
    if (_a.playing) {
      await _a.pause();
    } else {
      if (_a.audioSource == null && cur != null) {
        _queueSig = '';
        await play(queue, index);
      } else {
        unawaited(_a.play());
      }
    }
    notifyListeners();
  }

  Future<void> next() async {
    if (index < queue.length - 1 || repeat == RepeatKind.all) {
      await _a.seekToNext();
      if (!_a.playing) unawaited(_a.play());
    }
  }

  Future<void> prev() async {
    if (_a.position > const Duration(seconds: 4) || (index == 0 && repeat != RepeatKind.all)) {
      await _a.seek(Duration.zero);
    } else {
      await _a.seekToPrevious();
    }
  }

  Future<void> jumpTo(int i) async {
    if (i < 0 || i >= queue.length) return;
    index = i;
    notifyListeners();
    await _a.seek(Duration.zero, index: i);
    if (!_a.playing) unawaited(_a.play());
  }

  Future<void> seek(Duration d) => _a.seek(d);

  Future<void> skip(int sec) async {
    var t = _a.position + Duration(seconds: sec);
    final d = _a.duration;
    if (t < Duration.zero) t = Duration.zero;
    if (d != null && t > d) t = d;
    await _a.seek(t);
  }

  void cycleRepeat() {
    repeat = RepeatKind.values[(repeat.index + 1) % 3];
    _a.setLoopMode(_loop());
    notifyListeners();
  }

  /// مؤقت النوم: يوقف التشغيل بعد [d] (null = إلغاء).
  void setSleep(Duration? d) {
    _sleep?.cancel();
    sleepAt = d == null ? null : DateTime.now().add(d);
    if (d != null) {
      _sleep = Timer(d, () {
        _a.pause();
        sleepAt = null;
        notifyListeners();
      });
    }
    notifyListeners();
  }

  Future<void> stop() async {
    _sleep?.cancel();
    sleepAt = null;
    _queueSig = '';
    await _a.stop();
    queue = [];
    index = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _sleep?.cancel();
    _a.dispose();
    super.dispose();
  }
}

final PlayerService player = PlayerService();
