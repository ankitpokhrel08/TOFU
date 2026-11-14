import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Short sound effects (original, synthesized for TOFU).
enum Sfx {
  rep('rep', .5),
  tick('tick', .6),
  go('go', .8),
  blockDone('block_done', .8),
  levelUp('level_up', .9),
  tryAgain('try_again', .6);

  const Sfx(this.file, this.volume);
  final String file;
  final double volume;
}

/// Spoken coaching and sound effects, with rate limiting so feedback is
/// helpful rather than constant chatter.
///
/// - Lines with the same [key] repeat at most once per [cooldown].
/// - Normal lines need [minGap] since the last one; [urgent] lines (like
///   "next exercise") always play and replace what's being said.
class Coach {
  Coach({required this.speak, required this.playSound, DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  /// The app-wide coach. Tests swap in a silent or recording one.
  static Coach instance = Coach.device();

  /// Device text-to-speech and audio. Failures (e.g. no TTS engine) are
  /// ignored: coaching is a bonus, never a crash.
  factory Coach.device() {
    final tts = _Tts();
    final sfx = _SfxPlayer();
    return Coach(speak: tts.speak, playSound: sfx.play);
  }

  factory Coach.silent() => Coach(speak: (_) {}, playSound: (_) {});

  static const minGap = Duration(milliseconds: 3500);
  static const defaultCooldown = Duration(seconds: 8);

  /// Low-level output; use [say] and [play], which apply the settings
  /// and rate limits.
  final void Function(String text) speak;
  final void Function(Sfx sfx) playSound;
  final DateTime Function() _clock;

  bool voice = true;
  bool sounds = true;

  DateTime? _lastSpoke;
  final _lastByKey = <String, DateTime>{};

  /// Speak [text] if voice is on and the rate limits allow. Returns whether
  /// it was spoken.
  bool say(String text, {String? key, Duration cooldown = defaultCooldown, bool urgent = false}) {
    if (!voice) return false;
    final now = _clock();
    final k = key ?? text;
    final last = _lastByKey[k];
    if (last != null && now.difference(last) < cooldown) return false;
    if (!urgent && _lastSpoke != null && now.difference(_lastSpoke!) < minGap) return false;
    _lastSpoke = now;
    _lastByKey[k] = now;
    if (kDebugMode) debugPrint('Coach says: $text');
    speak(text);
    return true;
  }

  void play(Sfx sfx) {
    if (sounds) playSound(sfx);
  }

  /// Forget cooldowns, e.g. at the start of a new workout.
  void reset() {
    _lastSpoke = null;
    _lastByKey.clear();
  }
}

class _Tts {
  Future<FlutterTts?>? _init;

  Future<FlutterTts?> _ready() => _init ??= () async {
    try {
      final tts = FlutterTts();
      await tts.setSpeechRate(.5);
      await tts.setPitch(1.0);
      await tts.setVolume(1.0);
      // Newer lines replace older ones instead of queueing up.
      await tts.setQueueMode(0);
      return tts;
    } on Object catch (e) {
      debugPrint('Text-to-speech unavailable: $e');
      return null;
    }
  }();

  void speak(String text) => _ready().then((tts) async {
    try {
      await tts?.speak(text);
    } on Object catch (e) {
      debugPrint('Speaking failed: $e');
    }
  });
}

class _SfxPlayer {
  final _players = <Sfx, AudioPlayer>{};

  void play(Sfx sfx) => _playAsync(sfx);

  Future<void> _playAsync(Sfx sfx) async {
    try {
      final p = _players[sfx] ??= AudioPlayer()..setReleaseMode(ReleaseMode.stop);
      await p.stop();
      await p.play(
        AssetSource('sounds/${sfx.file}.wav'),
        volume: sfx.volume,
        mode: PlayerMode.lowLatency,
      );
    } on Object catch (e) {
      debugPrint('Sound failed: $e');
    }
  }
}
