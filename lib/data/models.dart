import '../game/exercises.dart';

class FormError {
  const FormError(this.rep, this.issue);

  factory FormError.fromJson(Map<String, dynamic> j) =>
      FormError(j['rep'] as int, FormIssue.values.byName(j['issue'] as String));

  final int rep;
  final FormIssue issue;

  String get title => issue.title;
  String get tip => issue.tip;

  Map<String, dynamic> toJson() => {'rep': rep, 'issue': issue.name};
}

/// One exercise within a finished workout.
class BlockResult {
  const BlockResult({
    required this.exercise,
    required this.target,
    required this.repLog,
    required this.errors,
  });

  factory BlockResult.fromJson(Map<String, dynamic> j) => BlockResult(
    exercise: Exercise.values.byName(j['exercise'] as String),
    target: j['target'] as int,
    repLog: [for (final r in j['repLog'] as List) r as bool],
    errors: [for (final e in j['errors'] as List) FormError.fromJson(e as Map<String, dynamic>)],
  );

  final Exercise exercise;

  /// Reps, or seconds for holds.
  final int target;

  /// One entry per graded unit (rep or 5-second hold segment): true = clean.
  final List<bool> repLog;
  final List<FormError> errors;

  int get units => exercise.timed ? (target / Exercise.holdSegment).ceil() : target;
  int get done => repLog.length;
  int get clean => repLog.where((r) => r).length;
  bool get complete => done >= units;

  /// Share of finished units that were clean, 0–100.
  int get form => done == 0 ? 0 : (100 * clean / done).round();

  Map<String, dynamic> toJson() => {
    'exercise': exercise.name,
    'target': target,
    'repLog': repLog,
    'errors': [for (final e in errors) e.toJson()],
  };
}

enum SessionKind { level, drill }

/// A finished workout (a level attempt or a drill).
class SessionResult {
  const SessionResult({
    required this.kind,
    required this.at,
    required this.blocks,
    required this.activeSeconds,
    required this.stars,
    required this.xp,
    this.level,
    this.id,
  });

  factory SessionResult.fromJson(Map<String, dynamic> j, {String? id}) => SessionResult(
    id: id,
    kind: SessionKind.values.byName(j['kind'] as String),
    level: j['level'] as int?,
    at: DateTime.parse(j['at'] as String),
    blocks: [for (final b in j['blocks'] as List) BlockResult.fromJson(b as Map<String, dynamic>)],
    activeSeconds: j['activeSeconds'] as int,
    stars: j['stars'] as int,
    xp: j['xp'] as int,
  );

  final String? id;
  final SessionKind kind;

  /// Level number for level attempts.
  final int? level;

  /// Finish time (local).
  final DateTime at;
  final List<BlockResult> blocks;

  /// Seconds spent training (excludes setup, countdowns and pauses).
  final int activeSeconds;

  /// 0–3; 0 means the level wasn't passed.
  final int stars;
  final int xp;

  bool get complete => blocks.every((b) => b.complete);
  int get reps => blocks.fold(0, (s, b) => s + b.done);
  int get cleanReps => blocks.fold(0, (s, b) => s + b.clean);
  List<FormError> get errors => [for (final b in blocks) ...b.errors];

  /// Form across all graded units, 0–100.
  int get form => reps == 0 ? 0 : (100 * cleanReps / reps).round();

  String get title => stars == 3
      ? 'Flawless!'
      : stars == 2
      ? 'Crushed it!'
      : stars == 1
      ? 'Level cleared!'
      : kind == SessionKind.drill
      ? 'Drill done!'
      : 'So close!';

  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    'level': level,
    'at': at.toIso8601String(),
    'blocks': [for (final b in blocks) b.toJson()],
    'activeSeconds': activeSeconds,
    'stars': stars,
    'xp': xp,
  };
}

/// Setup answers. Only what the app uses.
class Profile {
  const Profile({
    required this.name,
    required this.nickname,
    required this.goal,
    required this.experience,
    required this.minutes,
    required this.limitations,
    required this.createdAt,
    this.voice = true,
    this.sounds = true,
  });

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
    name: j['name'] as String,
    nickname: j['nickname'] as String,
    goal: j['goal'] as String,
    experience: j['experience'] as String,
    minutes: j['minutes'] as int,
    limitations: {
      for (final l in (j['limitations'] as List? ?? const []))
        Limitation.values.byName(l as String),
    },
    createdAt: DateTime.parse(j['createdAt'] as String),
    voice: j['voice'] as bool? ?? true,
    sounds: j['sounds'] as bool? ?? true,
  );

  /// Spoken coaching during workouts.
  final bool voice;

  /// Sound effects (reps, countdown, celebrations).
  final bool sounds;

  /// First name, for greetings.
  final String name;

  /// Public name on the leaderboard.
  final String nickname;

  /// One of `goals` ids.
  final String goal;

  /// beginner / intermediate / advanced.
  final String experience;

  /// Daily training goal in minutes.
  final int minutes;
  final Set<Limitation> limitations;
  final DateTime createdAt;

  Profile copyWith({
    String? nickname,
    String? goal,
    int? minutes,
    Set<Limitation>? limitations,
    bool? voice,
    bool? sounds,
  }) => Profile(
    name: name,
    nickname: nickname ?? this.nickname,
    goal: goal ?? this.goal,
    experience: experience,
    minutes: minutes ?? this.minutes,
    limitations: limitations ?? this.limitations,
    createdAt: createdAt,
    voice: voice ?? this.voice,
    sounds: sounds ?? this.sounds,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'nickname': nickname,
    'goal': goal,
    'experience': experience,
    'minutes': minutes,
    'limitations': [for (final l in limitations) l.name],
    'createdAt': createdAt.toIso8601String(),
    'voice': voice,
    'sounds': sounds,
  };
}

/// One row on the leaderboard.
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.uid,
    required this.nickname,
    required this.xp,
    required this.weeklyXp,
  });

  final String uid;
  final String nickname;
  final int xp;
  final int weeklyXp;
}
