import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../data/models.dart';
import '../data/repository.dart';
import '../game/exercises.dart';
import '../game/levels.dart';
import '../game/progression.dart';

export '../data/models.dart';

/// What changed after a workout, for the results screen.
class WorkoutOutcome {
  const WorkoutOutcome({
    required this.session,
    this.firstClear = false,
    this.unlocked,
    this.rankUp,
    this.newBadges = const {},
    this.goalJustMet = false,
    this.demo = false,
  });

  final SessionResult session;

  /// A scripted demo set: shown, never saved or rewarded.
  final bool demo;
  final bool firstClear;

  /// Level newly unlocked by this result.
  final GameLevel? unlocked;
  final Rank? rankUp;
  final Set<Achievement> newBadges;

  /// This workout completed today's daily goal.
  final bool goalJustMet;
}

/// Main-app state, derived from the profile and stored workouts.
class AppController extends ChangeNotifier {
  AppController(this._repo, UserData data, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now,
      _profile = data.profile!,
      _sessions = List.of(data.sessions),
      _frozen = Set.of(data.frozenDays);

  final Repository _repo;
  final DateTime Function() _clock;
  Profile _profile;
  final List<SessionResult> _sessions;
  final Set<String> _frozen;

  Profile get profile => _profile;
  Repository get repository => _repo;
  List<SessionResult> get sessions => List.unmodifiable(_sessions);
  Set<Limitation> get limits => _profile.limitations;

  DateTime get now => _clock();
  DateTime get _today => _day(now);
  static DateTime _day(DateTime t) => DateTime(t.year, t.month, t.day);
  static String dayKey(DateTime t) =>
      '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';

  // Daily goal and streak

  int get goalSeconds => _profile.minutes * 60;

  int _secondsOn(DateTime day) =>
      _sessions.where((s) => _day(s.at) == day).fold(0, (sum, s) => sum + s.activeSeconds);

  int get todaySeconds => _secondsOn(_today);
  double get goalProgress => (todaySeconds / goalSeconds).clamp(0.0, 1.0);
  bool get goalMetToday => todaySeconds >= goalSeconds;

  bool _counts(DateTime day) => _secondsOn(day) >= goalSeconds || _frozen.contains(dayKey(day));

  /// Days in a row with the daily goal met (or frozen), ending today, or
  /// yesterday until today's goal is met.
  int get streak => _streakFrom(goalMetToday ? _today : _today.subtract(const Duration(days: 1)));

  int _streakFrom(DateTime start) {
    var d = start, n = 0;
    while (_counts(d)) {
      n++;
      d = d.subtract(const Duration(days: 1));
    }
    return n;
  }

  int get bestStreak {
    final days = {
      for (final s in _sessions) _day(s.at),
      for (final f in _frozen) DateTime.parse(f),
    }.where(_counts).toList()..sort();
    var best = 0, run = 0;
    DateTime? prev;
    for (final d in days) {
      run = prev != null && d.difference(prev).inHours.round() <= 25 ? run + 1 : 1;
      best = math.max(best, run);
      prev = d;
    }
    return best;
  }

  /// Monday-first: whether each day this week counted toward the streak.
  List<bool> get week {
    final monday = _today.subtract(Duration(days: _today.weekday - 1));
    return [for (var i = 0; i < 7; i++) _counts(monday.add(Duration(days: i)))];
  }

  int get todayIndex => _today.weekday - 1;

  /// Freezes earned (one per [xpPerFreeze] XP) minus those used, max [maxFreezes].
  int get freezes => (xp ~/ xpPerFreeze - _frozen.length).clamp(0, maxFreezes);

  /// Spend a freeze on yesterday if it was missed and a streak was running.
  /// Returns true when a freeze was used.
  Future<bool> applyFreezeIfNeeded() async {
    final yesterday = _today.subtract(const Duration(days: 1));
    if (_counts(yesterday) || freezes == 0) return false;
    if (_streakFrom(yesterday.subtract(const Duration(days: 1))) == 0) return false;
    _frozen.add(dayKey(yesterday));
    notifyListeners();
    await _repo.saveFrozenDays(_frozen);
    return true;
  }

  // XP and rank

  int get xp => _sessions.fold(0, (s, x) => s + x.xp);
  String get weekId => weekIdFor(now);
  int get weeklyXp => _sessions.where((s) => weekIdFor(s.at) == weekId).fold(0, (s, x) => s + x.xp);
  Rank get rank => rankFor(xp);

  int get totalReps => _sessions.fold(0, (s, x) => s + x.reps);
  int get errorsCaught => _sessions.fold(0, (s, x) => s + x.errors.length);
  int? get avgForm => _sessions.isEmpty
      ? null
      : (_sessions.fold(0, (s, x) => s + x.form) / _sessions.length).round();

  /// Form for the last 7 workouts, oldest first.
  List<int> get formHistory => [
    for (final s in _sessions.skip(math.max(0, _sessions.length - 7))) s.form,
  ];

  Set<Achievement> get badges =>
      badgesFor(sessions: _sessions, stars: levelStars, bestStreak: bestStreak);

  // Levels

  /// Best stars per level number.
  Map<int, int> get levelStars {
    final m = <int, int>{};
    for (final s in _sessions) {
      if (s.kind == SessionKind.level && s.level != null) {
        m[s.level!] = math.max(m[s.level!] ?? 0, s.stars);
      }
    }
    return m;
  }

  int get startLevel => startLevelFor(_profile.experience);

  bool isUnlocked(int n) => n <= startLevel || (levelStars[n - 1] ?? 0) > 0;

  /// The level to play next: the first unlocked one not yet passed.
  GameLevel get currentLevel {
    final stars = levelStars;
    for (var n = startLevel; n <= gameLevels.length; n++) {
      if (isUnlocked(n) && (stars[n] ?? 0) == 0) return levelByNumber(n);
    }
    return gameLevels.last;
  }

  int get levelsCleared => levelStars.values.where((s) => s > 0).length;
  int get totalStars => levelStars.values.fold(0, (a, b) => a + b);

  /// Blocks for a level, adapted to the user's limitations.
  List<Block> blocksFor(GameLevel level) => adaptBlocks(level.blocks, limits);

  Drill get drill =>
      recommendDrill(sessions: _sessions, profile: _profile, currentLevel: currentLevel.number);

  // Saving

  Future<WorkoutOutcome> completeWorkout({
    required SessionKind kind,
    GameLevel? level,
    required List<BlockResult> blocks,
    required int activeSeconds,
    bool demo = false,
  }) async {
    if (demo) {
      // Simulated reps must not earn XP, stars, streak days or leaderboard points.
      return WorkoutOutcome(
        demo: true,
        session: SessionResult(
          kind: kind,
          level: level?.number,
          at: now,
          blocks: blocks,
          activeSeconds: activeSeconds,
          stars: 0,
          xp: 0,
        ),
      );
    }
    final stars0 = levelStars;
    final rank0 = rank;
    final badges0 = badges;
    final goal0 = goalMetToday;

    final draft = SessionResult(
      kind: kind,
      level: level?.number,
      at: now,
      blocks: blocks,
      activeSeconds: activeSeconds,
      stars: 0,
      xp: 0,
    );
    final adapted = level == null ? null : blocksFor(level);
    final complete =
        adapted != null && blocks.length == adapted.length && blocks.every((b) => b.complete);
    final stars = level == null
        ? 0
        : starsFor(form: draft.form, passForm: level.passForm, complete: complete);
    final firstClear = level != null && stars > 0 && (stars0[level.number] ?? 0) == 0;
    final session = SessionResult(
      kind: kind,
      level: level?.number,
      at: draft.at,
      blocks: blocks,
      activeSeconds: activeSeconds,
      stars: stars,
      xp: xpFor(
        kind: kind,
        cleanReps: draft.cleanReps,
        stars: stars,
        firstClear: firstClear,
        boss: level?.boss ?? false,
      ),
    );

    _sessions.add(session);
    final saved = await _repo.addSession(session, _boardUpdate());
    _sessions[_sessions.length - 1] = saved;

    final next = level != null && firstClear && level.number < gameLevels.length
        ? levelByNumber(level.number + 1)
        : null;
    final outcome = WorkoutOutcome(
      session: saved,
      firstClear: firstClear,
      unlocked: next != null && next.number > startLevel ? next : null,
      rankUp: rank.minXp > rank0.minXp ? rank : null,
      newBadges: badges.difference(badges0),
      goalJustMet: !goal0 && goalMetToday,
    );
    notifyListeners();
    return outcome;
  }

  Future<void> setNickname(String nickname) => updateProfile(_profile.copyWith(nickname: nickname));

  /// Save edited settings. Levels, drills and the daily goal follow at once.
  Future<void> updateProfile(Profile p) async {
    _profile = p;
    notifyListeners();
    await _repo.saveProfile(_profile, _boardUpdate());
  }

  LeaderboardUpdate _boardUpdate() =>
      LeaderboardUpdate(nickname: _profile.nickname, xp: xp, weeklyXp: weeklyXp, weekId: weekId);
}
