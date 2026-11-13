import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../data/models.dart';
import 'pose.dart';
import 'squat_analyzer.dart';

enum TrackerPhase {
  /// Opening the camera.
  starting,

  /// The user declined camera access.
  permissionDenied,

  /// No usable camera (emulator, desktop, or a camera error).
  unavailable,

  /// Waiting for the setup checks to pass.
  setup,
  countdown,
  workout,

  /// Rep target reached.
  done,
}

const setupCheckLabels = [
  'Whole body in frame',
  'Clear, well-lit view',
  'Phone steady, standing still',
];

/// Builds a tracker for one set. Swappable so tests and devices without a
/// camera can use [SimulatedTracker].
typedef TrackerFactory = SquatTracker Function();

/// Common setup → countdown → workout lifecycle. Subclasses feed in setup
/// checks, live pose data and completed reps.
abstract class SquatTracker extends ChangeNotifier {
  SquatTracker({this.countdownStep = const Duration(milliseconds: 900)});

  static const _countFrom = 3;
  static const _issueTitles = {
    FormIssue.kneesIn: ('Knees caved in', 'Push knees out over your toes'),
    FormIssue.shallow: ('Too shallow', 'Hips should reach knee height'),
  };

  final Duration countdownStep;

  /// True for the scripted demo set.
  bool get simulated;

  /// Camera preview to show behind the overlay, if any.
  Widget? buildPreview() => null;

  TrackerPhase _phase = TrackerPhase.starting;
  TrackerPhase get phase => _phase;

  List<bool> _checks = const [false, false, false];
  List<bool> get checks => _checks;

  int _count = _countFrom;
  int get count => _count;

  final _repLog = <bool>[];
  List<bool> get repLog => List.unmodifiable(_repLog);
  int get reps => _repLog.length;

  final _errors = <FormError>[];
  List<FormError> get errors => List.unmodifiable(_errors);

  /// 0 standing → 1 full depth.
  double depth = 0;

  /// Issue in the rep happening right now.
  FormIssue? liveIssue;

  /// Latest detected body, for the overlay. Null in the demo.
  PoseSnapshot? pose;

  /// Whether a full body is currently detected (always true in the demo).
  bool bodyVisible = true;

  DateTime? _lastRepAt;

  /// Time since the last rep finished, for short praise cues.
  Duration? get sinceLastRep => _lastRepAt == null ? null : DateTime.now().difference(_lastRepAt!);

  final _clock = Stopwatch();
  Duration get elapsed => _clock.elapsed;

  bool _paused = false;
  bool get paused => _paused;

  Timer? _countdown;
  bool _disposed = false;

  int get formScore {
    final live = liveIssue != null ? 6 : 0;
    return reps == 0 ? 100 : (100 - _errors.length * 9 - live).clamp(0, 100);
  }

  /// Final score for the saved session (ignores the in-progress rep).
  int get finalScore => (100 - _errors.length * 9).clamp(0, 100);

  Future<void> start();

  void setPaused(bool v) {
    if (_phase != TrackerPhase.workout || _paused == v) return;
    _paused = v;
    v ? _clock.stop() : _clock.start();
    notifyListeners();
  }

  @protected
  void setPhase(TrackerPhase p) {
    if (_disposed) return;
    _phase = p;
    notifyListeners();
  }

  /// Report setup checks. Starts the countdown once all pass.
  @protected
  void reportChecks(List<bool> checks) {
    if (_phase != TrackerPhase.setup) return;
    _checks = checks;
    if (checks.every((c) => c)) _startCountdown();
    notifyListeners();
  }

  @protected
  void reportLive({
    required double depth,
    FormIssue? issue,
    PoseSnapshot? pose,
    bool bodyVisible = true,
  }) {
    if (_disposed) return;
    this.depth = depth;
    liveIssue = issue;
    this.pose = pose;
    this.bodyVisible = bodyVisible;
    notifyListeners();
  }

  @protected
  void reportRep(FormIssue? issue) {
    if (_phase != TrackerPhase.workout || _paused) return;
    final rep = _repLog.length + 1;
    _repLog.add(issue == null);
    _lastRepAt = DateTime.now();
    if (issue != null) {
      final (title, tip) = _issueTitles[issue]!;
      _errors.add(FormError(rep, title, tip));
      HapticFeedback.mediumImpact();
    }
    if (_repLog.length >= repTarget) {
      _clock.stop();
      _phase = TrackerPhase.done;
    }
    notifyListeners();
  }

  /// Stop early (End set). Moves to [TrackerPhase.done].
  void finish() {
    _countdown?.cancel();
    _clock.stop();
    setPhase(TrackerPhase.done);
  }

  void _startCountdown() {
    _phase = TrackerPhase.countdown;
    _count = _countFrom;
    _countdown = Timer.periodic(countdownStep, (t) {
      if (_count > 1) {
        _count--;
      } else {
        t.cancel();
        _phase = TrackerPhase.workout;
        _clock.start();
        onWorkoutStart();
      }
      if (!_disposed) notifyListeners();
    });
  }

  /// Hook for subclasses when counting begins.
  @protected
  void onWorkoutStart() {}

  @override
  void dispose() {
    _disposed = true;
    _countdown?.cancel();
    _clock.stop();
    super.dispose();
  }
}
