import 'package:cloud_firestore/cloud_firestore.dart';

import 'models.dart';

/// Everything stored for the signed-in user.
class UserData {
  const UserData({required this.profile, required this.sessions, required this.frozenDays});
  final Profile? profile;

  /// Oldest first.
  final List<SessionResult> sessions;

  /// Days (yyyy-mm-dd) protected by a streak freeze.
  final Set<String> frozenDays;
}

/// Totals written to the public leaderboard with each workout.
class LeaderboardUpdate {
  const LeaderboardUpdate({
    required this.nickname,
    required this.xp,
    required this.weeklyXp,
    required this.weekId,
  });
  final String nickname;
  final int xp;
  final int weeklyXp;
  final String weekId;

  Map<String, dynamic> toJson() => {
    'nickname': nickname,
    'xp': xp,
    'weeklyXp': weeklyXp,
    'weekId': weekId,
  };
}

abstract class Repository {
  /// Signed-in user's id.
  String get uid;

  /// Fast load (on-device cache when available).
  Future<UserData> load();

  /// Up-to-date data from the server, for refreshing after a fast load.
  Future<UserData> loadFromServer();
  Future<void> saveProfile(Profile p, LeaderboardUpdate board);

  /// Saves a workout and the new leaderboard totals together.
  Future<SessionResult> addSession(SessionResult s, LeaderboardUpdate board);
  Future<void> saveFrozenDays(Set<String> days);

  /// Top [limit] players, all-time or for [weekId].
  Future<List<LeaderboardEntry>> leaderboard({String? weekId, int limit = 50});

  /// 1-based rank for a score, all-time or for [weekId].
  Future<int> rankFor(int score, {String? weekId});

  /// Removes the user's profile, sessions and leaderboard entry.
  Future<void> deleteAll();
}

/// Firestore layout (prefixed so the app can share a Firebase project):
/// - `gymguru_users/{uid}`: profile fields and `frozenDays`
/// - `gymguru_users/{uid}/sessions/{id}`: one doc per workout
/// - `gymguru_leaderboard/{uid}`: public nickname and XP totals
class FirestoreRepository implements Repository {
  FirestoreRepository(this.uid, {FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  @override
  final String uid;
  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> get _user => _db.collection('gymguru_users').doc(uid);
  CollectionReference<Map<String, dynamic>> get _sessions => _user.collection('sessions');
  CollectionReference<Map<String, dynamic>> get _board => _db.collection('gymguru_leaderboard');

  /// Waits this long for the server before using the on-device cache.
  static const _serverTimeout = Duration(seconds: 4);

  /// Opens instantly from the on-device cache when it has a profile; the
  /// first launch on a device (empty cache) goes to the server.
  @override
  Future<UserData> load() async {
    try {
      final cached = await _read(Source.cache);
      if (cached.profile != null) return cached;
    } on Object {
      // Nothing cached yet.
    }
    return loadFromServer();
  }

  /// Fresh data from the server, falling back to the cache when the
  /// connection is slow or offline.
  @override
  Future<UserData> loadFromServer() async {
    try {
      return await _read(Source.server).timeout(_serverTimeout);
    } on Object {
      return _read(Source.cache);
    }
  }

  Future<UserData> _read(Source source) async {
    final options = GetOptions(source: source);
    final user = await _user.get(options);
    final sessions = await _sessions.orderBy('at').get(options);
    final data = user.data();
    return UserData(
      profile: data?['profile'] == null
          ? null
          : Profile.fromJson(Map<String, dynamic>.from(data!['profile'] as Map)),
      sessions: [for (final d in sessions.docs) SessionResult.fromJson(d.data(), id: d.id)],
      frozenDays: {for (final d in (data?['frozenDays'] as List? ?? const [])) d as String},
    );
  }

  @override
  Future<void> saveProfile(Profile p, LeaderboardUpdate board) async {
    final batch = _db.batch()
      ..set(_user, {'profile': p.toJson()}, SetOptions(merge: true))
      ..set(_board.doc(uid), {...board.toJson(), 'updatedAt': FieldValue.serverTimestamp()});
    await batch.commit();
  }

  @override
  Future<SessionResult> addSession(SessionResult s, LeaderboardUpdate board) async {
    final doc = _sessions.doc();
    final batch = _db.batch()
      ..set(doc, s.toJson())
      ..set(_board.doc(uid), {...board.toJson(), 'updatedAt': FieldValue.serverTimestamp()});
    await batch.commit();
    return SessionResult.fromJson(s.toJson(), id: doc.id);
  }

  @override
  Future<void> saveFrozenDays(Set<String> days) =>
      _user.set({'frozenDays': days.toList()..sort()}, SetOptions(merge: true));

  Query<Map<String, dynamic>> _boardQuery(String? weekId) => weekId == null
      ? _board.orderBy('xp', descending: true)
      : _board.where('weekId', isEqualTo: weekId).orderBy('weeklyXp', descending: true);

  @override
  Future<List<LeaderboardEntry>> leaderboard({String? weekId, int limit = 50}) async {
    final snap = await _boardQuery(weekId).limit(limit).get();
    return [
      for (final d in snap.docs)
        LeaderboardEntry(
          uid: d.id,
          nickname: d['nickname'] as String,
          xp: d['xp'] as int,
          weeklyXp: d['weekId'] == weekId ? d['weeklyXp'] as int : 0,
        ),
    ];
  }

  @override
  Future<int> rankFor(int score, {String? weekId}) async {
    final q = weekId == null
        ? _board.where('xp', isGreaterThan: score)
        : _board.where('weekId', isEqualTo: weekId).where('weeklyXp', isGreaterThan: score);
    final count = await q.count().get();
    return (count.count ?? 0) + 1;
  }

  @override
  Future<void> deleteAll() async {
    final sessions = await _sessions.get();
    // Batches hold up to 500 writes.
    for (var i = 0; i < sessions.docs.length; i += 450) {
      final batch = _db.batch();
      for (final d in sessions.docs.skip(i).take(450)) {
        batch.delete(d.reference);
      }
      await batch.commit();
    }
    await _board.doc(uid).delete();
    await _user.delete();
  }
}
