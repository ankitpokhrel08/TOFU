import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:gym_guru/tracking/pose.dart';
import 'package:gym_guru/tracking/squat_analyzer.dart';

const _image = Size(480, 800);

/// Front-facing body. [depth] 0 = standing, 1 = hips at knee height.
/// [kneeGap] is the knee spacing (ankles are 120px apart).
PoseSnapshot body({double depth = 0, double kneeGap = 110, double confidence = .95}) {
  const kneeY = 560.0, ankleY = 700.0, shin = ankleY - kneeY;
  final hipY = kneeY - shin * 1.1 * (1 - depth);
  PosePoint p(double x, double y) => PosePoint(x, y, confidence);
  return PoseSnapshot({
    Joint.nose: p(240, hipY - 260),
    Joint.leftShoulder: p(190, hipY - 200),
    Joint.rightShoulder: p(290, hipY - 200),
    Joint.leftHip: p(200, hipY),
    Joint.rightHip: p(280, hipY),
    Joint.leftKnee: p(240 - kneeGap / 2, kneeY),
    Joint.rightKnee: p(240 + kneeGap / 2, kneeY),
    Joint.leftAnkle: p(180, ankleY),
    Joint.rightAnkle: p(300, ankleY),
  }, _image);
}

/// Runs one rep down to [bottom] and back, returning any completed reps.
List<RepEvent> rep(SquatAnalyzer a, {double bottom = 1, double kneeGap = 110}) {
  final events = <RepEvent>[];
  const steps = [0.0, .3, .6, .9, 1.0, 1.0, .9, .6, .3, 0.0, 0.0, 0.0];
  for (final s in steps) {
    final d = s * bottom;
    // Knees only cave near the bottom.
    final e = a.update(body(depth: d, kneeGap: d > .5 ? kneeGap : 110));
    if (e != null) events.add(e);
  }
  return events;
}

void main() {
  group('SquatAnalyzer', () {
    late SquatAnalyzer a;
    setUp(() {
      a = SquatAnalyzer();
      for (var i = 0; i < 3; i++) {
        a.update(body());
      }
    });

    test('standing produces no reps and zero depth', () {
      for (var i = 0; i < 20; i++) {
        expect(a.update(body()), isNull);
      }
      expect(a.depth, closeTo(0, .01));
    });

    test('a full-depth squat is one clean rep', () {
      final events = rep(a);
      expect(events, hasLength(1));
      expect(events.single.issue, isNull);
    });

    test('counts consecutive reps', () {
      final events = [for (var i = 0; i < 5; i++) ...rep(a)];
      expect(events, hasLength(5));
    });

    test('a half squat is flagged shallow', () {
      final events = rep(a, bottom: .5);
      expect(events.single.issue, FormIssue.shallow);
    });

    test('knees collapsing inward is flagged', () {
      final events = rep(a, kneeGap: 60);
      expect(events.single.issue, FormIssue.kneesIn);
    });

    test('small wobbles while standing are ignored', () {
      for (final d in [.05, .1, .15, .1, .05, 0.0]) {
        expect(a.update(body(depth: d)), isNull);
      }
    });

    test('depth tracks the squat', () {
      for (var i = 0; i < 6; i++) {
        a.update(body(depth: 1));
      }
      expect(a.depth, greaterThan(.9));
      expect(a.inRep, isTrue);
    });
  });

  group('SetupChecker', () {
    test('passes once the whole body is visible and still', () {
      final c = SetupChecker();
      List<bool> last = const [];
      for (var i = 0; i < 12; i++) {
        last = c.update(body());
      }
      expect(last, [true, true, true]);
    });

    test('fails with no body or a cropped body', () {
      final c = SetupChecker();
      expect(c.update(null), [false, false, false]);
      final cropped = PoseSnapshot({...body().points}..remove(Joint.leftAnkle), _image);
      expect(c.update(cropped).first, isFalse);
    });

    test('low-confidence landmarks fail the clear-view check', () {
      final c = SetupChecker();
      expect(c.update(body(confidence: .6))[1], isFalse);
    });

    test('moving body is not steady', () {
      final c = SetupChecker();
      List<bool> last = const [];
      for (var i = 0; i < 12; i++) {
        last = c.update(body(depth: i.isEven ? 0 : .3));
      }
      expect(last[2], isFalse);
    });
  });
}
