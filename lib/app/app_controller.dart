import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../data/models.dart';
import '../data/progress_store.dart';

export '../data/models.dart';

class Lesson {
  const Lesson(this.number, this.name);
  final int number;
  final String name;
}

const pathLessons = [
  Lesson(1, 'Hip hinge'),
  Lesson(2, 'Squat depth'),
  Lesson(3, 'Core bracing'),
  Lesson(4, 'Push-up form'),
  Lesson(5, 'Lunge balance'),
  Lesson(6, 'Pull mechanics'),
  Lesson(7, 'Overhead press'),
  Lesson(8, 'Mobility flow'),
];

/// Lessons unlocked from the start of the unit.
const unlockedLessons = 4;

/// Weekly challenge target (clean reps).
const challengeTarget = 100;

/// Main-app state derived from the stored profile and sessions.
class AppController extends ChangeNotifier {
  AppController(this._store, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final ProgressStore _store;
  final DateTime Function() _clock;

  Profile get profile => _store.profile!;
  List<SessionResult> get sessions => _store.sessions;

  DateTime get now => _clock();
  DateTime get _today => _day(now);

  static DateTime _day(DateTime t) => DateTime(t.year, t.month, t.day);

  Set<DateTime> get _trainedDays => {for (final s in sessions) _day(s.at)};

  /// The most recent set finished today, if any.
  SessionResult? get today {
    for (final s in sessions.reversed) {
      if (_day(s.at) == _today) return s;
    }
    return null;
  }

  bool get doneToday => today != null;

  /// Consecutive training days ending today, or yesterday if today isn't
  /// done yet (the streak stays alive until midnight).
  int get streak {
    final days = _trainedDays;
    var d = doneToday ? _today : _today.subtract(const Duration(days: 1));
    var n = 0;
    while (days.contains(d)) {
      n++;
      d = d.subtract(const Duration(days: 1));
    }
    return n;
  }

  int get bestStreak {
    final days = _trainedDays.toList()..sort();
    var best = 0, run = 0;
    DateTime? prev;
    for (final d in days) {
      run = prev != null && d.difference(prev).inHours.round() <= 25 ? run + 1 : 1;
      best = math.max(best, run);
      prev = d;
    }
    return best;
  }

  /// Monday-first training days for the current week.
  List<bool> get week {
    final monday = _today.subtract(Duration(days: _today.weekday - 1));
    final days = _trainedDays;
    return [for (var i = 0; i < 7; i++) days.contains(monday.add(Duration(days: i)))];
  }

  /// Index of today in [week].
  int get todayIndex => _today.weekday - 1;

  /// Day of the plan, counting the day onboarding finished as day 1.
  int get planDay => _today.difference(_day(profile.createdAt)).inDays + 1;

  int get xp => sessions.fold(0, (sum, s) => sum + s.xpGain);
  int get totalReps => sessions.fold(0, (sum, s) => sum + s.reps);
  int get errorsCaught => sessions.fold(0, (sum, s) => sum + s.errors.length);

  int? get avgForm => sessions.isEmpty
      ? null
      : (sessions.fold(0, (sum, s) => sum + s.form) / sessions.length).round();

  bool get hasPerfectSet => sessions.any((s) => s.form == 100 && s.reps >= repTarget);

  /// Clean reps this week toward the weekly challenge.
  int get challenge {
    final monday = _today.subtract(Duration(days: _today.weekday - 1));
    final clean = sessions
        .where((s) => !_day(s.at).isBefore(monday))
        .fold(0, (sum, s) => sum + s.cleanReps);
    return math.min(challengeTarget, clean);
  }

  /// Distinct path lessons completed.
  int get masteredCount => {for (final s in sessions) s.lesson}.length;

  /// Lessons the user can see as unlocked on the path.
  int get unlockedCount => math.max(unlockedLessons, masteredCount + 1);

  /// Today's lesson: the one already done today (for practice), otherwise
  /// the next one on the path.
  Lesson get todaysLesson {
    final done = today;
    if (done != null) return pathLessons[done.lesson - 1];
    return pathLessons[math.min(masteredCount, pathLessons.length - 1)];
  }

  /// The lesson that unlocks after today's.
  Lesson? get nextLesson {
    final i = todaysLesson.number;
    return i < pathLessons.length ? pathLessons[i] : null;
  }

  /// Form scores for the last 7 sessions, oldest first.
  List<int> get formHistory => [
    for (final s in sessions.skip(math.max(0, sessions.length - 7))) s.form,
  ];

  /// Stamp a finished set with the current lesson and time, then save it.
  Future<SessionResult> completeSession({
    required List<bool> repLog,
    required List<FormError> errors,
    required int form,
  }) async {
    final result = SessionResult(
      repLog: repLog,
      errors: errors,
      form: form,
      at: now,
      lesson: todaysLesson.number,
    );
    await _store.addSession(result);
    notifyListeners();
    return result;
  }
}
