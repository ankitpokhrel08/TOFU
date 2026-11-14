import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../data/models.dart';
import '../game/exercises.dart';
import '../game/levels.dart';
import 'pose.dart';

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

  /// Between exercises: "next up" with a short countdown.
  transition,

  /// All blocks finished, or ended early.
  done,
}

const setupCheckLabels = [
  'Whole body in frame',
  'Clear, well-lit view',
  'Phone steady, standing still',
];

/// Builds a tracker for one workout. Swappable so tests and devices without
/// a camera can use the demo tracker.
typedef TrackerFactory = WorkoutTracker Function(List<Block> blocks, Set<Limitation> limits);

/// Common lifecycle for a workout of one or more [blocks]:
/// setup → countdown → block 1 → transition → block 2 … → done.
/// Subclasses feed in setup checks, live pose data and completed reps.
abstract class WorkoutTracker extends ChangeNotifier {
  WorkoutTracker(
    this.blocks, {
    this.limits = const {},
    this.countdownStep = const Duration(milliseconds: 900),
  }) : assert(blocks.isNotEmpty);

  static const _countFrom = 3;

  final List<Block> blocks;
  final Set<Limitation> limits;
  final Duration countdownStep;

  /// True for the scripted demo workout.
  bool get simulated;

  /// Camera preview to show behind the overlay, if any.
  Widget? buildPreview() => null;

  /// Upright preview size, when [buildPreview] returns a camera preview.
  Size? get previewSize => null;

  TrackerPhase _phase = TrackerPhase.starting;
  TrackerPhase get phase => _phase;

  List<bool> _checks = const [false, false, false];
  List<bool> get checks => _checks;

  int _count = _countFrom;
  int get count => _count;

  int _index = 0;
  int get blockIndex => _index;
  Block get block => blocks[_index];
  Block? get nextBlock => _index + 1 < blocks.length ? blocks[_index + 1] : null;

  late final List<List<bool>> _logs = [for (final _ in blocks) <bool>[]];
  late final List<List<FormError>> _errors = [for (final _ in blocks) <FormError>[]];

  /// Graded units done in the current block.
  List<bool> get repLog => List.unmodifiable(_logs[_index]);
  int get reps => _logs[_index].length;

  /// Seconds held in the current timed block (whole segments plus progress).
  double get heldSeconds => (reps + progress) * Exercise.holdSegment;

  /// 0–1 movement progress (depth, lift, hold segment).
  double progress = 0;

  /// Issue in the rep happening right now.
  FormIssue? liveIssue;

  /// Latest detected body, for the overlay. Null in the demo.
  PoseSnapshot? pose;

  /// Whether the body is visible, and in this exercise's position.
  bool bodyVisible = true;
  bool inPosition = true;

  DateTime? _lastRepAt;
  Duration? get sinceLastRep => _lastRepAt == null ? null : DateTime.now().difference(_lastRepAt!);

  final _clock = Stopwatch();

  /// Active training time (excludes setup, countdowns, transitions, pauses).
  Duration get elapsed => _clock.elapsed;

  bool _paused = false;
  bool get paused => _paused;

  Timer? _countdown;
  bool _disposed = false;

  /// Results so far, one per block that was started.
  List<BlockResult> get results => [
    for (var i = 0; i <= _index; i++)
      BlockResult(
        exercise: blocks[i].exercise,
        target: blocks[i].target,
        repLog: List.of(_logs[i]),
        errors: List.of(_errors[i]),
      ),
  ];

  /// Units done across all blocks.
  int get totalDone => _logs.fold(0, (s, l) => s + l.length);

  /// Live form across everything done so far, 0–100.
  int get formScore {
    final done = totalDone;
    if (done == 0) return 100;
    final clean = _logs.fold(0, (s, l) => s + l.where((r) => r).length);
    final live = liveIssue != null ? 5 : 0;
    return ((100 * clean / done).round() - live).clamp(0, 100);
  }

  Future<void> start();

  /// Called when a block's counting begins (reset analyzers here).
  @protected
  void onBlockStart() {}

  void setPaused(bool v) {
    if (_phase != TrackerPhase.workout || _paused == v) return;
    _paused = v;
    v ? _clock.stop() : _clock.start();
    notifyListeners();
  }

  @protected
  void setPhase(TrackerPhase p) {
    if (_disposed) return;
    if (p == TrackerPhase.setup && _phase != TrackerPhase.setup) _setupSince = DateTime.now();
    _phase = p;
    notifyListeners();
  }

  DateTime? _setupSince;

  /// How long setup has been waiting, for "can't see you" help.
  Duration get setupTime => _phase == TrackerPhase.setup && _setupSince != null
      ? DateTime.now().difference(_setupSince!)
      : Duration.zero;

  /// Report setup checks. Starts the countdown once all pass.
  @protected
  void reportChecks(List<bool> checks) {
    if (_phase != TrackerPhase.setup) return;
    _checks = checks;
    if (checks.every((c) => c)) _runCountdown(TrackerPhase.countdown);
    notifyListeners();
  }

  @protected
  void reportLive({
    required double progress,
    FormIssue? issue,
    PoseSnapshot? pose,
    bool bodyVisible = true,
    bool inPosition = true,
  }) {
    if (_disposed) return;
    this.progress = progress;
    liveIssue = issue;
    this.pose = pose;
    this.bodyVisible = bodyVisible;
    this.inPosition = inPosition;
    notifyListeners();
  }

  @protected
  void reportRep(FormIssue? issue) {
    if (_phase != TrackerPhase.workout || _paused) return;
    final log = _logs[_index];
    log.add(issue == null);
    _lastRepAt = DateTime.now();
    if (issue != null) {
      _errors[_index].add(FormError(log.length, issue));
      HapticFeedback.mediumImpact();
    }
    if (log.length >= block.units) {
      _clock.stop();
      liveIssue = null;
      progress = 0;
      if (nextBlock == null) {
        _phase = TrackerPhase.done;
      } else {
        HapticFeedback.heavyImpact();
        _runCountdown(TrackerPhase.transition);
      }
    }
    notifyListeners();
  }

  /// Stop early (End set).
  void finish() {
    _countdown?.cancel();
    _clock.stop();
    setPhase(TrackerPhase.done);
  }

  /// Countdown into the next block. Switching between facing the camera and
  /// side-on gets extra time to turn.
  void _runCountdown(TrackerPhase phase) {
    final turning =
        phase == TrackerPhase.transition && nextBlock!.exercise.view != block.exercise.view;
    _phase = phase;
    _count = phase == TrackerPhase.transition ? (turning ? 5 : 3) : _countFrom;
    _countdown?.cancel();
    _countdown = Timer.periodic(countdownStep, (t) {
      if (_count > 1) {
        _count--;
      } else {
        t.cancel();
        if (_phase == TrackerPhase.transition) _index++;
        _phase = TrackerPhase.workout;
        _clock.start();
        onBlockStart();
      }
      if (!_disposed) notifyListeners();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _countdown?.cancel();
    _clock.stop();
    super.dispose();
  }
}
