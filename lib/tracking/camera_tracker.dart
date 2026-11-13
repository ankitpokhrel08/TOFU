import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import 'pose.dart';
import 'squat_analyzer.dart';
import 'tracker.dart';

const _jointMap = {
  Joint.nose: PoseLandmarkType.nose,
  Joint.leftShoulder: PoseLandmarkType.leftShoulder,
  Joint.rightShoulder: PoseLandmarkType.rightShoulder,
  Joint.leftElbow: PoseLandmarkType.leftElbow,
  Joint.rightElbow: PoseLandmarkType.rightElbow,
  Joint.leftWrist: PoseLandmarkType.leftWrist,
  Joint.rightWrist: PoseLandmarkType.rightWrist,
  Joint.leftHip: PoseLandmarkType.leftHip,
  Joint.rightHip: PoseLandmarkType.rightHip,
  Joint.leftKnee: PoseLandmarkType.leftKnee,
  Joint.rightKnee: PoseLandmarkType.rightKnee,
  Joint.leftAnkle: PoseLandmarkType.leftAnkle,
  Joint.rightAnkle: PoseLandmarkType.rightAnkle,
};

/// Live squat tracking on the front camera with on-device ML Kit pose
/// detection. Frames never leave the device.
class CameraTracker extends SquatTracker {
  final _detector = PoseDetector(
    options: PoseDetectorOptions(model: PoseDetectionModel.base, mode: PoseDetectionMode.stream),
  );
  final _setupChecker = SetupChecker();
  final _analyzer = SquatAnalyzer();

  CameraController? _controller;
  bool _busy = false;
  bool _closed = false;

  @override
  bool get simulated => false;

  @override
  Widget? buildPreview() {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return null;
    return CameraPreview(c);
  }

  /// Upright preview size (portrait), for laying out the preview and overlay.
  Size? get previewSize {
    final s = _controller?.value.previewSize;
    return s == null ? null : Size(s.shortestSide, s.longestSide);
  }

  @override
  Future<void> start() async {
    setPhase(TrackerPhase.starting);
    final List<CameraDescription> cameras;
    try {
      cameras = await availableCameras();
    } on Object {
      return setPhase(TrackerPhase.unavailable);
    }
    if (cameras.isEmpty) return setPhase(TrackerPhase.unavailable);

    final camera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );
    final controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
    );
    _controller = controller;
    try {
      await controller.initialize();
      if (_closed) return;
      await controller.startImageStream(_onFrame);
    } on CameraException catch (e) {
      debugPrint('Camera error: ${e.code} ${e.description}');
      return setPhase(
        e.code.startsWith('CameraAccess')
            ? TrackerPhase.permissionDenied
            : TrackerPhase.unavailable,
      );
    }
    setPhase(TrackerPhase.setup);
  }

  @override
  void onWorkoutStart() => _analyzer.reset();

  Future<void> _onFrame(CameraImage image) async {
    // Drop frames while the detector is busy so latency stays low.
    if (_busy || _closed || paused) return;
    _busy = true;
    try {
      final input = _toInputImage(image);
      if (input == null) return;
      final poses = await _detector.processImage(input);
      if (_closed) return;
      _handle(poses.isEmpty ? null : _snapshot(poses.first, input.metadata!));
    } on Object catch (e) {
      debugPrint('Pose detection failed: $e');
    } finally {
      _busy = false;
    }
  }

  void _handle(PoseSnapshot? pose) {
    switch (phase) {
      case TrackerPhase.setup:
        reportLive(depth: 0, pose: pose, bodyVisible: pose != null);
        reportChecks(_setupChecker.update(pose));
      case TrackerPhase.countdown:
        reportLive(depth: 0, pose: pose, bodyVisible: pose != null);
      case TrackerPhase.workout:
        final visible = pose != null && SetupChecker.bodyInFrame(pose);
        RepEvent? rep;
        if (visible) rep = _analyzer.update(pose);
        reportLive(
          depth: _analyzer.depth,
          issue: visible ? _analyzer.liveIssue : null,
          pose: pose,
          bodyVisible: visible,
        );
        if (rep != null) reportRep(rep.issue);
      default:
    }
  }

  /// Map ML Kit landmarks into the upright, mirrored display frame.
  PoseSnapshot _snapshot(Pose pose, InputImageMetadata meta) {
    final quarterTurn =
        meta.rotation == InputImageRotation.rotation90deg ||
        meta.rotation == InputImageRotation.rotation270deg;
    final size = quarterTurn ? Size(meta.size.height, meta.size.width) : meta.size;
    final mirror = _controller?.description.lensDirection == CameraLensDirection.front;
    return PoseSnapshot({
      for (final MapEntry(key: joint, value: type) in _jointMap.entries)
        if (pose.landmarks[type] case final l?)
          joint: PosePoint(mirror ? size.width - l.x : l.x, l.y, l.likelihood),
    }, size);
  }

  InputImage? _toInputImage(CameraImage image) {
    final camera = _controller?.description;
    if (camera == null) return null;
    // The app is portrait-locked, so the sensor orientation is the rotation.
    final rotation = InputImageRotationValue.fromRawValue(camera.sensorOrientation);
    if (rotation == null) return null;

    final Uint8List bytes;
    final int bytesPerRow;
    final InputImageFormat format;
    if (Platform.isAndroid) {
      format = InputImageFormat.nv21;
      bytes = image.planes.length == 1 ? image.planes.first.bytes : _yuv420ToNv21(image);
      bytesPerRow = image.planes.length == 1 ? image.planes.first.bytesPerRow : image.width;
    } else {
      if (image.planes.length != 1) return null;
      format = InputImageFormat.bgra8888;
      bytes = image.planes.first.bytes;
      bytesPerRow = image.planes.first.bytesPerRow;
    }
    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: bytesPerRow,
      ),
    );
  }

  /// Some Android devices deliver three YUV planes even when NV21 is
  /// requested; pack them into NV21 (Y plane, then interleaved V/U).
  static Uint8List _yuv420ToNv21(CameraImage image) {
    final w = image.width, h = image.height;
    final out = Uint8List(w * h * 3 ~/ 2);
    final y = image.planes[0], u = image.planes[1], v = image.planes[2];
    var o = 0;
    for (var row = 0; row < h; row++) {
      out.setRange(o, o + w, y.bytes, row * y.bytesPerRow);
      o += w;
    }
    final step = u.bytesPerPixel ?? 1;
    for (var row = 0; row < h ~/ 2; row++) {
      for (var col = 0; col < w ~/ 2; col++) {
        out[o++] = v.bytes[row * v.bytesPerRow + col * step];
        out[o++] = u.bytes[row * u.bytesPerRow + col * step];
      }
    }
    return out;
  }

  @override
  void dispose() {
    _closed = true;
    final c = _controller;
    _controller = null;
    // Release the camera and detector without blocking the UI.
    () async {
      try {
        if (c != null && c.value.isStreamingImages) await c.stopImageStream();
      } on Object {
        // Already stopped.
      }
      await c?.dispose();
      await _detector.close();
    }();
    super.dispose();
  }
}
