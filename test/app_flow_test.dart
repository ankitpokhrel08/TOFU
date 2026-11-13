import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gym_guru/app/main_shell.dart';
import 'package:gym_guru/data/progress_store.dart';
import 'package:gym_guru/main.dart';
import 'package:gym_guru/onboarding/onboarding_controller.dart';
import 'package:gym_guru/onboarding/screens/paywall_screen.dart';
import 'package:gym_guru/tracking/simulated_tracker.dart';

import 'helpers.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text));
    await tester.tap(find.text(text));
    await tester.pump();
  }

  void usePhoneSize(WidgetTester tester) {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  group('paywall CTA', () {
    late List<String> calls;

    Future<OnboardingController> pumpPaywall(WidgetTester tester) async {
      calls = [];
      final c = OnboardingController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaywallScreen(
              c: c,
              nav: FlowNav(
                next: () => calls.add('next'),
                back: () => calls.add('back'),
                enterApp: () => calls.add('app'),
              ),
            ),
          ),
        ),
      );
      return c;
    }

    testWidgets('annual starts the trial and enters the app', (tester) async {
      await pumpPaywall(tester);
      await tapText(tester, 'Start my 7-day free trial');
      expect(calls, ['app']);
    });

    testWidgets('monthly continues to the success screen', (tester) async {
      final c = await pumpPaywall(tester);
      c.setPlan(Plan.monthly);
      await tester.pump();
      await tapText(tester, 'Continue with Monthly');
      expect(calls, ['next']);
    });
  });

  testWidgets('returning users skip onboarding', (tester) async {
    final store = await tester.runAsync(() => makeStore(profile: testProfile()));
    await tester.pumpWidget(GymGuruApp(store: store!));
    await tester.pump();
    expect(find.text("Let's get started"), findsNothing);
    expect(find.text('Start lesson'), findsOneWidget);
    expect(find.textContaining('Strength Foundations'), findsOneWidget);
  });

  testWidgets('a full lesson is saved and updates the app', (tester) async {
    usePhoneSize(tester);
    final store = (await tester.runAsync(() => makeStore(profile: testProfile())))!;

    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        home: MainShell(store: store, trackerFactory: SimulatedTracker.new),
      ),
    );
    expect(find.bySemanticsLabel('0 day streak'), findsOneWidget);
    expect(find.text('Hip hinge'), findsOneWidget);

    await tapText(tester, 'Start lesson');
    await tester.pumpAndSettle();
    await tapText(tester, 'Got it, open camera');
    await tester.pumpAndSettle();
    expect(find.text('DEMO'), findsOneWidget);

    // Setup (~2.7s) + countdown (~2.7s) + 12 reps × 2.4s.
    for (var i = 0; i < 140; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
    await tester.pumpAndSettle();

    expect(find.text('LESSON COMPLETE'), findsOneWidget);
    expect(find.text('Knees caved in'), findsOneWidget);
    expect(find.text('Too shallow'), findsOneWidget);
    expect(find.text('1-day streak!'), findsOneWidget);

    await tapText(tester, 'Continue');
    await tester.pumpAndSettle();
    expect(find.text('Streak safe. Rest up!'), findsOneWidget);
    expect(find.text('Squat depth unlocks tomorrow'), findsOneWidget);
    expect(find.bySemanticsLabel('1 day streak'), findsOneWidget);
    semantics.dispose();

    // Persisted: a fresh store sees the session.
    final reopened = (await tester.runAsync(ProgressStore.open))!;
    expect(reopened.sessions, hasLength(1));
    expect(reopened.sessions.single.errors, hasLength(2));
  });
}
