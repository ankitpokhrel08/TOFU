import 'package:flutter_test/flutter_test.dart';
import 'package:gym_guru/app/app_controller.dart';
import 'package:gym_guru/game/exercises.dart';
import 'package:gym_guru/game/levels.dart';
import 'package:gym_guru/game/progression.dart';

import 'helpers.dart';

// Thursday 2026-11-12, 18:00.
final _now = DateTime(2026, 11, 12, 18);
DateTime _daysAgo(int n) => DateTime(_now.year, _now.month, _now.day - n, 9);

Future<(AppController, MemoryRepository)> controller(
  List<SessionResult> sessions, {
  Profile? profile,
  Set<String> frozen = const {},
}) async {
  final repo = MemoryRepository('u1', profile: profile ?? testProfile(), sessions: sessions)
    ..frozen = Set.of(frozen);
  final app = AppController(repo, await repo.load(), clock: () => _now);
  return (app, repo);
}

/// A full, clean run of [level].
List<BlockResult> cleanRun(GameLevel level, {int errors = 0}) => [
  for (final b in level.blocks)
    BlockResult(
      exercise: b.exercise,
      target: b.target,
      repLog: [for (var i = 0; i < b.units; i++) i >= errors],
      errors: [for (var i = 0; i < errors; i++) FormError(i + 1, b.exercise.issues.first)],
    ),
];

