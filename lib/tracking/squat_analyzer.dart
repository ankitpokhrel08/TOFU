import 'dart:math' as math;

import 'pose.dart';

/// Form problems the squat analyzer can flag.
enum FormIssue { kneesIn, shallow }

/// A completed rep and the issue it had, if any.
class RepEvent {
  const RepEvent(this.issue);
  final FormIssue? issue;
}

const _legJoints = [
  Joint.leftHip,
  Joint.rightHip,
  Joint.leftKnee,
  Joint.rightKnee,
  Joint.leftAnkle,
  Joint.rightAnkle,
];

const _frameJoints = [Joint.leftShoulder, Joint.rightShoulder, ..._legJoints];

/// Checks the user is set up well enough to track: whole body visible,
/// confident landmarks, and the phone (and body) held still.
class SetupChecker {
  static const minConfidence = .5;
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
    final inFrame = bodyInFrame(pose);
    final clear =
        inFrame &&
        _frameJoints.map((j) => pose[j]!.confidence).reduce((a, b) => a + b) /
                _frameJoints.length >=
            clearConfidence;

    if (inFrame) {
      final hipY = (pose[Joint.leftHip]!.y + pose[Joint.rightHip]!.y) / 2;
      _hipHistory.add(hipY / pose.imageSize.height);
      if (_hipHistory.length > _steadyFrames) _hipHistory.removeAt(0);
    } else {
      _hipHistory.clear();
    }
    final steady =
        _hipHistory.length == _steadyFrames &&
        _hipHistory.reduce(math.max) - _hipHistory.reduce(math.min) < _steadyTolerance;
    return [inFrame, clear, steady];
  }

  static bool bodyInFrame(PoseSnapshot pose) {
    final w = pose.imageSize.width, h = pose.imageSize.height;
    for (final j in _frameJoints) {
      final p = pose[j];
      if (p == null || p.confidence < minConfidence) return false;
      if (p.x < w * _edge || p.x > w * (1 - _edge)) return false;
      if (p.y < h * _edge || p.y > h * (1 - _edge)) return false;
    }
    return true;
  }
}

/// Counts squat reps from pose frames and flags form issues.
///
/// Depth is how far the hips have dropped toward knee height, measured as
/// the vertical hip-to-knee gap relative to shin length and calibrated to
/// the user's standing pose. Unlike the 2D knee angle, this works whether
/// the user faces the camera or stands side-on. 0 = standing, 1 = hips at
/// knee height.
///
/// A rep starts when depth passes [downDepth] and ends when it drops back
/// below [standDepth]. It is "shallow" if depth never reached [goodDepth],
/// and "knees in" if the knees came much closer together than the ankles
/// (only judged when facing the camera).
class SquatAnalyzer {
  static const downDepth = .3;
  static const standDepth = .12;
  static const goodDepth = .8;

  /// Knee gap ÷ ankle gap below this counts as knees caving in.
  static const kneeRatioMin = .75;

  /// Smoothing factor for depth (higher = more responsive).
  static const _smoothing = .5;

  /// Standing thigh-drop ÷ shin ratio, learned from the tallest frames.
  double? _standingRatio;
  double? _depth;
  bool _down = false;
  double _maxDepth = 0;
  bool _kneesIn = false;

  /// 0 when standing, about 1 with hips at knee height.
  double get depth => (_depth ?? 0).clamp(0.0, 1.0);

  /// Issue to show right now, while the rep is in progress.
  FormIssue? get liveIssue {
    if (!_down) return null;
    if (_kneesIn) return FormIssue.kneesIn;
    // Coming back up without having reached depth.
    if (_maxDepth < goodDepth && (_depth ?? 0) < _maxDepth - .1) return FormIssue.shallow;
    return null;
  }

  bool get inRep => _down;

  void reset() {
    _standingRatio = null;
    _depth = null;
    _down = false;
    _maxDepth = 0;
    _kneesIn = false;
  }

  /// Feed one frame. Returns a [RepEvent] when a rep completes.
  RepEvent? update(PoseSnapshot pose) {
    final ratio = _dropRatio(pose);
    if (ratio == null) return null;
    // Standing is the tallest pose seen; only learn it while not mid-rep.
    if (!_down && (_standingRatio == null || ratio > _standingRatio!)) _standingRatio = ratio;
    final standing = _standingRatio!;
    if (standing <= 0) return null;
    final raw = 1 - ratio / standing;
    _depth = _depth == null ? raw : _depth! + (raw - _depth!) * _smoothing;
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
      if (h == null || k == null || a == null) return null;
      if (math.min(h.confidence, math.min(k.confidence, a.confidence)) <
          SetupChecker.minConfidence) {
        return null;
      }
      final shin = (a.offset - k.offset).distance;
      if (shin < 1) return null;
      return (k.y - h.y) / shin;
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
    if ([lk, rk, la, ra, lh, rh].any((j) => j == null)) return false;
    final ankleGap = (la!.x - ra!.x).abs();
    final hipGap = (lh!.x - rh!.x).abs();
    // Side-on to the camera the gaps collapse and the ratio is meaningless.
    if (ankleGap < hipGap * .6) return false;
    return (lk!.x - rk!.x).abs() / ankleGap < kneeRatioMin;
  }
}
