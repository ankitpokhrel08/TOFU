import 'dart:math' as math;
import 'dart:ui';

/// Body points used by the trackers and overlay.
enum Joint {
  nose,
  leftShoulder,
  rightShoulder,
  leftElbow,
  rightElbow,
  leftWrist,
  rightWrist,
  leftHip,
  rightHip,
  leftKnee,
  rightKnee,
  leftAnkle,
  rightAnkle,
}

/// Skeleton edges drawn by the overlay.
const skeletonBones = [
  (Joint.leftShoulder, Joint.rightShoulder),
  (Joint.leftShoulder, Joint.leftElbow),
  (Joint.leftElbow, Joint.leftWrist),
  (Joint.rightShoulder, Joint.rightElbow),
  (Joint.rightElbow, Joint.rightWrist),
  (Joint.leftShoulder, Joint.leftHip),
  (Joint.rightShoulder, Joint.rightHip),
  (Joint.leftHip, Joint.rightHip),
  (Joint.leftHip, Joint.leftKnee),
  (Joint.leftKnee, Joint.leftAnkle),
  (Joint.rightHip, Joint.rightKnee),
  (Joint.rightKnee, Joint.rightAnkle),
];

class PosePoint {
  const PosePoint(this.x, this.y, this.confidence);

  /// Pixel position in the upright, display-oriented image.
  final double x;
  final double y;

  /// Detector likelihood, 0–1.
  final double confidence;

  Offset get offset => Offset(x, y);
}

/// One detected body in a camera frame.
class PoseSnapshot {
  const PoseSnapshot(this.points, this.imageSize);

  final Map<Joint, PosePoint> points;

  /// Size of the upright image the points are measured in.
  final Size imageSize;

  PosePoint? operator [](Joint j) => points[j];
}

/// Interior angle at [b], in degrees, for the path a → b → c.
double jointAngle(PosePoint a, PosePoint b, PosePoint c) {
  final v1x = a.x - b.x, v1y = a.y - b.y;
  final v2x = c.x - b.x, v2y = c.y - b.y;
  final dot = v1x * v2x + v1y * v2y;
  final mag = math.sqrt(v1x * v1x + v1y * v1y) * math.sqrt(v2x * v2x + v2y * v2y);
  if (mag == 0) return 180;
  return math.acos((dot / mag).clamp(-1.0, 1.0)) * 180 / math.pi;
}
