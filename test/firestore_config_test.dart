// Firestore needs a deployed composite index for every query that filters
// on one field and orders or ranges on another. The in-memory repository
// can't catch a missing one, so check the config the app deploys.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final indexes = (jsonDecode(File('firestore.indexes.json').readAsStringSync())['indexes'] as List)
      .cast<Map<String, dynamic>>();

  bool hasIndex(String collection, List<(String, String)> fields) => indexes.any(
    (i) =>
        i['collectionGroup'] == collection &&
        (i['fields'] as List).length == fields.length &&
        [
          for (final (k, f) in (i['fields'] as List).indexed)
            f['fieldPath'] == fields[k].$1 && f['order'] == fields[k].$2,
        ].every((ok) => ok),
  );

  test('weekly top players query has an index', () {
    // leaderboard(weekId:): where weekId == …, orderBy weeklyXp desc.
    expect(
      hasIndex('gymguru_leaderboard', [('weekId', 'ASCENDING'), ('weeklyXp', 'DESCENDING')]),
      isTrue,
    );
  });

  test('weekly rank count query has an index', () {
    // rankFor(weekId:): where weekId == …, where weeklyXp > ….
    expect(
      hasIndex('gymguru_leaderboard', [('weekId', 'ASCENDING'), ('weeklyXp', 'ASCENDING')]),
      isTrue,
    );
  });

  test('rules and code use the same collections', () {
    final rules = File('firestore.rules').readAsStringSync();
    final repo = File('lib/data/repository.dart').readAsStringSync();
    for (final c in RegExp(r"collection\('(\w+)'\)").allMatches(repo).map((m) => m[1]!)) {
      if (c == 'sessions') continue; // nested under gymguru_users in the rules
      expect(rules, contains('match /$c/'), reason: 'no rules for $c');
    }
  });
}