void main() {
  group('progression rules', () {
    test('stars need a complete run at the pass mark', () {
      expect(starsFor(form: 100, passForm: 60, complete: false), 0);
      expect(starsFor(form: 59, passForm: 60, complete: true), 0);
      expect(starsFor(form: 70, passForm: 60, complete: true), 1);
      expect(starsFor(form: 85, passForm: 60, complete: true), 2);
      expect(starsFor(form: 95, passForm: 60, complete: true), 3);
      // Boss levels: 2 stars needs pass + 5.
      expect(starsFor(form: 83, passForm: 80, complete: true), 1);
    });

    test('XP rewards clean reps, stars, first clears and bosses', () {
      final normal = xpFor(kind: SessionKind.level, cleanReps: 10, stars: 2);
      expect(normal, 20 + 20 + 30);
      expect(
        xpFor(kind: SessionKind.level, cleanReps: 10, stars: 2, firstClear: true),
        normal + 50,
      );
      expect(xpFor(kind: SessionKind.level, cleanReps: 10, stars: 2, boss: true), normal * 2);
      expect(xpFor(kind: SessionKind.drill, cleanReps: 8, stars: 0), 31);
      expect(
        xpFor(kind: SessionKind.level, cleanReps: 500, stars: 3, firstClear: true, boss: true),
        maxXpPerWorkout,
      );
    });

    test('ranks climb with XP', () {
      expect(rankFor(0).title, 'Rookie');
      expect(rankFor(950).title, 'Athlete');
      expect(nextRank(950)?.title, 'Pro');
      expect(rankFor(100000).title, 'Legend');
      expect(nextRank(100000), isNull);
    });

    test('there are 20 levels in 4 units, each ending in a boss', () {
      expect(gameLevels, hasLength(20));
      for (final l in gameLevels) {
        expect(l.boss, l.number % 5 == 0, reason: 'level ${l.number}');
        expect(l.unit, (l.number - 1) ~/ 5 + 1);
      }
      expect(exercisesUnlockedBy(5), {Exercise.squat, Exercise.gluteBridge});
      expect(exercisesUnlockedBy(20), Exercise.values.toSet());
    });

    test('knee limitations swap out lunges and jumping', () {
      final adapted = adaptBlocks(levelByNumber(17).blocks, {Limitation.knees});
      expect(adapted.map((b) => b.exercise), isNot(contains(Exercise.reverseLunge)));
      expect(adapted.map((b) => b.exercise), isNot(contains(Exercise.jumpingJack)));
    });

    test('experience sets the start level', () {
      expect(startLevelFor('beginner'), 1);
      expect(startLevelFor('intermediate'), 6);
      expect(startLevelFor('advanced'), 11);
    });

    test('week ids start on Monday', () {
      expect(weekIdFor(DateTime(2026, 11, 12)), '2026-11-09');
      expect(weekIdFor(DateTime(2026, 11, 9)), '2026-11-09');
      expect(weekIdFor(DateTime(2026, 11, 8)), '2026-11-02');
    });
  });

  group('drill recommendation', () {
    test('targets the weakest recent exercise and its top issue', () {
      final s = testSession(_daysAgo(1), errors: 5);
      final d = recommendDrill(sessions: [s], profile: testProfile(), currentLevel: 2);
      expect(d.block.exercise, Exercise.squat);
      expect(d.title, 'Knee tracking drill');
    });

    test('falls back to the goal when form is good', () {
      final d = recommendDrill(
        sessions: [testSession(_daysAgo(1))],
        profile: testProfile(goal: 'pain'),
        currentLevel: 2,
      );
      expect(d.block.exercise, Exercise.gluteBridge);
    });

    test('never suggests a move that is not unlocked yet', () {
      final d = recommendDrill(
        sessions: [],
        profile: testProfile(goal: 'fat'),
        currentLevel: 1,
      );
      expect(exercisesUnlockedBy(1), contains(d.block.exercise));
    });

    test('does not claim a goal match when falling back', () {
      // Posture's plank arrives in unit 2, so level 1 gets squats instead.
      final d = recommendDrill(
        sessions: [],
        profile: testProfile(goal: 'posture'),
        currentLevel: 1,
      );
      expect(d.block.exercise, Exercise.squat);
      expect(d.reason, isNot(contains('goal')));
    });
  });

  group('daily goal and streak', () {
    test('is zero for a new user', () async {
      final (app, _) = await controller([]);
      expect(app.streak, 0);
      expect(app.goalMetToday, isFalse);
    });

    test('only days that hit the daily goal count', () async {
      final (app, _) = await controller([
        testSession(_daysAgo(2), activeSeconds: 300),
        testSession(_daysAgo(1), activeSeconds: 120), // short of 5 min
        testSession(_daysAgo(0), activeSeconds: 300),
      ]);
      expect(app.streak, 1);
    });

    test('several workouts add up to the goal', () async {
      final (app, _) = await controller([
        testSession(_daysAgo(0), activeSeconds: 150),
        testSession(_daysAgo(0), activeSeconds: 160),
      ]);
      expect(app.goalMetToday, isTrue);
      expect(app.streak, 1);
    });

    test('stays alive until midnight when today is not done yet', () async {
      final (app, _) = await controller([testSession(_daysAgo(2)), testSession(_daysAgo(1))]);
      expect(app.streak, 2);
    });

    test('a freeze covers a missed yesterday', () async {
      final (app, repo) = await controller([
        testSession(_daysAgo(3), xp: 300),
        testSession(_daysAgo(2), xp: 300),
      ]);
      expect(app.freezes, 1);
      expect(await app.applyFreezeIfNeeded(), isTrue);
      expect(repo.frozen, {'2026-11-11'});
      expect(app.streak, 3);
      expect(app.freezes, 0);
      // Only once.
      expect(await app.applyFreezeIfNeeded(), isFalse);
    });

    test('no freeze is spent without a streak to save', () async {
      final (app, _) = await controller([testSession(_daysAgo(5), xp: 1000)]);
      expect(await app.applyFreezeIfNeeded(), isFalse);
    });
  });

  group('levels', () {
    test('beginners start at level 1, others later', () async {
      expect((await controller([])).$1.currentLevel.number, 1);
      final (adv, _) = await controller([], profile: testProfile(experience: 'advanced'));
      expect(adv.currentLevel.number, 11);
      expect(adv.isUnlocked(5), isTrue);
      expect(adv.isUnlocked(12), isFalse);
    });

    test('passing a level unlocks the next', () async {
      final (app, _) = await controller([]);
      final l1 = levelByNumber(1);
      final out = await app.completeWorkout(
        kind: SessionKind.level,
        level: l1,
        blocks: cleanRun(l1),
        activeSeconds: 300,
      );
      expect(out.session.stars, 3);
      expect(out.firstClear, isTrue);
      expect(out.unlocked?.number, 2);
      expect(out.goalJustMet, isTrue);
      expect(out.newBadges, contains(Achievement.firstWorkout));
      expect(app.currentLevel.number, 2);
      expect(app.isUnlocked(2), isTrue);
    });

    test('a poor run earns no stars and unlocks nothing', () async {
      final (app, _) = await controller([]);
      final l1 = levelByNumber(1);
      final out = await app.completeWorkout(
        kind: SessionKind.level,
        level: l1,
        blocks: cleanRun(l1, errors: 5),
        activeSeconds: 120,
      );
      expect(out.session.stars, 0);
      expect(out.unlocked, isNull);
      expect(app.isUnlocked(2), isFalse);
    });

    test('ending early never passes', () async {
      final (app, _) = await controller([]);
      final l1 = levelByNumber(1);
      final out = await app.completeWorkout(
        kind: SessionKind.level,
        level: l1,
        blocks: [cleanRun(l1).first],
        activeSeconds: 60,
      );
      expect(out.session.stars, 0);
    });

    test('rank-ups are reported', () async {
      final (app, _) = await controller([testSession(_daysAgo(3), xp: 290)]);
      final l1 = levelByNumber(1);
      final out = await app.completeWorkout(
        kind: SessionKind.level,
        level: l1,
        blocks: cleanRun(l1),
        activeSeconds: 300,
      );
      expect(out.rankUp?.title, 'Mover');
    });
  });

  test('editing limitations and daily goal takes effect at once', () async {
    final (app, repo) = await controller([], profile: testProfile(experience: 'advanced'));
    final l17 = levelByNumber(17);
    expect(app.blocksFor(l17).map((b) => b.exercise), contains(Exercise.reverseLunge));
    await app.updateProfile(app.profile.copyWith(limitations: {Limitation.knees}, minutes: 10));
    expect(app.blocksFor(l17).map((b) => b.exercise), isNot(contains(Exercise.reverseLunge)));
    expect(app.goalSeconds, 600);
    expect((await repo.load()).profile!.minutes, 10);
  });

  test('demo sets are never saved or rewarded', () async {
    final (app, repo) = await controller([]);
    final l1 = levelByNumber(1);
    final out = await app.completeWorkout(
      kind: SessionKind.level,
      level: l1,
      blocks: cleanRun(l1),
      activeSeconds: 300,
      demo: true,
    );
    expect(out.demo, isTrue);
    expect(out.session.xp, 0);
    expect(out.unlocked, isNull);
    expect(app.sessions, isEmpty);
    expect(app.isUnlocked(2), isFalse);
    expect(repo.writes, 0);
  });

  test('leaderboard totals are written with each workout', () async {
    final (app, repo) = await controller([testSession(_daysAgo(8), xp: 200)]);
    final l1 = levelByNumber(1);
    final out = await app.completeWorkout(
      kind: SessionKind.level,
      level: l1,
      blocks: cleanRun(l1),
      activeSeconds: 300,
    );
    final board = await repo.leaderboard();
    expect(board.single.xp, 200 + out.session.xp);
    expect(board.single.weeklyXp, out.session.xp);
    expect(board.single.nickname, 'SamLifts');
  });
}
