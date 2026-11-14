import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:gym_guru/tracking/pose.dart';
import 'package:gym_guru/game/exercises.dart';
import 'package:gym_guru/tracking/analyzers.dart';

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
  otherExercises();

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

// Side-view and other-exercise helpers.

const _side = Size(800, 480);
PosePoint _p(double x, double y) => PosePoint(x, y, .95);

/// Both sides at the same point (the far side mirrors the near one).
PoseSnapshot _both(Map<String, Offset> pts, [Size size = _side]) {
  final m = <Joint, PosePoint>{};
  for (final MapEntry(key: k, value: o) in pts.entries) {
    for (final side in ['left', 'right']) {
      final j = Joint.values.byName('$side${k[0].toUpperCase()}${k.substring(1)}');
      m[j] = _p(o.dx, o.dy);
    }
  }
  return PoseSnapshot(m, size);
}

/// Horizontal push-up/plank body. [elbow] is the elbow angle; [sag] moves
/// the hip below (+) or above (−) the shoulder–ankle line, in pixels.
PoseSnapshot plankBody({double elbow = 180, double sag = 0}) {
  const wrist = Offset(100, 440);
  // Shoulder drops as the elbow bends.
  final sy = 440 - 120 * (elbow / 180);
  final h = (wrist.dy - sy) / 2;
  final dx = elbow >= 179.9 ? 0.0 : h / math.tan(elbow / 2 * math.pi / 180);
  final shoulder = Offset(100, sy);
  const ankle = Offset(600, 430);
  final hipX = 350.0;
  final lineY =
      shoulder.dy + (ankle.dy - shoulder.dy) * (hipX - shoulder.dx) / (ankle.dx - shoulder.dx);
  return _both({
    'shoulder': shoulder,
    'elbow': Offset(100 + dx, sy + h),
    'wrist': wrist,
    'hip': Offset(hipX, lineY + sag),
    'knee': Offset(475, (lineY + sag + ankle.dy) / 2),
    'ankle': ankle,
  });
}

/// Side-on lunge with the front knee at [knee] degrees and the torso
/// leaning [lean] px forward at the shoulder.
PoseSnapshot lungeBody({double knee = 180, double lean = 0}) {
  const size = Size(480, 800);
  const hip = Offset(240, 400), ankle = Offset(240, 700);
  final dx = knee >= 179.9 ? 0.0 : 150 / math.tan(knee / 2 * math.pi / 180);
  final m = <Joint, PosePoint>{
    Joint.leftShoulder: _p(240 + lean, 200),
    Joint.rightShoulder: _p(240 + lean, 200),
    Joint.leftHip: _p(hip.dx, hip.dy),
    Joint.rightHip: _p(hip.dx, hip.dy),
    Joint.leftKnee: _p(240 + dx, 550),
    Joint.leftAnkle: _p(ankle.dx, ankle.dy),
    Joint.rightKnee: _p(240, 550),
    Joint.rightAnkle: _p(ankle.dx, ankle.dy),
  };
  return PoseSnapshot(m, size);
}

/// Lying glute bridge; [lift] 0 = hips down, 1 = straight line.
PoseSnapshot bridgeBody(double lift) {
  const shoulder = Offset(100, 400), knee = Offset(500, 330);
  final lineY = shoulder.dy + (knee.dy - shoulder.dy) * .5;
  return _both({
    'shoulder': shoulder,
    'hip': Offset(300, lineY + 110 * (1 - lift)),
    'knee': knee,
    'ankle': const Offset(560, 400),
  });
}

/// Front-facing jumping jack; [arms] and [legs] each 0 (closed) or 1 (open).
PoseSnapshot jackBody({double arms = 0, double legs = 0}) {
  const size = Size(480, 800);
  final wristY = 450 - 400 * arms;
  final ankleGap = 80 + 140 * legs;
  return PoseSnapshot({
    Joint.nose: _p(240, 120),
    Joint.leftShoulder: _p(190, 200),
    Joint.rightShoulder: _p(290, 200),
    Joint.leftWrist: _p(170 - 60 * arms, wristY),
    Joint.rightWrist: _p(310 + 60 * arms, wristY),
    Joint.leftHip: _p(200, 420),
    Joint.rightHip: _p(280, 420),
    Joint.leftKnee: _p(200 - 30 * legs, 560),
    Joint.rightKnee: _p(280 + 30 * legs, 560),
    Joint.leftAnkle: _p(240 - ankleGap / 2, 700),
    Joint.rightAnkle: _p(240 + ankleGap / 2, 700),
  }, size);
}

List<RepEvent> _run(ExerciseAnalyzer a, Iterable<PoseSnapshot> frames, {int stepMs = 100}) {
  final out = <RepEvent>[];
  var t = 0;
  for (final f in frames) {
    final e = a.update(f, Duration(milliseconds: t));
    t += stepMs;
    if (e != null) out.add(e);
  }
  return out;
}

Iterable<double> _cycle(double from, double to) sync* {
  const n = 6;
  for (var i = 0; i <= n; i++) {
    yield from + (to - from) * i / n;
  }
  for (var i = n; i >= 0; i--) {
    yield from + (to - from) * i / n;
  }
  yield from;
  yield from;
}

