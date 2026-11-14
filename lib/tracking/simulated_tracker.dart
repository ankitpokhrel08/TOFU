import 'dart:async';

import '../game/exercises.dart';
import 'tracker.dart';

/// Scripted demo workout for devices without a camera and for tests. In
/// each block, rep 4 shows the exercise's main issue and rep 9 its second.
class SimulatedTracker extends WorkoutTracker {
  SimulatedTracker(
    super.blocks, {
    super.limits,
    this.tick = const Duration(milliseconds: 300),
    this.demo = true,
  }) : super(countdownStep: tick * 3);

  final Duration tick;

  /// False only in tests, where the script stands in for a real camera.
  final bool demo;

  static const _ticksPerRep = 8;

  /// Movement through one rep, sampled per tick.
  static const _curve = [0.0, .35, .75, 1.0, 1.0, .7, .35, 0.0];

  Timer? _timer;
  int _setup = 0;
  int _ticks = 0;

  @override
  bool get simulated => demo;

  @override
  Future<void> start() async {
    setPhase(TrackerPhase.setup);
    _timer = Timer.periodic(tick, (_) => _step());
  }

  @override
  void onBlockStart() => _ticks = 0;

  FormIssue? _scripted(int rep) {
    final issues = block.exercise.issues;
    if (rep == 4) return issues.first;
    if (rep == 9) return issues.length > 1 ? issues[1] : issues.first;
    return null;
  }

  void _step() {
    switch (phase) {
      case TrackerPhase.setup:
        _setup++;
        reportChecks([for (var i = 0; i < 3; i++) _setup > i * 3 + 2]);
      case TrackerPhase.workout when !paused:
        _ticks++;
        final t = _ticks % _ticksPerRep;
        final rep = reps + 1;
        final issue = _scripted(rep);
        final p = block.exercise.timed ? t / _ticksPerRep : _curve[t] * (issue != null ? .55 : 1);
        reportLive(progress: p, issue: issue != null && t >= 3 && t <= 5 ? issue : null);
        if (t == 0) reportRep(issue);
      case TrackerPhase.done:
        _timer?.cancel();
      default:
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
