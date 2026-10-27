import 'dart:math' as math;

import 'package:flutter/foundation.dart';

/// Reps per set in a lesson.
const repTarget = 12;

class FormError {
  const FormError(this.rep, this.title, this.tip);
  final int rep;
  final String title;
  final String tip;
}

/// Outcome of one tracked set.
class SessionResult {
  const SessionResult({required this.repLog, required this.errors, required this.form});

  /// true = clean rep, false = rep with a form error.
  final List<bool> repLog;
  final List<FormError> errors;
  final int form;

  int get reps => repLog.length;
  int get cleanReps => repLog.where((r) => r).length;
  int get xpGain => 40 + math.max(0, form - 80);

  String get title => form >= 90
      ? 'Crushed it!'
      : form >= 80
      ? 'Strong session!'
      : 'Good start!';
}

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

/// Lessons 1–4 are unlocked for the current unit.
const unlockedLessons = 4;

/// User progress for the main app. Values before today's lesson are seeded
/// to match a returning user mid-streak.
class AppController extends ChangeNotifier {
  static const _baseStreak = 12;
  static const _baseXp = 1840;
  static const _baseChallenge = 64;
  static const _baseReps = 640;

  final String name = 'Alex';

  SessionResult? _today;

  /// Today's completed set, if any.
  SessionResult? get today => _today;
  bool get doneToday => _today != null;

  int get streak => _baseStreak + (doneToday ? 1 : 0);
  int get xp => _baseXp + (_today?.xpGain ?? 0);
  int get totalReps => _baseReps + (_today?.reps ?? 0);
  int get avgForm => 81;
  int get errorsFixed => 23;

  /// Progress toward "100 clean squats" this week.
  int get challenge =>
      math.min(100, _baseChallenge + (doneToday ? math.max(_today!.cleanReps, 10) : 0));

  /// Lessons mastered on the path (lesson 1 was done before today).
  int get masteredCount => doneToday ? 2 : 1;

  /// The lesson Home offers today.
  Lesson get todaysLesson => pathLessons[1];

  /// Form score for the last 7 sessions, newest last.
  List<int> get formHistory => [68, 72, 70, 79, 83, 86, _today?.form ?? 88];

  void completeSession(SessionResult result) {
    _today = result;
    notifyListeners();
  }
}
