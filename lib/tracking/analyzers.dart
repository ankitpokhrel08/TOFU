import 'dart:math' as math;

import '../game/exercises.dart';
import 'pose.dart';

/// A completed rep (or hold segment) and the issue it had, if any.
class RepEvent {
  const RepEvent(this.issue);
  final FormIssue? issue;
}

/// Turns pose frames into graded reps for one exercise.
abstract class ExerciseAnalyzer {
  /// Feed one frame at time [t] since the set started. Returns a
  /// [RepEvent] when a rep (or 5-second hold segment) completes.
  RepEvent? update(PoseSnapshot pose, Duration t);

  /// 0–1 movement progress for the UI (depth, lift, hold segment).
  double get progress;

  /// Issue to show right now.
  FormIssue? get liveIssue;

  /// False when the body isn't in this exercise's position (e.g. not
  /// horizontal for a plank), so the UI can prompt the user.
  bool get inPosition => true;

  void reset();
}

ExerciseAnalyzer analyzerFor(Exercise e, Set<Limitation> limits) => switch (e) {
  Exercise.squat => SquatAnalyzer(goodDepth: limits.contains(Limitation.knees) ? .65 : .8),
  Exercise.pushUp => PushUpAnalyzer(),
  Exercise.plank => PlankAnalyzer(),
  Exercise.reverseLunge => LungeAnalyzer(),
  Exercise.gluteBridge => GluteBridgeAnalyzer(),
  Exercise.jumpingJack => JumpingJackAnalyzer(),
};

const _minConfidence = .5;

bool _ok(PosePoint? p) => p != null && p.confidence >= _minConfidence;

/// One side of the body (left or right), whichever the camera sees best.
class _Side {
  const _Side(this.shoulder, this.elbow, this.wrist, this.hip, this.knee, this.ankle);
  final PosePoint? shoulder, elbow, wrist, hip, knee, ankle;
}

_Side _bestSide(PoseSnapshot p) {
  _Side side(bool left) => left
      ? _Side(
          p[Joint.leftShoulder],
          p[Joint.leftElbow],
          p[Joint.leftWrist],
          p[Joint.leftHip],
          p[Joint.leftKnee],
          p[Joint.leftAnkle],
        )
      : _Side(
          p[Joint.rightShoulder],
          p[Joint.rightElbow],
          p[Joint.rightWrist],
          p[Joint.rightHip],
          p[Joint.rightKnee],
          p[Joint.rightAnkle],
        );
  double score(_Side s) => [
    s.shoulder,
    s.elbow,
    s.wrist,
    s.hip,
    s.knee,
    s.ankle,
  ].fold(0.0, (sum, j) => sum + (j?.confidence ?? 0));
  final l = side(true), r = side(false);
  return score(l) >= score(r) ? l : r;
}

/// How far [hip] sits below (+) or above (−) the shoulder→ankle line,
/// as a fraction of that line's length.
double _hipOffset(PosePoint shoulder, PosePoint hip, PosePoint ankle) {
  final dx = ankle.x - shoulder.x;
  final len = (ankle.offset - shoulder.offset).distance;
  if (len < 1 || dx.abs() < 1) return 0;
  final lineY = shoulder.y + (ankle.y - shoulder.y) * (hip.x - shoulder.x) / dx;
  return (hip.y - lineY) / len;
}

/// Body roughly horizontal, as in a plank or push-up.
bool _horizontal(PosePoint shoulder, PosePoint ankle) =>
    (ankle.y - shoulder.y).abs() < (ankle.x - shoulder.x).abs() * .6;

double _smooth(double? prev, double raw, [double k = .5]) =>
    prev == null ? raw : prev + (raw - prev) * k;

/// Setup checks: whole body visible, confident landmarks, and still.
class SetupChecker {
  SetupChecker({this.view = CameraView.front});

  final CameraView view;

  static const clearConfidence = .8;
  static const _edge = .02;
  static const _steadyFrames = 10;
  static const _steadyTolerance = .015;

  final _hipHistory = <double>[];

