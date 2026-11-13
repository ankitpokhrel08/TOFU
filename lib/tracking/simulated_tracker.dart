import 'dart:async';

import 'squat_analyzer.dart';
import 'tracker.dart';

/// Scripted demo set for devices without a camera and for tests: 12 reps
/// with knees caving on rep 4 and a shallow rep 9.
class SimulatedTracker extends SquatTracker {
  SimulatedTracker({this.tick = const Duration(milliseconds: 300)})
    : super(countdownStep: tick * 3);

  final Duration tick;

  static const _ticksPerRep = 8;

  /// Squat depth through one rep, sampled per tick.
  static const _depthCurve = [0.0, .35, .75, 1.0, 1.0, .7, .35, 0.0];

  Timer? _timer;
  int _setup = 0;
  int _ticks = 0;

  @override
  bool get simulated => true;

  @override
  Future<void> start() async {
    setPhase(TrackerPhase.setup);
    _timer = Timer.periodic(tick, (_) => _step());
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
        final shallow = rep == 9;
        final d = _depthCurve[t] * (shallow ? .55 : 1);
        final issue = rep == 4 && d > .6
            ? FormIssue.kneesIn
            : shallow && t >= 3 && t <= 5
            ? FormIssue.shallow
            : null;
        reportLive(depth: d, issue: issue);
        if (t == 0) {
          reportRep(
            rep == 4
                ? FormIssue.kneesIn
                : shallow
                ? FormIssue.shallow
                : null,
          );
        }
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
