import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gym_guru/main.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('welcome screen advances to goals', (tester) async {
    await tester.pumpWidget(const GymGuruApp());
    expect(find.text("Let's get started"), findsOneWidget);

    await tester.tap(find.text("Let's get started"));
    await tester.pumpAndSettle();
    expect(find.text('What should we work on?'), findsOneWidget);
    expect(find.text('2/10'), findsOneWidget);
  });
}