  /// [whole body in frame, clear view, steady].
  List<bool> update(PoseSnapshot? pose) {
    if (pose == null) {
      _hipHistory.clear();
      return const [false, false, false];
    }
    final joints = _frameJoints(pose, view);
    final inFrame = joints != null && _inside(pose, joints);
    final clear =
        inFrame &&
        joints.map((j) => pose[j]!.confidence).reduce((a, b) => a + b) / joints.length >=
            clearConfidence;

    if (inFrame) {
      final hips = [pose[Joint.leftHip], pose[Joint.rightHip]].where(_ok).toList();
      final y = hips.fold(0.0, (s, h) => s + h!.y) / hips.length;
      _hipHistory.add(y / pose.imageSize.height);
      if (_hipHistory.length > _steadyFrames) _hipHistory.removeAt(0);
    } else {
      _hipHistory.clear();
    }
    final steady =
        _hipHistory.length == _steadyFrames &&
        _hipHistory.reduce(math.max) - _hipHistory.reduce(math.min) < _steadyTolerance;
    return [inFrame, clear, steady];
  }

  /// Whether enough of the body is visible to track [view] exercises.
  static bool bodyInFrame(PoseSnapshot pose, [CameraView view = CameraView.front]) {
    final joints = _frameJoints(pose, view);
    return joints != null && _inside(pose, joints);
  }

  static const _left = [Joint.leftShoulder, Joint.leftHip, Joint.leftKnee, Joint.leftAnkle];
  static const _right = [Joint.rightShoulder, Joint.rightHip, Joint.rightKnee, Joint.rightAnkle];

  /// Joints that must be visible: both sides facing the camera, or the
  /// nearer side when side-on (the far side is often hidden).
  static List<Joint>? _frameJoints(PoseSnapshot p, CameraView view) {
    bool all(List<Joint> js) => js.every((j) => _ok(p[j]));
    if (view == CameraView.front) return all(_left) && all(_right) ? [..._left, ..._right] : null;
    if (all(_left)) return _left;
    if (all(_right)) return _right;
    return null;
  }

  /// A real person 2–3 m away spans a good part of the frame. Anything
  /// smaller is a false detection (a poster, a ceiling fan) or too far away.
  static const minBodySpan = .15;

  static bool _inside(PoseSnapshot p, List<Joint> joints) {
    final w = p.imageSize.width, h = p.imageSize.height;
    final xs = joints.map((j) => p[j]!.x), ys = joints.map((j) => p[j]!.y);
    final spanX = (xs.reduce(math.max) - xs.reduce(math.min)) / w;
    final spanY = (ys.reduce(math.max) - ys.reduce(math.min)) / h;
    if (math.max(spanX, spanY) < minBodySpan) return false;
    return joints.every((j) {
      final q = p[j]!;
      return q.x >= w * _edge &&
          q.x <= w * (1 - _edge) &&
          q.y >= h * _edge &&
          q.y <= h * (1 - _edge);
    });
  }
}

/// Squats, from the front or side.
///
/// Depth is how far the hips have dropped toward knee height: the vertical
/// hip-to-knee gap relative to shin length, calibrated to the standing
/// pose. Unlike the 2D knee angle, this works facing the camera. 0 =
/// standing, 1 = hips at knee height.
class SquatAnalyzer implements ExerciseAnalyzer {
  SquatAnalyzer({this.goodDepth = .8});

  static const downDepth = .3;
  static const standDepth = .12;

  /// Depth a rep must reach to count as full (lower with knee limitations).
  final double goodDepth;

  /// Knee gap ÷ ankle gap below this counts as knees caving in.
  static const kneeRatioMin = .75;

  double? _standingRatio;
  double? _depth;
  bool _down = false;
  double _maxDepth = 0;
  bool _kneesIn = false;

  double get depth => (_depth ?? 0).clamp(0.0, 1.0);

  @override
  double get progress => depth;

  @override
  bool get inPosition => true;

  @override
  FormIssue? get liveIssue {
    if (!_down) return null;
    if (_kneesIn) return FormIssue.kneesIn;
    // Coming back up without having reached depth.
    if (_maxDepth < goodDepth && (_depth ?? 0) < _maxDepth - .1) return FormIssue.shallow;
    return null;
  }

  bool get inRep => _down;

  @override
  void reset() {
    _standingRatio = null;
    _depth = null;
    _down = false;
    _maxDepth = 0;
    _kneesIn = false;
  }

  @override
  RepEvent? update(PoseSnapshot pose, [Duration t = Duration.zero]) {
    final ratio = _dropRatio(pose);
    if (ratio == null) return null;
    // Standing is the tallest pose seen; only learn it between reps.
    if (!_down && (_standingRatio == null || ratio > _standingRatio!)) _standingRatio = ratio;
    final standing = _standingRatio!;
    if (standing <= 0) return null;
    _depth = _smooth(_depth, 1 - ratio / standing);
    final d = _depth!;

    if (!_down) {
      if (d > downDepth) {
        _down = true;
        _maxDepth = d;
        _kneesIn = _kneesCaving(pose);
      }
      return null;
    }

    _maxDepth = math.max(_maxDepth, d);
    if (d > downDepth && _kneesCaving(pose)) _kneesIn = true;

    if (d < standDepth) {
      final issue = _kneesIn
          ? FormIssue.kneesIn
          : _maxDepth < goodDepth
          ? FormIssue.shallow
          : null;
      _down = false;
      _kneesIn = false;
      _maxDepth = 0;
      return RepEvent(issue);
    }
    return null;
  }

