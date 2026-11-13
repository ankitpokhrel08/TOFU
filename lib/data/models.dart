import 'dart:math' as math;

/// Reps per set in a lesson.
const repTarget = 12;

class FormError {
  const FormError(this.rep, this.title, this.tip);

  factory FormError.fromJson(Map<String, dynamic> j) =>
      FormError(j['rep'] as int, j['title'] as String, j['tip'] as String);

  final int rep;
  final String title;
  final String tip;

  Map<String, dynamic> toJson() => {'rep': rep, 'title': title, 'tip': tip};
}

/// Outcome of one tracked set.
class SessionResult {
  const SessionResult({
    required this.repLog,
    required this.errors,
    required this.form,
    required this.at,
    required this.lesson,
  });

  factory SessionResult.fromJson(Map<String, dynamic> j) => SessionResult(
    repLog: [for (final r in j['repLog'] as List) r as bool],
    errors: [for (final e in j['errors'] as List) FormError.fromJson(e as Map<String, dynamic>)],
    form: j['form'] as int,
    at: DateTime.parse(j['at'] as String),
    lesson: j['lesson'] as int,
  );

  /// true = clean rep, false = rep with a form error.
  final List<bool> repLog;
  final List<FormError> errors;
  final int form;

  /// When the set finished (local time).
  final DateTime at;

  /// Path lesson number this set counted toward.
  final int lesson;

  int get reps => repLog.length;
  int get cleanReps => repLog.where((r) => r).length;
  int get xpGain => 40 + math.max(0, form - 80);

  String get title => form >= 90
      ? 'Crushed it!'
      : form >= 80
      ? 'Strong session!'
      : 'Good start!';

  Map<String, dynamic> toJson() => {
    'repLog': repLog,
    'errors': [for (final e in errors) e.toJson()],
    'form': form,
    'at': at.toIso8601String(),
    'lesson': lesson,
  };
}

/// Answers kept from onboarding.
class Profile {
  const Profile({
    required this.goals,
    required this.planName,
    required this.minutes,
    required this.levelShort,
    required this.plan,
    required this.createdAt,
  });

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
    goals: [for (final g in j['goals'] as List) g as String],
    planName: j['planName'] as String,
    minutes: j['minutes'] as int,
    levelShort: j['levelShort'] as String,
    plan: j['plan'] as String,
    createdAt: DateTime.parse(j['createdAt'] as String),
  );

  final List<String> goals;
  final String planName;
  final int minutes;

  /// Short level label, e.g. "New", "Mid", "Adv.".
  final String levelShort;

  /// "annual" or "monthly".
  final String plan;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
    'goals': goals,
    'planName': planName,
    'minutes': minutes,
    'levelShort': levelShort,
    'plan': plan,
    'createdAt': createdAt.toIso8601String(),
  };
}
