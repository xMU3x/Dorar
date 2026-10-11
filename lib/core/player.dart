import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

class Track {
  final String title, sub, url;
  Track(this.title, this.sub, this.url);
}

/// مشغّل القرآن الصوتي (mp3quran.net) مع قائمة تشغيل بسيطة.
class PlayerService extends ChangeNotifier {
  final AudioPlayer _a = AudioPlayer();
  List<Track> queue = [];
  int index = 0;
  String? error;

  PlayerService() {
    _a.playerStateStream.listen((s) {
      if (s.processingState == ProcessingState.completed) next();
      notifyListeners();
    });
  }

  Track? get cur => queue.isEmpty ? null : queue[index];
  bool get playing => _a.playing;

  Future<void> play(List<Track> q, int i) async {
    queue = q;
    index = i;
    error = null;
    notifyListeners();
    try {
      await _a.setUrl(q[i].url);
      await _a.play();
    } catch (e) {
      error = 'تعذّر تشغيل هذا الملف';
      notifyListeners();
    }
  }

  Future<void> toggle() async => _a.playing ? _a.pause() : _a.play();
  Future<void> next() async {
    if (index < queue.length - 1) await play(queue, index + 1);
  }

  Future<void> prev() async {
    if (index > 0) await play(queue, index - 1);
  }

  Future<void> stop() async {
    await _a.stop();
    queue = [];
    notifyListeners();
  }

  @override
  void dispose() {
    _a.dispose();
    super.dispose();
  }
}

final PlayerService player = PlayerService();
