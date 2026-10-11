import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

class Track {
  final String title, sub, url;
  final int? surah;
  Track(this.title, this.sub, this.url, {this.surah});
}

enum RepeatKind { off, one, all }

/// مشغّل القرآن الصوتي (mp3quran.net): قائمة تشغيل، تكرار، مؤقت نوم، تقديم/تأخير ١٥ ثانية.
class PlayerService extends ChangeNotifier {
  final AudioPlayer _a = AudioPlayer();
  List<Track> queue = [];
  int index = 0;
  String? error;
  bool loading = false;
  RepeatKind repeat = RepeatKind.off;
  DateTime? sleepAt;
  Timer? _sleep;

  PlayerService() {
    _a.playerStateStream.listen((s) {
      loading = s.processingState == ProcessingState.loading || s.processingState == ProcessingState.buffering;
      if (s.processingState == ProcessingState.completed) _onDone();
      notifyListeners();
    });
  }

  Track? get cur => queue.isEmpty ? null : queue[index];
  bool get playing => _a.playing;
  Stream<Duration> get positionStream => _a.positionStream;
  Stream<Duration?> get durationStream => _a.durationStream;
  Duration get position => _a.position;
  Duration? get duration => _a.duration;

  Future<void> _onDone() async {
    if (repeat == RepeatKind.one) {
      await _a.seek(Duration.zero);
      await _a.play();
    } else if (index < queue.length - 1) {
      await play(queue, index + 1);
    } else if (repeat == RepeatKind.all && queue.isNotEmpty) {
      await play(queue, 0);
    } else {
      await _a.pause();
      await _a.seek(Duration.zero);
    }
  }

  Future<void> play(List<Track> q, int i) async {
    queue = q;
    index = i;
    error = null;
    loading = true;
    notifyListeners();
    final url = q[i].url;
    try {
      // نجرّب https أولًا ثم الرابط الأصلي (بعض الخوادم http فقط)
      try {
        await _a.setUrl(url.replaceFirst('http://', 'https://'));
      } catch (_) {
        await _a.setUrl(url);
      }
      unawaited(_a.play());
    } catch (e) {
      error = 'تعذّر تشغيل هذا الملف، تحقق من الإنترنت';
      loading = false;
      notifyListeners();
    }
  }

  Future<void> toggle() async {
    if (_a.playing) {
      await _a.pause();
    } else {
      if (_a.processingState == ProcessingState.idle && cur != null) {
        await play(queue, index);
      } else {
        unawaited(_a.play());
      }
    }
    notifyListeners();
  }

  Future<void> next() async {
    if (index < queue.length - 1) {
      await play(queue, index + 1);
    } else if (repeat == RepeatKind.all && queue.isNotEmpty) {
      await play(queue, 0);
    }
  }

  Future<void> prev() async {
    if (_a.position > const Duration(seconds: 4) || index == 0) {
      await _a.seek(Duration.zero);
    } else {
      await play(queue, index - 1);
    }
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
    await _a.stop();
    queue = [];
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