void otherExercises() {
  group('PushUpAnalyzer', () {
    test('a full push-up is clean', () {
      final a = PushUpAnalyzer();
      final e = _run(a, _cycle(178, 80).map((el) => plankBody(elbow: el)));
      expect(e.single.issue, isNull);
    });

    test('a half push-up is flagged', () {
      final a = PushUpAnalyzer();
      final e = _run(a, _cycle(178, 112).map((el) => plankBody(elbow: el)));
      expect(e.single.issue, FormIssue.halfRep);
    });

    test('sagging hips are flagged', () {
      final a = PushUpAnalyzer();
      final e = _run(a, _cycle(178, 80).map((el) => plankBody(elbow: el, sag: 70)));
      expect(e.single.issue, FormIssue.hipSag);
    });

    test('standing up is not a push-up position', () {
      final a = PushUpAnalyzer();
      _run(a, [for (var i = 0; i < 5; i++) lungeBody()]);
      expect(a.inPosition, isFalse);
    });
  });

  group('PlankAnalyzer', () {
    test('a good hold yields clean 5-second segments', () {
      final a = PlankAnalyzer();
      final e = _run(a, [for (var i = 0; i < 111; i++) plankBody()]);
      expect(e, hasLength(2));
      expect(e.every((r) => r.issue == null), isTrue);
    });

    test('sagging marks the segment', () {
      final a = PlankAnalyzer();
      final e = _run(a, [for (var i = 0; i < 55; i++) plankBody(sag: 70)]);
      expect(e.single.issue, FormIssue.hipSag);
      expect(a.liveIssue, FormIssue.hipSag);
    });

    test('piking is flagged', () {
      final a = PlankAnalyzer();
      final e = _run(a, [for (var i = 0; i < 55; i++) plankBody(sag: -80)]);
      expect(e.single.issue, FormIssue.hipPike);
    });

    test('time does not count while standing', () {
      final a = PlankAnalyzer();
      expect(_run(a, [for (var i = 0; i < 80; i++) lungeBody()]), isEmpty);
    });
  });

  group('LungeAnalyzer', () {
    test('a deep upright lunge is clean', () {
      final e = _run(LungeAnalyzer(), _cycle(178, 90).map((k) => lungeBody(knee: k)));
      expect(e.single.issue, isNull);
    });

    test('a shallow lunge is flagged', () {
      final e = _run(LungeAnalyzer(), _cycle(178, 125).map((k) => lungeBody(knee: k)));
      expect(e.single.issue, FormIssue.lungeShallow);
    });

    test('leaning forward is flagged', () {
      final e = _run(
        LungeAnalyzer(),
        _cycle(178, 90).map((k) => lungeBody(knee: k, lean: k < 130 ? 140 : 0)),
      );
      expect(e.single.issue, FormIssue.torsoLean);
    });
  });

  group('GluteBridgeAnalyzer', () {
    test('a full bridge is clean', () {
      final e = _run(GluteBridgeAnalyzer(), [..._cycle(0, 1).map(bridgeBody), bridgeBody(0)]);
      expect(e.single.issue, isNull);
    });

    test('a low bridge is flagged', () {
      final e = _run(GluteBridgeAnalyzer(), [..._cycle(0, .7).map(bridgeBody), bridgeBody(0)]);
      expect(e.single.issue, FormIssue.lowBridge);
    });
  });

  group('JumpingJackAnalyzer', () {
    Iterable<PoseSnapshot> jack({double arms = 1, double legs = 1}) => [
      jackBody(),
      jackBody(arms: arms / 2, legs: legs / 2),
      jackBody(arms: arms, legs: legs),
      jackBody(arms: arms, legs: legs),
      jackBody(arms: arms / 2, legs: legs / 2),
      jackBody(),
    ];

    test('full jacks count cleanly', () {
      final e = _run(JumpingJackAnalyzer(), [...jack(), ...jack(), ...jack()]);
      expect(e, hasLength(3));
      expect(e.every((r) => r.issue == null), isTrue);
    });

    test('arms-only jacks are partial', () {
      final e = _run(JumpingJackAnalyzer(), jack(legs: 0));
      expect(e.single.issue, FormIssue.shortRange);
    });
  });

  test('a tiny false detection is not a body in frame', () {
    // A full skeleton squeezed into a corner, like one found in background clutter.
    final big = lungeBody();
    final tiny = PoseSnapshot({
      for (final MapEntry(key: j, value: p) in big.points.entries)
        j: PosePoint(200 + (p.x - 240) * .1, 300 + (p.y - 400) * .1, p.confidence),
    }, big.imageSize);
    expect(SetupChecker.bodyInFrame(big, CameraView.side), isTrue);
    expect(SetupChecker.bodyInFrame(tiny, CameraView.side), isFalse);
  });

  group('SetupChecker side view', () {
    test('one full side is enough when side-on', () {
      final pose = PoseSnapshot({
        for (final MapEntry(key: j, value: p) in lungeBody().points.entries)
          if (j.name.startsWith('left') || j.name.startsWith('nose')) j: p,
      }, const Size(480, 800));
      expect(SetupChecker.bodyInFrame(pose, CameraView.side), isTrue);
      expect(SetupChecker.bodyInFrame(pose), isFalse);
    });
  });

  test('knee limitation relaxes squat depth', () {
    final a = analyzerFor(Exercise.squat, {Limitation.knees}) as SquatAnalyzer;
    expect(a.goodDepth, lessThan(SquatAnalyzer().goodDepth));
  });
}
