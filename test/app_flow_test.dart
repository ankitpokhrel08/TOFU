import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gym_guru/app/main_shell.dart';
import 'package:gym_guru/onboarding/onboarding_controller.dart';
import 'package:gym_guru/onboarding/screens/paywall_screen.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text));
    await tester.tap(find.text(text));
    await tester.pump();
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
                restart: () => calls.add('restart'),
                startTrial: () => calls.add('trial'),
              ),
            ),
          ),
        ),
      );
      return c;
    }

    testWidgets('annual starts the free trial', (tester) async {
      await pumpPaywall(tester);
      await tapText(tester, 'Start my 7-day free trial');
      expect(calls, ['trial']);
    });

    testWidgets('monthly keeps the existing next step', (tester) async {
      final c = await pumpPaywall(tester);
      c.setPlan(Plan.monthly);
      await tester.pump();
      await tapText(tester, 'Continue with Monthly');
      expect(calls, ['next']);
    });
  });

  testWidgets('a full lesson updates streak and home', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(const MaterialApp(home: MainShell()));
    expect(find.text('Hey Alex!'), findsOneWidget);
    expect(find.bySemanticsLabel('12 day streak'), findsOneWidget);

    await tapText(tester, 'Start lesson');
    await tester.pumpAndSettle();
    await tapText(tester, 'Got it, open camera');
    await tester.pumpAndSettle();
    expect(find.text('CALIBRATING'), findsOneWidget);

    // Setup (~2.7s) + countdown (~2.7s) + 12 reps × 2.4s.
    for (var i = 0; i < 140; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
    await tester.pumpAndSettle();

    expect(find.text('LESSON COMPLETE'), findsOneWidget);
    expect(find.text('Knees caved in'), findsOneWidget);
    expect(find.text('Too shallow'), findsOneWidget);
    expect(find.text('13-day streak!'), findsOneWidget);

    await tapText(tester, 'Continue');
    await tester.pumpAndSettle();
    expect(find.text('Streak safe. Rest up!'), findsOneWidget);
    expect(find.bySemanticsLabel('13 day streak'), findsOneWidget);
    semantics.dispose();
  });
}
