import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gym_guru/app/app_controller.dart';
import 'package:gym_guru/app_root.dart';
import 'package:gym_guru/data/auth.dart';
import 'package:gym_guru/theme/app_theme.dart';
import 'package:gym_guru/tracking/simulated_tracker.dart';

import 'helpers.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  late Map<String, MemoryRepository> repos;
  late Map<String, LeaderboardEntry> board;

  setUp(() {
    board = {};
    repos = {};
  });

  MemoryRepository repoFor(String uid) =>
      repos.putIfAbsent(uid, () => MemoryRepository(uid, board: board));

  Future<void> pumpApp(WidgetTester tester, FakeAuth auth) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        home: AppRoot(
          auth: auth,
          repositoryFor: repoFor,
          // Scripted reps standing in for a real camera.
          trackerFactory: (b, l) => SimulatedTracker(b, limits: l, demo: false),
          clock: () => DateTime(2026, 11, 12, 9),
        ),
      ),
    );
    await settle(tester);
  }

  testWidgets('new user signs in, sets up a profile and lands on Today', (tester) async {
    final auth = FakeAuth();
    await pumpApp(tester, auth);
    expect(find.text('Continue with Google'), findsOneWidget);

    await tap(tester, 'Continue with Google');
    expect(find.text("Hey, I'm Guru! What should I call you?"), findsOneWidget);
    // Prefilled from the Google account.
    expect(find.widgetWithText(TextField, 'Sam'), findsNWidgets(2));

    await tap(tester, 'Continue'); // name
    await tap(tester, 'Lose fat');
    await tap(tester, 'Continue'); // goal
    await tap(tester, 'Intermediate');
    await tap(tester, 'Continue'); // time + experience
    await tap(tester, 'Knees');
    await tap(tester, 'Continue'); // limitations
    await tap(tester, 'Whoa, cool'); // form check demo
    await settle(tester, seconds: 4); // plan builds
    expect(find.text('Lvl 6'), findsOneWidget);
    await tap(tester, "Let's train");

    final p = repos['u1']!.profile!;
    expect(p.name, 'Sam');
    expect(p.goal, 'fat');
    expect(p.experience, 'intermediate');
    expect(p.limitations.map((l) => l.name), ['knees']);
    expect(find.text('Hey Sam!'), findsOneWidget);
    expect(find.text('Play level 6'), findsOneWidget);
  });

  testWidgets('returning user skips setup', (tester) async {
    repos['u1'] = MemoryRepository('u1', board: board, profile: testProfile());
    await pumpApp(tester, FakeAuth(user: const AppUser(uid: 'u1')));
    expect(find.text('Continue with Google'), findsNothing);
    expect(find.text('Play level 1'), findsOneWidget);
  });

  testWidgets('cancelling Google sign-in stays on welcome', (tester) async {
    final auth = FakeAuth()..cancelNext = true;
    await pumpApp(tester, auth);
    await tap(tester, 'Continue with Google');
    expect(find.text('Continue with Google'), findsOneWidget);
  });

  testWidgets('playing level 1 earns stars, XP and unlocks level 2', (tester) async {
    repos['u1'] = MemoryRepository('u1', board: board, profile: testProfile());
    await pumpApp(tester, FakeAuth(user: const AppUser(uid: 'u1')));

    await tap(tester, 'Play level 1');
    expect(find.text('8 squats'), findsOneWidget);
    expect(find.text('8 bridges'), findsOneWidget);
    await tap(tester, 'Start workout');
    expect(find.text('CALIBRATING'), findsOneWidget);

    // Setup + countdown + 8 squats + turn side-on + 8 bridges.
    for (var i = 0; i < 220; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
    await settle(tester);

    expect(find.text('LEVEL 1 CLEARED'), findsOneWidget);
    expect(find.text('Level 2 unlocked: Find your depth'), findsOneWidget);
    expect(find.text('Knees caved in'), findsOneWidget);
    expect(find.text('Hips not fully up'), findsOneWidget);
    final s = repos['u1']!.load();
    final session = (await tester.runAsync(() => s))!.sessions.single;
    expect(session.stars, 2); // 14 of 16 clean
    expect(session.level, 1);

    await tap(tester, 'Next: level 2');
    expect(find.text('Find your depth'), findsOneWidget);
  });

  testWidgets('leaderboard shows players and your rank', (tester) async {
    board['a'] = const LeaderboardEntry(uid: 'a', nickname: 'Alpha', xp: 900, weeklyXp: 400);
    board['b'] = const LeaderboardEntry(uid: 'b', nickname: 'Bravo', xp: 100, weeklyXp: 50);
    repos['u1'] = MemoryRepository(
      'u1',
      board: board,
      profile: testProfile(),
      sessions: [testSession(DateTime(2026, 11, 11), xp: 300)],
    );
    board['u1'] = const LeaderboardEntry(uid: 'u1', nickname: 'SamLifts', xp: 300, weeklyXp: 300);
    await pumpApp(tester, FakeAuth(user: const AppUser(uid: 'u1')));

    await tap(tester, 'Ranks');
    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('SamLifts (you)'), findsOneWidget);
    expect(find.text('#2'), findsOneWidget);
  });

  testWidgets('players with no XP are not ranked', (tester) async {
    board['a'] = const LeaderboardEntry(uid: 'a', nickname: 'Alpha', xp: 50, weeklyXp: 0);
    repos['u1'] = MemoryRepository('u1', board: board, profile: testProfile());
    await pumpApp(tester, FakeAuth(user: const AppUser(uid: 'u1')));
    await tap(tester, 'Ranks');
    expect(find.text('#1'), findsNothing);
    expect(find.text('TRAIN TO GET RANKED THIS WEEK'), findsOneWidget);
    // Zero-XP players (Alpha this week, and you) aren't listed either.
    expect(find.text('Alpha'), findsNothing);
    expect(find.textContaining('(you)'), findsNothing);
    await tap(tester, 'All time');
    expect(find.text('Alpha'), findsOneWidget); // 50 XP all-time
    expect(find.textContaining('this week'), findsNothing);
  });

  testWidgets('editing the nickname saves it and updates the leaderboard', (tester) async {
    repos['u1'] = MemoryRepository('u1', board: board, profile: testProfile());
    await pumpApp(tester, FakeAuth(user: const AppUser(uid: 'u1')));
    await tester.tap(find.bySemanticsLabel('Profile'));
    await settle(tester);
    await tap(tester, 'Leaderboard nickname');
    await tester.enterText(find.byType(TextField), 'NewName');
    await tester.pump();
    await tap(tester, 'Save');
    await settle(tester, seconds: 2);
    expect(tester.takeException(), isNull);
    expect(repos['u1']!.profile!.nickname, 'NewName');
    expect(board['u1']!.nickname, 'NewName');
  });

  testWidgets('deleting the account removes data and signs out', (tester) async {
    repos['u1'] = MemoryRepository('u1', board: board, profile: testProfile());
    board['u1'] = const LeaderboardEntry(uid: 'u1', nickname: 'SamLifts', xp: 0, weeklyXp: 0);
    await pumpApp(tester, FakeAuth(user: const AppUser(uid: 'u1')));

    await tester.tap(find.bySemanticsLabel('Profile'));
    await settle(tester);
    await tap(tester, 'Delete account');
    await tap(tester, 'Delete');

    expect(repos['u1']!.profile, isNull);
    expect(board.containsKey('u1'), isFalse);
    expect(find.text('Continue with Google'), findsOneWidget);
  });

  test('outcome types are exported for the UI', () {
    // Guards the public API the screens rely on.
    expect(WorkoutOutcome, isNotNull);
    expect(SessionKind.values, hasLength(2));
  });
}

/// Pump through animations without waiting on periodic timers.
Future<void> settle(WidgetTester tester, {int seconds = 1}) async {
  for (var i = 0; i < seconds * 4; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

Future<void> tap(WidgetTester tester, String text) async {
  final f = find.text(text).hitTestable();
  await tester.ensureVisible(f.first);
  await tester.pump();
  await tester.tap(f.first);
  await settle(tester);
}