  /// Vertical hip-above-knee gap ÷ shin length, averaged over visible sides.
  static double? _dropRatio(PoseSnapshot p) {
    double? side(Joint hip, Joint knee, Joint ankle) {
      final h = p[hip], k = p[knee], a = p[ankle];
      if (!_ok(h) || !_ok(k) || !_ok(a)) return null;
      final shin = (a!.offset - k!.offset).distance;
      if (shin < 1) return null;
      return (k.y - h!.y) / shin;
    }

    final l = side(Joint.leftHip, Joint.leftKnee, Joint.leftAnkle);
    final r = side(Joint.rightHip, Joint.rightKnee, Joint.rightAnkle);
    if (l != null && r != null) return (l + r) / 2;
    return l ?? r;
  }

  static bool _kneesCaving(PoseSnapshot p) {
    final lk = p[Joint.leftKnee], rk = p[Joint.rightKnee];
    final la = p[Joint.leftAnkle], ra = p[Joint.rightAnkle];
    final lh = p[Joint.leftHip], rh = p[Joint.rightHip];
    // Both legs must be clearly seen; side-on, the far leg is guesswork.
    if (![lk, rk, la, ra, lh, rh].every(_ok)) return false;
    final ankleGap = (la!.x - ra!.x).abs();
    final hipGap = (lh!.x - rh!.x).abs();
    // Side-on to the camera the gaps collapse and the ratio is meaningless.
    if (ankleGap < hipGap * .6) return false;
    return (lk!.x - rk!.x).abs() / ankleGap < kneeRatioMin;
  }
}

/// Push-ups, side-on. Reps from the elbow angle; checks range and a
/// straight body line.
class PushUpAnalyzer implements ExerciseAnalyzer {
  static const downAngle = 120.0;
  static const upAngle = 155.0;

  /// Full depth. Generous because 2D elbow angles read wider when the
  /// camera isn't exactly side-on.
  static const fullAngle = 105.0;
  static const sagLimit = .08;
  static const pikeLimit = -.10;

  double? _elbow;
  double _offset = 0;
  bool _ready = false;
  bool _down = false;
  double _minElbow = 180;
  FormIssue? _lineIssue;
  bool _inPosition = false;

  @override
  bool get inPosition => _inPosition;

  @override
  double get progress => ((165 - (_elbow ?? 165)) / (165 - 80)).clamp(0.0, 1.0);

  FormIssue? get _currentLine => _offset > sagLimit
      ? FormIssue.hipSag
      : _offset < pikeLimit
      ? FormIssue.hipPike
      : null;

  @override
  FormIssue? get liveIssue {
    if (!_inPosition) return null;
    final line = _currentLine;
    if (line != null) return line;
    if (_down && _minElbow > fullAngle && (_elbow ?? 180) > _minElbow + 8) return FormIssue.halfRep;
    return null;
  }

  @override
  void reset() {
    _elbow = null;
    _offset = 0;
    _ready = false;
    _down = false;
    _minElbow = 180;
    _lineIssue = null;
    _inPosition = false;
  }

  @override
  RepEvent? update(PoseSnapshot pose, Duration t) {
    final s = _bestSide(pose);
    if (![s.shoulder, s.elbow, s.wrist, s.hip, s.ankle].every(_ok)) return null;
    _inPosition = _horizontal(s.shoulder!, s.ankle!);
    if (!_inPosition) return null;
    _elbow = _smooth(_elbow, jointAngle(s.shoulder!, s.elbow!, s.wrist!));
    _offset = _hipOffset(s.shoulder!, s.hip!, s.ankle!);
    // Only count reps that start from the top, never a half-finished one.
    if (!_ready) {
      _ready = _elbow! > upAngle;
      return null;
    }

    if (!_down) {
      if (_elbow! < downAngle) {
        _down = true;
        _minElbow = _elbow!;
        _lineIssue = _currentLine;
      }
      return null;
    }
    _minElbow = math.min(_minElbow, _elbow!);
    _lineIssue ??= _currentLine;
    if (_elbow! > upAngle) {
      final issue = _lineIssue ?? (_minElbow > fullAngle ? FormIssue.halfRep : null);
      _down = false;
      _lineIssue = null;
      _minElbow = 180;
      return RepEvent(issue);
    }
    return null;
  }
}

