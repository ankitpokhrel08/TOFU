import 'dart:convert';

import 'package:gym_guru/data/models.dart';
import 'package:gym_guru/data/progress_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

Profile testProfile({DateTime? createdAt}) => Profile(
  goals: const ['strength'],
  planName: 'Strength Foundations',
  minutes: 5,
  levelShort: 'New',
  plan: 'annual',
  createdAt: createdAt ?? DateTime(2026, 11, 2),
);

SessionResult testSession(DateTime at, {int lesson = 1, int form = 91, int errors = 1}) =>
    SessionResult(
      repLog: [for (var i = 0; i < 12; i++) i >= errors],
      errors: [for (var i = 0; i < errors; i++) FormError(i + 1, 'Too shallow', 'Go lower')],
      form: form,
      at: at,
      lesson: lesson,
    );

/// Fresh store backed by in-memory preferences.
Future<ProgressStore> makeStore({Profile? profile, List<SessionResult> sessions = const []}) async {
  SharedPreferences.setMockInitialValues({
    if (profile != null) 'profile.v1': jsonEncode(profile.toJson()),
    if (sessions.isNotEmpty) 'sessions.v1': jsonEncode([for (final s in sessions) s.toJson()]),
  });
  return ProgressStore.open();
}
