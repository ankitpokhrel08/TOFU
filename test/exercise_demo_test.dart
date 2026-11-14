import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_guru/game/exercises.dart';
import 'package:gym_guru/widgets/exercise_demo.dart';
import 'package:lottie/lottie.dart';

void main() {
  test('every exercise has a valid Lottie file', () async {
    for (final e in Exercise.values) {
      final file = switch (e) {
        Exercise.squat => 'squat',
        Exercise.pushUp => 'push_up',
        Exercise.plank => 'plank',
        Exercise.reverseLunge => 'reverse_lunge',
        Exercise.gluteBridge => 'glute_bridge',
        Exercise.jumpingJack => 'jumping_jack',
      };
      final bytes = await rootBundle.load('assets/exercises/$file.json');
      final comp = await LottieComposition.fromByteData(bytes);
      expect(comp.duration, greaterThan(Duration.zero), reason: file);
      // No opaque full-frame background: the clips sit on the app's own cards.
      final json = jsonDecode(utf8.decode(bytes.buffer.asUint8List())) as Map<String, dynamic>;
      final layers = [
        ...json['layers'] as List,
        for (final a in json['assets'] as List? ?? const []) ...(a['layers'] as List? ?? const []),
      ];
      expect(layers.where((l) => l['ty'] == 1), isEmpty, reason: '$file has a solid background');
    }
  });

  testWidgets('switching exercises keeps animating without errors', (tester) async {
    Widget demo(Exercise e) => MaterialApp(
      home: Scaffold(body: ExerciseDemo(exercise: e)),
    );
    for (final e in Exercise.values) {
      await tester.pumpWidget(demo(e));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull, reason: e.name);
      expect(find.bySemanticsLabel(RegExp('how to do')), findsOneWidget);
    }
  });

  testWidgets('reduced motion shows a still frame', (tester) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: MaterialApp(
          home: Scaffold(body: ExerciseDemo(exercise: Exercise.squat)),
        ),
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump();
    // Nothing keeps scheduling frames when motion is off.
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
