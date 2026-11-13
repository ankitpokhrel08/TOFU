import 'package:flutter_test/flutter_test.dart';
import 'package:gym_guru/app/app_controller.dart';
import 'package:gym_guru/data/progress_store.dart';

import 'helpers.dart';

// Thursday 2026-11-12, 18:00.
final _now = DateTime(2026, 11, 12, 18);
DateTime _daysAgo(int n) => DateTime(_now.year, _now.month, _now.day - n, 9);

Future<AppController> controller(List<SessionResult> sessions) async {
  final store = await makeStore(profile: testProfile(), sessions: sessions);
  return AppController(store, clock: () => _now);
}

void main() {
  group('streak', () {
    test('is zero for a new user', () async {
      final c = await controller([]);
      expect(c.streak, 0);
      expect(c.doneToday, isFalse);
    });

    test('counts consecutive days ending today', () async {
      final c = await controller([
        testSession(_daysAgo(2)),
        testSession(_daysAgo(1)),
        testSession(_daysAgo(0)),
      ]);
      expect(c.streak, 3);
      expect(c.doneToday, isTrue);
    });

    test('stays alive until midnight when today is not done yet', () async {
      final c = await controller([testSession(_daysAgo(2)), testSession(_daysAgo(1))]);
      expect(c.streak, 2);
    });

    test('resets after a missed day', () async {
      final c = await controller([
        testSession(_daysAgo(4)),
        testSession(_daysAgo(3)),
        testSession(_daysAgo(1)),
      ]);
      expect(c.streak, 1);
      expect(c.bestStreak, 2);
    });

    test('several sets in one day count once', () async {
      final c = await controller([testSession(_daysAgo(0)), testSession(_daysAgo(0))]);
      expect(c.streak, 1);
    });
  });

  test('week marks the days trained this week (Monday first)', () async {
    // Monday the 9th and Wednesday the 11th; last Sunday doesn't count.
    final c = await controller([
      testSession(_daysAgo(4)),
      testSession(_daysAgo(3)),
      testSession(_daysAgo(1)),
    ]);
    expect(c.week, [true, false, true, false, false, false, false]);
    expect(c.todayIndex, 3);
  });

  test('path advances one lesson per completed lesson', () async {
    final c = await controller([testSession(_daysAgo(1), lesson: 1)]);
    expect(c.masteredCount, 1);
    expect(c.todaysLesson.number, 2);
    expect(c.nextLesson?.number, 3);
  });

  test('practising again today repeats today\'s lesson', () async {
    final c = await controller([testSession(_daysAgo(0), lesson: 1)]);
    expect(c.todaysLesson.number, 1);
  });

  test('totals and challenge come from stored sessions', () async {
    final c = await controller([
      testSession(_daysAgo(8), form: 80, errors: 2), // last week
      testSession(_daysAgo(1), form: 100, errors: 0),
    ]);
    expect(c.totalReps, 24);
    expect(c.errorsCaught, 2);
    expect(c.avgForm, 90);
    expect(c.challenge, 12); // only this week's clean reps
    expect(c.hasPerfectSet, isTrue);
    expect(c.xp, (40 + 0) + (40 + 20));
  });

  test('completed sessions are saved and survive a restart', () async {
    final c = await controller([]);
    await c.completeSession(repLog: List.filled(12, true), errors: const [], form: 100);
    expect(c.streak, 1);

    final reopened = await ProgressStore.open();
    expect(reopened.sessions, hasLength(1));
    expect(reopened.sessions.single.lesson, 1);
    expect(reopened.profile?.planName, 'Strength Foundations');
  });
}
