import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_theme.dart';
import '../../tracking/camera_tracker.dart';
import '../../tracking/pose.dart';
import '../../tracking/simulated_tracker.dart';
import '../../tracking/squat_analyzer.dart';
import '../../tracking/tracker.dart';
import '../../widgets/common.dart';
import '../../widgets/decor.dart';
import '../app_controller.dart';
import '../widgets/rep_dots.dart';
import 'results_screen.dart';

const _praise = ['Nice depth!', 'Clean rep!', 'Chest proud, love it', 'Smooth!'];

/// Camera setup → countdown → live tracked set, driven by a [SquatTracker].
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key, required this.app, required this.trackerFactory});

  final AppController app;
  final TrackerFactory trackerFactory;

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late SquatTracker _tracker;
  bool _voice = true;
  bool _finishing = false;

  @override
  void initState() {
    super.initState();
    _use(widget.trackerFactory());
  }

  void _use(SquatTracker t) {
    _tracker = t..addListener(_onTracker);
    t.start();
  }

  /// Swap in a fresh tracker (retry the camera, or fall back to the demo).
  void _replace(SquatTracker t) {
    _tracker
      ..removeListener(_onTracker)
      ..dispose();
    setState(() => _use(t));
  }

  void _onTracker() {
    if (!mounted) return;
    if (_tracker.phase == TrackerPhase.done) {
      _finish();
    } else {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _tracker
      ..removeListener(_onTracker)
      ..dispose();
    super.dispose();
  }

  bool get _workout => _tracker.phase == TrackerPhase.workout;

  Future<void> _finish() async {
    if (_finishing) return;
    _finishing = true;
    final t = _tracker;
    if (t.phase != TrackerPhase.done) t.finish();
    if (t.reps == 0) {
      Navigator.of(context).pop();
      return;
    }
    final result = await widget.app.completeSession(
      repLog: t.repLog,
      errors: t.errors,
      form: t.finalScore,
    );
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => ResultsScreen(app: widget.app, result: result),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = _tracker;
    final blocked = switch (t.phase) {
      TrackerPhase.permissionDenied || TrackerPhase.unavailable => true,
      _ => false,
    };
    final setup = !_workout && t.phase != TrackerPhase.done;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.inkDeep,
        body: CustomPaint(
          painter: const StripePainter(base: AppColors.inkDeep, stripe: Color(0x09FFFFFF)),
          child: SafeArea(
            child: DefaultTextStyle(
              style: nunito(15, color: Colors.white),
              child: Column(
                children: [
                  _TopBar(
                    setup: setup,
                    tag: blocked
                        ? 'NO CAMERA'
                        : t.simulated
                        ? (setup ? 'DEMO' : 'DEMO SET')
                        : (setup ? 'CALIBRATING' : 'TRACKING'),
                    voice: _voice,
                    onBack: setup ? () => Navigator.of(context).pop() : _finish,
                    onToggleVoice: () => setState(() => _voice = !_voice),
                  ),
                  Expanded(
                    child: blocked
                        ? _Blocked(
                            denied: t.phase == TrackerPhase.permissionDenied,
                            onRetry: () => _replace(widget.trackerFactory()),
                            onDemo: () => _replace(SimulatedTracker()),
                          )
                        : _viewport(setup),
                  ),
                  if (blocked)
                    const SizedBox(height: 16)
                  else if (setup)
                    _SetupChecks(checks: t.checks, starting: t.phase == TrackerPhase.starting)
                  else
                    _WorkoutControls(
                      cue: _cue(),
                      repLog: t.repLog,
                      paused: t.paused,
                      onTogglePause: () => t.setPaused(!t.paused),
                      onEnd: _finish,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _viewport(bool setup) {
    final t = _tracker;
    final calibrated = t.checks.first;
    final preview = t.buildPreview();
    final previewSize = t is CameraTracker ? t.previewSize : null;
    return Stack(
      children: [
        if (preview != null && previewSize != null)
          // Real camera: fill the area, overlay the detected skeleton.
          Positioned.fill(
            child: ClipRect(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: previewSize.width,
                  height: previewSize.height,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      preview,
                      if (t.pose case final pose?)
                        CustomPaint(
                          painter: _LiveSkeletonPainter(
                            pose,
                            issue: t.liveIssue,
                            dim: setup && !calibrated,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          )
        else
          // Demo: the stylised skeleton on a fixed 390×500 canvas.
          Positioned.fill(
            child: FittedBox(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: 390,
                height: 500,
                child: Stack(
                  children: [
                    Positioned(
                      left: 75,
                      top: 86,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        opacity: setup ? (calibrated ? .9 : .3) : 1,
                        child: CustomPaint(
                          size: const Size(240, 360),
                          painter: _PosePainter(
                            depth: t.depth,
                            kneeError: t.liveIssue == FormIssue.kneesIn,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (setup)
          // Body outline guide.
          Positioned.fill(
            child: FittedBox(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: 390,
                height: 500,
                child: Stack(
                  children: [
                    Positioned(
                      left: 90,
                      top: 60,
                      width: 210,
                      height: 420,
                      child: CustomPaint(
                        painter: DashedOutlinePainter(
                          color: calibrated ? AppColors.lime : Colors.white.withValues(alpha: .4),
                          strokeWidth: 3,
                          dash: 9,
                          gap: 7,
                          radius: const BorderRadius.vertical(
                            top: Radius.circular(105),
                            bottom: Radius.circular(28),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (t.phase == TrackerPhase.starting)
          const Center(child: CircularProgressIndicator(color: AppColors.pink)),
        if (_workout) ...[
          Positioned(left: 18, top: 12, child: _RepCounter(reps: t.reps)),
          Positioned(
            right: 18,
            top: 12,
            child: _FormReadout(form: t.formScore, seconds: t.elapsed.inMilliseconds / 1000),
          ),
        ],
        if (t.phase == TrackerPhase.countdown)
          Center(
            child: Container(
              width: 150,
              height: 150,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.pink,
                shape: BoxShape.circle,
                boxShadow: hardShadow(AppColors.pinkDark, 8),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                child: Text(
                  '${t.count}',
                  key: ValueKey(t.count),
                  style: baloo(92, height: 1, color: Colors.white),
                ),
              ),
            ),
          ),
        if (_workout && t.paused)
          Positioned.fill(
            child: ColoredBox(
              color: AppColors.inkDeep.withValues(alpha: .82),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 12,
                children: [
                  Image.asset('assets/mascot/zen.png', width: 130),
                  Text('Paused', style: baloo(30, color: Colors.white)),
                  Text(
                    'Take a breath. Your reps are saved.',
                    style: nunito(15, weight: FontWeight.w700, color: AppColors.textOnDark),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  _Cue _cue() {
    final t = _tracker;
    if (!t.bodyVisible) {
      return const _Cue('Step back so I can see your whole body', AppColors.orange, 'laptop');
    }
    if (t.liveIssue == FormIssue.kneesIn) {
      return const _Cue('Knees caving in! Push them out', AppColors.red, 'laptop');
    }
    if (t.liveIssue == FormIssue.shallow) {
      return const _Cue('Go lower: hips to knee height', AppColors.orange, 'laptop');
    }
    final since = t.sinceLastRep;
    if (t.repLog.isNotEmpty &&
        t.repLog.last &&
        since != null &&
        since < const Duration(milliseconds: 700)) {
      return _Cue(_praise[t.reps % _praise.length], AppColors.green, 'cheer');
    }
    if (t.reps >= repTarget - 3) {
      return _Cue("${repTarget - t.reps} more, you've got this!", AppColors.purple, 'lift');
    }
    return _Cue(
      "Sit back like there's a chair behind you",
      Colors.white.withValues(alpha: .12),
      'zen',
    );
  }
}

/// Shown when the camera can't be used.
class _Blocked extends StatelessWidget {
  const _Blocked({required this.denied, required this.onRetry, required this.onDemo});

  final bool denied;
  final VoidCallback onRetry;
  final VoidCallback onDemo;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          spacing: 14,
          children: [
            Image.asset('assets/mascot/laptop.png', width: 140),
            Text(
              denied ? 'Camera access is off' : 'No camera available',
              textAlign: TextAlign.center,
              style: baloo(26, color: Colors.white),
            ),
            Text(
              denied
                  ? 'Guru needs the camera to count reps and check your form. '
                        'Allow camera access for Gym Guru in Settings, then try again.'
                  : "This device doesn't have a camera Guru can use. "
                        'You can still try the demo set.',
              textAlign: TextAlign.center,
              style: nunito(15, weight: FontWeight.w600, height: 1.4, color: AppColors.textOnDark),
            ),
            const SizedBox(height: 6),
            if (denied) ChunkyButton(label: 'Try again', onPressed: onRetry),
            ChunkyButton(
              label: 'Try the demo set',
              onPressed: onDemo,
              color: Colors.white.withValues(alpha: .14),
              shadowColor: Colors.transparent,
              shadowDepth: 0,
            ),
          ],
        ),
      ),
    );
  }
}

/// Detected skeleton over the camera preview, in image pixel coordinates.
class _LiveSkeletonPainter extends CustomPainter {
  _LiveSkeletonPainter(this.pose, {required this.issue, required this.dim});

  final PoseSnapshot pose;
  final FormIssue? issue;
  final bool dim;

  static bool _isLeg(Joint j) =>
      j == Joint.leftKnee || j == Joint.rightKnee || j == Joint.leftAnkle || j == Joint.rightAnkle;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / pose.imageSize.width, size.height / pose.imageSize.height);
    final unit = pose.imageSize.shortestSide / 100;
    final alpha = dim ? .45 : 1.0;
    final legColor = issue == FormIssue.kneesIn ? AppColors.red : AppColors.lime;

    for (final (a, b) in skeletonBones) {
      final pa = pose[a], pb = pose[b];
      if (pa == null || pb == null || pa.confidence < .5 || pb.confidence < .5) continue;
      final leg = _isLeg(a) || _isLeg(b);
      canvas.drawLine(
        pa.offset,
        pb.offset,
        Paint()
          ..color = (leg ? legColor : AppColors.lime).withValues(alpha: alpha)
          ..strokeWidth = unit * 1.2
          ..strokeCap = StrokeCap.round,
      );
    }
    for (final MapEntry(key: j, value: p) in pose.points.entries) {
      if (p.confidence < .5 || j == Joint.nose) continue;
      final knee = j == Joint.leftKnee || j == Joint.rightKnee;
      canvas
        ..drawCircle(
          p.offset,
          unit * (knee ? 2 : 1.4),
          Paint()..color = (knee ? legColor : Colors.white).withValues(alpha: alpha),
        )
        ..drawCircle(
          p.offset,
          unit * (knee ? 2 : 1.4),
          Paint()
            ..color = AppColors.lime.withValues(alpha: alpha)
            ..style = PaintingStyle.stroke
            ..strokeWidth = unit * .6,
        );
    }
  }

  @override
  bool shouldRepaint(_LiveSkeletonPainter old) =>
      old.pose != pose || old.issue != issue || old.dim != dim;
}

class _Cue {
  const _Cue(this.text, this.color, this.mascot);
  final String text;
  final Color color;
  final String mascot;
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.setup,
    required this.tag,
    required this.voice,
    required this.onBack,
    required this.onToggleVoice,
  });

  final bool setup;
  final String tag;
  final bool voice;
  final VoidCallback onBack;
  final VoidCallback onToggleVoice;

  @override
  Widget build(BuildContext context) {
    final translucent = Colors.white.withValues(alpha: .12);
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 4, 22, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SquareIconButton(
            icon: setup ? Icons.chevron_left_rounded : Icons.close_rounded,
            label: setup ? 'Back' : 'End set',
            onTap: onBack,
            background: translucent,
            foreground: Colors.white,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.red,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Row(
              spacing: 6,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                ),
                Text(tag, style: nunito(11, weight: FontWeight.w900, letterSpacing: 1.1)),
              ],
            ),
          ),
          Semantics(
            button: true,
            toggled: voice,
            label: 'Voice coaching',
            excludeSemantics: true,
            child: GestureDetector(
              onTap: onToggleVoice,
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: translucent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(voice ? 'Voice on' : 'Voice off', style: nunito(13)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RepCounter extends StatelessWidget {
  const _RepCounter({required this.reps});

  final int reps;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$reps of $repTarget reps',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'REPS',
            style: nunito(
              10,
              weight: FontWeight.w900,
              letterSpacing: 1.4,
              color: AppColors.textOnDark,
            ),
          ),
          Text.rich(
            TextSpan(
              text: '$reps',
              children: [
                TextSpan(
                  text: '/$repTarget',
                  style: baloo(28, color: AppColors.textFaint),
                ),
              ],
            ),
            style: baloo(64, height: .9, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _FormReadout extends StatelessWidget {
  const _FormReadout({required this.form, required this.seconds});

  final int form;
  final double seconds;

  @override
  Widget build(BuildContext context) {
    final color = form >= 90
        ? AppColors.lime
        : form >= 80
        ? AppColors.yellow
        : const Color(0xFFFF7D8F);
    final s = seconds.floor();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'FORM',
          style: nunito(
            10,
            weight: FontWeight.w900,
            letterSpacing: 1.4,
            color: AppColors.textOnDark,
          ),
        ),
        Text('$form', style: baloo(40, height: 1, color: color)),
        const SizedBox(height: 6),
        Text(
          '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}',
          style: nunito(13, color: AppColors.textOnDark),
        ),
      ],
    );
  }
}

class _SetupChecks extends StatelessWidget {
  const _SetupChecks({required this.checks, required this.starting});

  final List<bool> checks;
  final bool starting;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 20),
      child: Column(
        spacing: 8,
        children: [
          for (final (i, label) in setupCheckLabels.indexed)
            Builder(
              builder: (context) {
                final ok = !starting && checks[i];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    spacing: 12,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: ok ? AppColors.lime : Colors.transparent,
                          border: Border.all(
                            color: ok ? AppColors.lime : Colors.white.withValues(alpha: .3),
                            width: 2,
                          ),
                        ),
                        child: ok
                            ? const Icon(Icons.check_rounded, size: 15, color: AppColors.ink)
                            : null,
                      ),
                      Expanded(
                        child: Text(
                          label,
                          style: nunito(15, color: ok ? Colors.white : AppColors.textFaint),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _WorkoutControls extends StatelessWidget {
  const _WorkoutControls({
    required this.cue,
    required this.repLog,
    required this.paused,
    required this.onTogglePause,
    required this.onEnd,
  });

  final _Cue cue;
  final List<bool> repLog;
  final bool paused;
  final VoidCallback onTogglePause;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
      child: Column(
        spacing: 12,
        children: [
          Semantics(
            liveRegion: true,
            label: cue.text,
            excludeSemantics: true,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
              decoration: BoxDecoration(color: cue.color, borderRadius: BorderRadius.circular(20)),
              child: Row(
                spacing: 10,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .9),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Image.asset('assets/mascot/${cue.mascot}.png', fit: BoxFit.contain),
                  ),
                  Expanded(child: Text(cue.text, style: nunito(16, height: 1.25))),
                ],
              ),
            ),
          ),
          RepDots(repLog: repLog, height: 8, empty: Colors.white.withValues(alpha: .15)),
          Row(
            spacing: 10,
            children: [
              Expanded(
                child: ChunkyButton(
                  label: paused ? 'Resume' : 'Pause',
                  onPressed: onTogglePause,
                  height: 54,
                  fontSize: 17,
                  color: Colors.white.withValues(alpha: .14),
                  shadowColor: Colors.transparent,
                  shadowDepth: 0,
                ),
              ),
              Expanded(
                child: ChunkyButton(
                  label: 'End set',
                  onPressed: onEnd,
                  height: 54,
                  fontSize: 17,
                  color: Colors.white,
                  textColor: AppColors.ink,
                  shadowColor: AppColors.disabledShadow,
                  shadowDepth: 4,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Pose skeleton in a 200×300 design space. [depth] 0–1 lowers the body
/// into the squat; [kneeError] draws the knees caving in.
class _PosePainter extends CustomPainter {
  _PosePainter({required this.depth, required this.kneeError});

  final double depth;
  final bool kneeError;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 200, size.height / 300);
    final d = depth;
    final headY = 34 + d * 40;
    final neckY = 50 + d * 40;
    final shY = 88 + d * 40;
    final elY = shY + 38;
    final haY = shY + 60;
    final hipY = 168 + d * 46;
    final kY = 218 + d * 6;
    // Knees track out as you sink; when caving they collapse toward centre.
    final kL = kneeError ? 96.0 : 66 - d * 10;
    final kR = kneeError ? 104.0 : 134 + d * 10;
    final kneeColor = kneeError ? AppColors.red : AppColors.lime;

    Paint stroke(Color c, [double w = 4]) => Paint()
      ..color = c
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    void line(double x1, double y1, double x2, double y2, Paint p) =>
        canvas.drawLine(Offset(x1, y1), Offset(x2, y2), p);

    final body = stroke(AppColors.lime);
    line(100, neckY, 100, shY, body);
    line(75, shY, 125, shY, body);
    line(75, shY, 56, elY, body);
    line(56, elY, 90, haY, body);
    line(125, shY, 144, elY, body);
    line(144, elY, 110, haY, body);
    line(75, shY, 84, hipY, body);
    line(125, shY, 116, hipY, body);
    line(84, hipY, 116, hipY, body);
    canvas.drawCircle(Offset(100, headY), 16, body);

    final legs = stroke(kneeColor);
    line(84, hipY, kL, kY, legs);
    line(kL, kY, 70, 274, legs);
    line(116, hipY, kR, kY, legs);
    line(kR, kY, 130, 274, legs);

    final fill = Paint()..color = Colors.white;
    final ring = stroke(AppColors.lime, 3);
    for (final p in [
      Offset(75, shY),
      Offset(125, shY),
      Offset(84, hipY),
      Offset(116, hipY),
      const Offset(70, 274),
      const Offset(130, 274),
    ]) {
      canvas
        ..drawCircle(p, 5, fill)
        ..drawCircle(p, 5, ring);
    }
    final knee = Paint()..color = kneeColor;
    canvas
      ..drawCircle(Offset(kL, kY), 7, knee)
      ..drawCircle(Offset(kR, kY), 7, knee);
  }

  @override
  bool shouldRepaint(_PosePainter old) => old.depth != depth || old.kneeError != kneeError;
}