/// Plank hold, side-on. Time only counts while in a plank; each 5-second
/// segment is graded on body line.
class PlankAnalyzer implements ExerciseAnalyzer {
  static const sagLimit = .08;
  static const pikeLimit = -.10;
  static const kneelLimit = .12;

  Duration? _last;
  double _segment = 0;
  FormIssue? _segmentIssue;
  FormIssue? _live;
  bool _inPosition = false;

  @override
  bool get inPosition => _inPosition;

  @override
  double get progress => (_segment / Exercise.holdSegment).clamp(0.0, 1.0);

  @override
  FormIssue? get liveIssue => _live;

  @override
  void reset() {
    _last = null;
    _segment = 0;
    _segmentIssue = null;
    _live = null;
    _inPosition = false;
  }

  @override
  RepEvent? update(PoseSnapshot pose, Duration t) {
    final s = _bestSide(pose);
    final prev = _last;
    _last = t;
    if (![s.shoulder, s.hip, s.ankle].every(_ok)) {
      _inPosition = false;
      return null;
    }
    _inPosition = _horizontal(s.shoulder!, s.ankle!);
    if (!_inPosition) {
      _live = null;
      return null;
    }
    // Knees on the floor (well below the body line) means resting, not planking.
    if (_ok(s.knee) && _hipOffset(s.shoulder!, s.knee!, s.ankle!) > kneelLimit) {
      _inPosition = false;
      _live = null;
      return null;
    }
    final off = _hipOffset(s.shoulder!, s.hip!, s.ankle!);
    _live = off > sagLimit
        ? FormIssue.hipSag
        : off < pikeLimit
        ? FormIssue.hipPike
        : null;
    _segmentIssue ??= _live;
    if (prev == null) return null;
    // Cap gaps (dropped frames, pauses) so time can't jump.
    final dt = math.min((t - prev).inMilliseconds, 500) / 1000;
    _segment += dt;
    if (_segment >= Exercise.holdSegment) {
      _segment -= Exercise.holdSegment;
      final issue = _segmentIssue;
      _segmentIssue = null;
      return RepEvent(issue);
    }
    return null;
  }
}

/// Reverse lunges, side-on. Reps from the bent-knee angle; checks depth and
/// an upright torso.
class LungeAnalyzer implements ExerciseAnalyzer {
  static const downAngle = 135.0;
  static const upAngle = 160.0;
  static const fullAngle = 105.0;
  static const maxLean = 25.0;

  double? _knee;
  bool _ready = false;
  bool _down = false;
  double _minKnee = 180;
  bool _leaned = false;

  @override
  bool get inPosition => true;

  @override
  double get progress => ((170 - (_knee ?? 170)) / (170 - 90)).clamp(0.0, 1.0);

  @override
  FormIssue? get liveIssue {
    if (!_down) return null;
    if (_leaned) return FormIssue.torsoLean;
    if (_minKnee > fullAngle && (_knee ?? 180) > _minKnee + 8) return FormIssue.lungeShallow;
    return null;
  }

  @override
  void reset() {
    _knee = null;
    _ready = false;
    _down = false;
    _minKnee = 180;
    _leaned = false;
  }

  @override
  RepEvent? update(PoseSnapshot p, Duration t) {
    double? angle(Joint h, Joint k, Joint a) =>
        _ok(p[h]) && _ok(p[k]) && _ok(p[a]) ? jointAngle(p[h]!, p[k]!, p[a]!) : null;
    final l = angle(Joint.leftHip, Joint.leftKnee, Joint.leftAnkle);
    final r = angle(Joint.rightHip, Joint.rightKnee, Joint.rightAnkle);
    if (l == null && r == null) return null;
    // The front (most bent) knee drives the rep.
    _knee = _smooth(_knee, math.min(l ?? 180, r ?? 180));
    final s = _bestSide(p);
    final lean = _ok(s.shoulder) && _ok(s.hip)
        ? math.atan2((s.shoulder!.x - s.hip!.x).abs(), (s.hip!.y - s.shoulder!.y).abs()) *
              180 /
              math.pi
        : 0.0;
    if (!_ready) {
      _ready = _knee! > upAngle;
      return null;
    }

    if (!_down) {
      if (_knee! < downAngle) {
        _down = true;
        _minKnee = _knee!;
        _leaned = lean > maxLean;
      }
      return null;
    }
    _minKnee = math.min(_minKnee, _knee!);
    if (_knee! < downAngle && lean > maxLean) _leaned = true;
    if (_knee! > upAngle) {
      final issue = _leaned
          ? FormIssue.torsoLean
          : _minKnee > fullAngle
          ? FormIssue.lungeShallow
          : null;
      _down = false;
      _leaned = false;
      _minKnee = 180;
      return RepEvent(issue);
    }
    return null;
  }
}

