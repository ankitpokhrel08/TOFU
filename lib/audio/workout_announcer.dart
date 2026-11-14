import '../game/exercises.dart';
import '../game/levels.dart';
import '../tracking/tracker.dart';
import 'coach.dart';

/// Turns workout events into spoken coaching and sounds.
///
/// Speaks only at meaningful moments: each new exercise, a form problem
/// (each kind at most every 8 seconds), "3 more" near the end, and help
/// when the camera can't find the user. Rep and countdown feedback are
/// sounds, not speech, so the voice stays sparse.
class WorkoutAnnouncer {
  WorkoutAnnouncer(this.coach);

  final Coach coach;

  TrackerPhase? _phase;
  int _block = -1;
  int _count = -1;
  int _reps = 0;
  FormIssue? _issue;
  bool _saidLeft = false;
  bool _paused = false;

  static String spokenLabel(Block b) =>
      b.exercise.timed ? 'a ${b.target} second ${b.exercise.label.toLowerCase()}' : b.label;

  void update(WorkoutTracker t, {bool cantSee = false}) {
    final phase = t.phase;
    final newBlock = t.blockIndex != _block;

    if (phase == TrackerPhase.intro && (newBlock || _phase != TrackerPhase.intro)) {
      final b = t.block;
      if (_block >= 0 && newBlock) coach.play(Sfx.blockDone);
      final lead = t.blockIndex == 0 ? 'First up' : 'Nice work! Next';
      coach.say(
        '$lead: ${spokenLabel(b)}. ${b.exercise.setupHint}.',
        key: 'intro-${t.blockIndex}',
        cooldown: const Duration(minutes: 10),
        urgent: true,
      );
      _saidLeft = false;
      _reps = 0;
      _issue = null;
    }

    if (phase == TrackerPhase.setup && cantSee) {
      coach.say(
        "I can't see you yet. Step back so your whole body fits.",
        key: 'cant-see',
        // The card stays on screen; the reminder doesn't need to nag.
        cooldown: const Duration(seconds: 30),
      );
    }

    if (phase == TrackerPhase.countdown && t.count != _count) coach.play(Sfx.tick);
    if (phase == TrackerPhase.workout && _phase == TrackerPhase.countdown) coach.play(Sfx.go);

    if (phase == TrackerPhase.workout) _workout(t);

    _phase = phase;
    _block = t.blockIndex;
    _count = t.count;
  }

  void _workout(WorkoutTracker t) {
    if (t.paused != _paused) {
      _paused = t.paused;
      if (t.paused) {
        coach.say('Paused. Take a breath.', key: 'paused', cooldown: Duration.zero, urgent: true);
      }
    }
    if (t.paused) return;

    // A finished rep: a sound, or the problem spoken.
    if (t.reps > _reps) {
      final clean = t.repLog.isNotEmpty && t.repLog.last;
      if (clean) {
        coach.play(Sfx.rep);
      } else {
        final issue = t.errors.isEmpty ? null : t.errors.last.issue;
        if (issue != null) coach.say(issue.cue, key: issue.name);
      }
      _reps = t.reps;
    }

    // A problem appearing mid-rep, so the user can correct it in time.
    final issue = t.liveIssue;
    if (issue != null && issue != _issue) coach.say(issue.cue, key: issue.name);
    _issue = issue;

    if (!t.inPosition) {
      coach.say(t.block.exercise.setupHint, key: 'position', cooldown: const Duration(seconds: 12));
    }

    final left = t.block.units - t.reps;
    if (!_saidLeft && left == 3 && t.block.units >= 6) {
      _saidLeft = true;
      coach.say(
        t.block.exercise.timed ? '15 seconds left. Hold it!' : 'Three more!',
        key: 'left-${t.blockIndex}',
      );
    }
  }
}
