import 'dart:async';

import 'package:gym_guru/data/auth.dart';
import 'package:gym_guru/data/models.dart';
import 'package:gym_guru/data/repository.dart';
import 'package:gym_guru/game/exercises.dart';
import 'package:gym_guru/game/levels.dart';

Profile testProfile({
  String experience = 'beginner',
  int minutes = 5,
  Set<Limitation> limitations = const {},
  String goal = 'strength',
}) => Profile(
  name: 'Sam',
  nickname: 'SamLifts',
  goal: goal,
  experience: experience,
  minutes: minutes,
  limitations: limitations,
  createdAt: DateTime(2026, 11, 2),
);

/// A finished workout. [errors] marks the first N units of each block bad.
SessionResult testSession(
  DateTime at, {
  int? level = 1,
  int errors = 0,
  int activeSeconds = 300,
  int stars = 2,
  int xp = 100,
  List<Block>? blocks,
}) {
  final bs =
      blocks ?? (level == null ? [const Block(Exercise.squat, 8)] : levelByNumber(level).blocks);
  return SessionResult(
    kind: level == null ? SessionKind.drill : SessionKind.level,
    level: level,
    at: at,
    blocks: [
      for (final b in bs)
        BlockResult(
          exercise: b.exercise,
          target: b.target,
          repLog: [for (var i = 0; i < b.units; i++) i >= errors],
          errors: [
            for (var i = 0; i < errors && i < b.units; i++)
              FormError(i + 1, b.exercise.issues.first),
          ],
        ),
    ],
    activeSeconds: activeSeconds,
    stars: stars,
    xp: xp,
  );
}

/// Repository kept in memory, with a shared leaderboard across users.
class MemoryRepository implements Repository {
  MemoryRepository(this.uid, {this.board, this.profile, List<SessionResult> sessions = const []})
    : _sessions = List.of(sessions);

  @override
  final String uid;

  /// Shared leaderboard (uid → entry). Defaults to a private one.
  final Map<String, LeaderboardEntry>? board;
  late final Map<String, LeaderboardEntry> _board = board ?? {};

  Profile? profile;
  final List<SessionResult> _sessions;
  Set<String> frozen = {};
  int writes = 0;

  @override
  Future<UserData> load() async =>
      UserData(profile: profile, sessions: List.of(_sessions), frozenDays: Set.of(frozen));

  void _writeBoard(LeaderboardUpdate u) => _board[uid] = LeaderboardEntry(
    uid: uid,
    nickname: u.nickname,
    xp: u.xp,
    weeklyXp: u.weeklyXp,
  );

  final _weeks = <String, String>{};

  @override
  Future<UserData> loadFromServer() => load();

  @override
  Future<void> saveProfile(Profile p, LeaderboardUpdate b) async {
    writes++;
    profile = p;
    _writeBoard(b);
    _weeks[uid] = b.weekId;
  }

  @override
  Future<SessionResult> addSession(SessionResult s, LeaderboardUpdate b) async {
    writes++;
    final saved = SessionResult.fromJson(s.toJson(), id: 's${_sessions.length}');
    _sessions.add(saved);
    _writeBoard(b);
    _weeks[uid] = b.weekId;
    return saved;
  }

  @override
  Future<void> saveFrozenDays(Set<String> days) async => frozen = Set.of(days);

  @override
  Future<List<LeaderboardEntry>> leaderboard({String? weekId, int limit = 50}) async {
    final all = _board.values.toList()
      ..sort((a, b) => (weekId == null ? b.xp.compareTo(a.xp) : b.weeklyXp.compareTo(a.weeklyXp)));
    return all.take(limit).toList();
  }

  @override
  Future<int> rankFor(int score, {String? weekId}) async =>
      _board.values.where((e) => (weekId == null ? e.xp : e.weeklyXp) > score).length + 1;

  @override
  Future<void> deleteAll() async {
    profile = null;
    _sessions.clear();
    _board.remove(uid);
  }
}

class FakeAuth implements AuthService {
  FakeAuth({this.user});

  AppUser? user;
  final _changes = StreamController<AppUser?>.broadcast();
  bool cancelNext = false;

  @override
  AppUser? get currentUser => user;

  @override
  Stream<AppUser?> get changes async* {
    yield user;
    yield* _changes.stream;
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    if (cancelNext) {
      cancelNext = false;
      throw SignInCancelled();
    }
    user = const AppUser(uid: 'u1', displayName: 'Sam Rivera', email: 'sam@example.com');
    _changes.add(user);
    return user!;
  }

  @override
  Future<void> signOut() async {
    user = null;
    _changes.add(null);
  }

  @override
  Future<void> deleteAccount() => signOut();
}