/// Glute bridges, lying on the back, side-on. Reps from the hip angle
/// (shoulder–hip–knee); a full rep straightens the hips.
class GluteBridgeAnalyzer implements ExerciseAnalyzer {
  static const lowAngle = 145.0;
  static const upAngle = 155.0;
  static const fullAngle = 165.0;

  double? _hip;
  bool _ready = false;
  bool _up = false;
  double _maxHip = 0;

  @override
  bool get inPosition => true;

  @override
  double get progress => (((_hip ?? 120) - 120) / (175 - 120)).clamp(0.0, 1.0);

  @override
  FormIssue? get liveIssue =>
      _up && _maxHip < fullAngle && (_hip ?? 0) < _maxHip - 6 ? FormIssue.lowBridge : null;

  @override
  void reset() {
    _hip = null;
    _ready = false;
    _up = false;
    _maxHip = 0;
  }

  @override
  RepEvent? update(PoseSnapshot p, Duration t) {
    final s = _bestSide(p);
    if (![s.shoulder, s.hip, s.knee].every(_ok)) return null;
    _hip = _smooth(_hip, jointAngle(s.shoulder!, s.hip!, s.knee!));
    // Start counting once the hips have been down.
    if (!_ready) {
      _ready = _hip! < lowAngle;
      return null;
    }
    if (!_up) {
      if (_hip! > upAngle) {
        _up = true;
        _maxHip = _hip!;
      }
      return null;
    }
    _maxHip = math.max(_maxHip, _hip!);
    if (_hip! < lowAngle) {
      final issue = _maxHip < fullAngle ? FormIssue.lowBridge : null;
      _up = false;
      _maxHip = 0;
      return RepEvent(issue);
    }
    return null;
  }
}

/// Jumping jacks, facing the camera. A rep is closed → open → closed; it's
/// full range only if both the arms went overhead and the feet went wide.
class JumpingJackAnalyzer implements ExerciseAnalyzer {
  static const wideLegs = 1.6;
  static const closedLegs = 1.3;

  bool _open = false;
  bool _sawArms = false;
  bool _sawLegs = false;
  double _spread = 0;

  @override
  bool get inPosition => true;

  @override
  double get progress => _spread;

  @override
  FormIssue? get liveIssue => null;

  @override
  void reset() {
    _open = false;
    _sawArms = false;
    _sawLegs = false;
    _spread = 0;
  }

  @override
  RepEvent? update(PoseSnapshot p, Duration t) {
    final need = [
      Joint.nose,
      Joint.leftShoulder,
      Joint.rightShoulder,
      Joint.leftWrist,
      Joint.rightWrist,
      Joint.leftHip,
      Joint.rightHip,
      Joint.leftAnkle,
      Joint.rightAnkle,
    ];
    if (!need.every((j) => _ok(p[j]))) return null;
    final hipGap = (p[Joint.leftHip]!.x - p[Joint.rightHip]!.x).abs();
    if (hipGap < 1) return null;
    final legs = (p[Joint.leftAnkle]!.x - p[Joint.rightAnkle]!.x).abs() / hipGap;
    final nose = p[Joint.nose]!.y;
    final armsUp = p[Joint.leftWrist]!.y < nose && p[Joint.rightWrist]!.y < nose;
    final shoulderY = (p[Joint.leftShoulder]!.y + p[Joint.rightShoulder]!.y) / 2;
    final armsDown = p[Joint.leftWrist]!.y > shoulderY && p[Joint.rightWrist]!.y > shoulderY;
    final legsWide = legs > wideLegs;
    _spread = ((legs - 1) / (wideLegs + .2 - 1)).clamp(0.0, 1.0);

    if (!_open) {
      if (armsUp || legsWide) {
        _open = true;
        _sawArms = armsUp;
        _sawLegs = legsWide;
      }
      return null;
    }
    _sawArms |= armsUp;
    _sawLegs |= legsWide;
    if (armsDown && legs < closedLegs) {
      final issue = _sawArms && _sawLegs ? null : FormIssue.shortRange;
      _open = false;
      return RepEvent(issue);
    }
    return null;
  }
}
