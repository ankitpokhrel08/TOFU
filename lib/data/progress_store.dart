import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

/// On-device storage for the profile and completed sessions.
class ProgressStore {
  ProgressStore._(this._prefs) {
    _profile = _readProfile();
    _sessions = _readSessions();
  }

  static const _profileKey = 'profile.v1';
  static const _sessionsKey = 'sessions.v1';

  static Future<ProgressStore> open() async =>
      ProgressStore._(await SharedPreferences.getInstance());

  final SharedPreferences _prefs;
  Profile? _profile;
  late List<SessionResult> _sessions;

  /// Null until onboarding is finished.
  Profile? get profile => _profile;

  /// All sessions, oldest first.
  List<SessionResult> get sessions => List.unmodifiable(_sessions);

  Future<void> saveProfile(Profile p) async {
    _profile = p;
    await _prefs.setString(_profileKey, jsonEncode(p.toJson()));
  }

  Future<void> addSession(SessionResult s) async {
    _sessions.add(s);
    await _prefs.setString(_sessionsKey, jsonEncode([for (final s in _sessions) s.toJson()]));
  }

  Profile? _readProfile() {
    final raw = _prefs.getString(_profileKey);
    if (raw == null) return null;
    try {
      return Profile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object {
      // Corrupt or outdated data: fall back to onboarding rather than crash.
      return null;
    }
  }

  List<SessionResult> _readSessions() {
    final raw = _prefs.getString(_sessionsKey);
    if (raw == null) return [];
    try {
      return [
        for (final s in jsonDecode(raw) as List) SessionResult.fromJson(s as Map<String, dynamic>),
      ];
    } on Object {
      return [];
    }
  }
}
