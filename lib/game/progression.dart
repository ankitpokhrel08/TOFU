import 'dart:math' as math;

import '../data/models.dart';
import 'exercises.dart';
import 'levels.dart';

/// Most XP one workout can earn. Firestore rules enforce the same cap.
const maxXpPerWorkout = 1000;

/// Lifetime XP per streak freeze earned.
const xpPerFreeze = 500;

/// Most freezes held at once.
const maxFreezes = 2;

/// Stars for a level attempt. Unfinished attempts never pass.
int starsFor({required int form, required int passForm, required bool complete}) {
  if (!complete || form < passForm) return 0;
  if (form >= 92) return 3;
  if (form >= math.max(82, passForm + 5)) return 2;
  return 1;
}

/// XP for a workout.
int xpFor({
  required SessionKind kind,
  required int cleanReps,
  required int stars,
  bool firstClear = false,
  bool boss = false,
}) {
  final xp = kind == SessionKind.drill
      ? 15 + cleanReps * 2
      : (20 + cleanReps * 2 + stars * 15 + (firstClear ? 50 : 0)) * (boss ? 2 : 1);
  return math.min(maxXpPerWorkout, xp);
}

class Rank {
  const Rank(this.title, this.minXp);
  final String title;
  final int minXp;
}

const ranks = [
  Rank('Rookie', 0),
  Rank('Mover', 300),
  Rank('Athlete', 900),
  Rank('Pro', 2000),
  Rank('Elite', 4000),
  Rank('Legend', 8000),
];

Rank rankFor(int xp) => ranks.lastWhere((r) => xp >= r.minXp);

Rank? nextRank(int xp) {
  for (final r in ranks) {
    if (r.minXp > xp) return r;
  }
  return null;
}

/// 0–1 progress toward the next rank.
double rankProgress(int xp) {
  final cur = rankFor(xp), next = nextRank(xp);
  if (next == null) return 1;
  return (xp - cur.minXp) / (next.minXp - cur.minXp);
}

enum Achievement {
  firstWorkout('1st', 'First workout'),
  streak7('7', '7-day streak'),
  streak30('30', '30-day streak'),
  flawless('★★★', 'Flawless level'),
  unit1('U1', 'Foundations cleared'),
  unit2('U2', 'Control cleared'),
  unit3('U3', 'Strength cleared'),
  unit4('U4', 'Legend cleared'),
  reps1000('1K', '1,000 reps');

  const Achievement(this.mark, this.label);
  final String mark;
  final String label;
}

/// Badges earned from stored progress.
Set<Achievement> badgesFor({
  required List<SessionResult> sessions,
  required Map<int, int> stars,
  required int bestStreak,
}) {
  final reps = sessions.fold(0, (s, x) => s + x.reps);
  bool cleared(int boss) => (stars[boss] ?? 0) > 0;
  return {
    if (sessions.isNotEmpty) Achievement.firstWorkout,
    if (bestStreak >= 7) Achievement.streak7,
    if (bestStreak >= 30) Achievement.streak30,
    if (stars.values.any((s) => s == 3)) Achievement.flawless,
    if (cleared(5)) Achievement.unit1,
    if (cleared(10)) Achievement.unit2,
    if (cleared(15)) Achievement.unit3,
    if (cleared(20)) Achievement.unit4,
    if (reps >= 1000) Achievement.reps1000,
  };
}

/// A short targeted set for the user's weakest exercise.
class Drill {
  const Drill(this.title, this.reason, this.block);
  final String title;
  final String reason;
  final Block block;
}

const _goalDefaults = {
  'strength': Exercise.pushUp,
  'fat': Exercise.jumpingJack,
  'posture': Exercise.plank,
  'pain': Exercise.gluteBridge,
  'habit': Exercise.squat,
};

const _drillTitles = {
  FormIssue.kneesIn: 'Knee tracking drill',
  FormIssue.shallow: 'Depth drill',
  FormIssue.halfRep: 'Full-range push-ups',
  FormIssue.hipSag: 'Core brace drill',
  FormIssue.hipPike: 'Straight-line drill',
  FormIssue.lungeShallow: 'Lunge depth drill',
  FormIssue.torsoLean: 'Tall torso drill',
  FormIssue.lowBridge: 'Glute squeeze drill',
  FormIssue.shortRange: 'Full-range jacks',
};

/// Pick today's drill: the exercise with the weakest recent form, falling
/// back to the user's goal. Moves that clash with limitations are skipped.
Drill recommendDrill({
  required List<SessionResult> sessions,
  required Profile profile,
  required int currentLevel,
}) {
  final allowed = exercisesUnlockedBy(math.max(currentLevel, startLevelFor(profile.experience)));
  bool ok(Exercise e) =>
      allowed.contains(e) &&
      !(profile.limitations.contains(Limitation.knees) &&
          (e == Exercise.reverseLunge || e == Exercise.jumpingJack));

  // Recent blocks (last 10 workouts), grouped by exercise.
  final recent = sessions.skip(math.max(0, sessions.length - 10));
  final done = <Exercise, (int clean, int total)>{};
  final issues = <Exercise, Map<FormIssue, int>>{};
  for (final s in recent) {
    for (final b in s.blocks) {
      if (!ok(b.exercise) || b.done == 0) continue;
      final (c, t) = done[b.exercise] ?? (0, 0);
      done[b.exercise] = (c + b.clean, t + b.done);
      for (final e in b.errors) {
        final m = issues.putIfAbsent(b.exercise, () => {});
        m[e.issue] = (m[e.issue] ?? 0) + 1;
      }
    }
  }

  Exercise? weakest;
  var worst = 1.0;
  for (final MapEntry(key: e, value: (c, t)) in done.entries) {
    final ratio = c / t;
    if (ratio < .9 && ratio < worst) {
      worst = ratio;
      weakest = e;
    }
  }

  if (weakest != null) {
    final top = issues[weakest]!.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    return Drill(
      _drillTitles[top]!,
      'Your most common slip lately: ${top.title.toLowerCase()}.',
      _drillBlock(weakest),
    );
  }

  final goal = _goalDefaults[profile.goal] ?? Exercise.squat;
  if (ok(goal)) {
    return Drill('Bonus ${goal.label.toLowerCase()}', 'Matched to your goal.', _drillBlock(goal));
  }
  // The goal's move isn't unlocked yet: say so rather than claim a match.
  final pick = ok(Exercise.squat) ? Exercise.squat : Exercise.gluteBridge;
  return Drill('Bonus ${pick.label.toLowerCase()}', 'Extra practice for today.', _drillBlock(pick));
}

Block _drillBlock(Exercise e) => Block(e, e.timed ? 20 : (e == Exercise.jumpingJack ? 20 : 8));

/// Monday (local) of the week containing [t], as `yyyy-mm-dd`.
String weekIdFor(DateTime t) {
  final monday = DateTime(t.year, t.month, t.day).subtract(Duration(days: t.weekday - 1));
  String two(int n) => n.toString().padLeft(2, '0');
  return '${monday.year}-${two(monday.month)}-${two(monday.day)}';
}
