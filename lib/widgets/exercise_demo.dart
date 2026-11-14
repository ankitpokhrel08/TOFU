import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../game/exercises.dart';

/// Which part of a Lottie clip to loop.
class _Clip {
  const _Clip(this.file, {this.end = 1, this.pingPong = false, this.speed = 1});

  final String file;

  /// Loop from the start of the clip to this fraction of it.
  final double end;

  /// Play forward then backward (for segments cut out of a longer clip).
  final bool pingPong;

  /// Playback speed; below 1 is slower.
  final double speed;

  String get asset => 'assets/exercises/$file.json';
}

const _clips = {
  // The source is a jumping squat; frames before take-off are a clean
  // bodyweight squat, played down and back up.
  Exercise.squat: _Clip('squat', end: .28, pingPong: true, speed: .7),
  Exercise.pushUp: _Clip('push_up'),
  Exercise.plank: _Clip('plank'),
  Exercise.reverseLunge: _Clip('reverse_lunge'),
  Exercise.gluteBridge: _Clip('glute_bridge'),
  Exercise.jumpingJack: _Clip('jumping_jack', speed: .8),
};

/// Looping animation showing how to do [exercise].
///
/// With reduced motion turned on, shows a single still frame instead.
class ExerciseDemo extends StatefulWidget {
  const ExerciseDemo({super.key, required this.exercise, this.height = 160});

  final Exercise exercise;
  final double height;

  @override
  State<ExerciseDemo> createState() => _ExerciseDemoState();
}

class _ExerciseDemoState extends State<ExerciseDemo> with TickerProviderStateMixin {
  late _Clip _clip = _clips[widget.exercise]!;
  late AnimationController _controller = _makeController();
  Duration? _length;

  AnimationController _makeController() => AnimationController(vsync: this, upperBound: _clip.end);

  @override
  void didUpdateWidget(ExerciseDemo old) {
    super.didUpdateWidget(old);
    if (old.exercise != widget.exercise) {
      _controller.dispose();
      _clip = _clips[widget.exercise]!;
      _controller = _makeController();
      _length = null;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  void _onLoaded(LottieComposition composition) {
    _length = composition.duration;
    _sync();
  }

  /// Start, or stop on a still frame for reduced motion.
  void _sync() {
    final length = _length;
    if (length == null) return;
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (still) {
      _controller
        ..stop()
        ..value = 0;
      return;
    }
    final span = _clip.end.clamp(.01, 1.0);
    _controller.duration = length * (span / _clip.speed);
    if (!_controller.isAnimating) _controller.repeat(reverse: _clip.pingPong);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'Animation showing how to do ${widget.exercise.label.toLowerCase()}',
      child: SizedBox(
        height: widget.height,
        child: Lottie.asset(
          _clip.asset,
          key: ValueKey(widget.exercise),
          controller: _controller,
          onLoaded: _onLoaded,
          fit: BoxFit.contain,
          // Lottie's own frame interpolation keeps slowed segments smooth.
          frameRate: FrameRate.max,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}
