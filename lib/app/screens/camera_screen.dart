import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_theme.dart';
import '../../tracking/pose.dart';
import '../../tracking/simulated_tracker.dart';
import '../../game/exercises.dart';
import '../../game/levels.dart';
import '../../tracking/tracker.dart';
import '../../widgets/common.dart';
import '../../widgets/decor.dart';
import '../../widgets/exercise_demo.dart';
import '../app_controller.dart';
import '../widgets/rep_dots.dart';
import 'results_screen.dart';

// Generic on purpose: these follow any exercise, and holds aren't reps.
const _praise = ['Clean rep!', 'Nice form!', 'Smooth!', 'Great control!'];
const _holdPraise = ['Solid hold!', 'Steady!', 'Looking strong!'];

/// Camera setup → countdown → each exercise in turn → results, driven by a
/// [WorkoutTracker].
class CameraScreen extends StatefulWidget {
  const CameraScreen({
    super.key,
    required this.app,
    required this.trackerFactory,
    required this.kind,
    required this.blocks,
    this.level,
  });

  final AppController app;
  final TrackerFactory trackerFactory;
  final SessionKind kind;
  final List<Block> blocks;
  final GameLevel? level;

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late WorkoutTracker _tracker;
  bool _finishing = false;

  /// Refreshes time-based hints even when the camera sends no frames.
  late final Timer _clock;

  @override
  void initState() {
    super.initState();
    _use(widget.trackerFactory(widget.blocks, widget.app.limits));
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _tracker.phase == TrackerPhase.setup) setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Cue mascots swap mid-set; decode them up front so none flashes blank.
    for (final m in const ['zen', 'laptop', 'cheer', 'lift']) {
      precacheImage(AssetImage('assets/mascot/$m.png'), context);
    }
  }

  void _use(WorkoutTracker t) {
    _tracker = t..addListener(_onTracker);
    t.start();
  }

  /// Swap in a fresh tracker (retry the camera, or fall back to the demo).
  void _replace(WorkoutTracker t) {
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
    _clock.cancel();
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
    if (t.totalDone == 0) {
      Navigator.of(context).pop();
      return;
    }
    final outcome = await widget.app.completeWorkout(
      kind: widget.kind,
      level: widget.level,
      blocks: t.results,
      activeSeconds: t.elapsed.inSeconds,
      demo: t.simulated,
    );
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => ResultsScreen(
          app: widget.app,
          outcome: outcome,
          level: widget.level,
          trackerFactory: widget.trackerFactory,
        ),
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
    final setup = switch (t.phase) {
      TrackerPhase.workout || TrackerPhase.transition || TrackerPhase.done => false,
      _ => true,
    };
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
                    onBack: setup ? () => Navigator.of(context).pop() : _finish,
                  ),
                  Expanded(
                    child: blocked
                        ? _Blocked(
                            denied: t.phase == TrackerPhase.permissionDenied,
                            onRetry: () =>
                                _replace(widget.trackerFactory(widget.blocks, widget.app.limits)),
                            onDemo: () => _replace(
                              SimulatedTracker(widget.blocks, limits: widget.app.limits),
                            ),
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
                      total: t.block.units,
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
    final previewSize = t.previewSize;
    return Stack(
      children: [
        if (preview != null && previewSize != null && !t.simulated)
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
        else if (t.simulated)
          // Demo: the exercise animation stands in for the camera.
          Positioned.fill(
            child: Center(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: setup ? (calibrated ? .9 : .4) : 1,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .92),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: ExerciseDemo(exercise: t.block.exercise, height: 300),
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
        if (_cantSee(t))
          Positioned(
            left: 18,
            right: 18,
            bottom: 12,
            child: _CantSeeYou(
              onDemo: () => _replace(SimulatedTracker(widget.blocks, limits: widget.app.limits)),
            ),
          ),
        if (_workout) ...[
          Positioned(left: 18, top: 12, child: _RepCounter(tracker: t)),
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
        if (t.phase == TrackerPhase.transition && t.nextBlock != null)
          Positioned.fill(
            child: ColoredBox(
              color: AppColors.inkDeep.withValues(alpha: .85),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 10,
                children: [
                  Text('Nice! Next up', style: nunito(15, color: AppColors.lime)),
                  Text(t.nextBlock!.label, style: baloo(32, color: Colors.white)),
                  Container(
                    width: 220,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .92),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ExerciseDemo(exercise: t.nextBlock!.exercise, height: 150),
                  ),
                  Text(
                    t.nextBlock!.exercise.setupHint,
                    style: nunito(15, weight: FontWeight.w700, color: AppColors.textOnDark),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 96,
                    height: 96,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.pink,
                      shape: BoxShape.circle,
                      boxShadow: hardShadow(AppColors.pinkDark, 6),
                    ),
                    child: Text('${t.count}', style: baloo(54, height: 1, color: Colors.white)),
                  ),
                ],
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

  /// No whole body found for a while during setup: the camera may be
  /// covered, too dark, too close, or only seeing background clutter.
  static bool _cantSee(WorkoutTracker t) =>
      !t.simulated &&
      t.phase == TrackerPhase.setup &&
      !t.checks.first &&
      t.setupTime > const Duration(seconds: 8);

  _Cue _cue() {
    final t = _tracker;
    if (!t.bodyVisible) {
      return const _Cue('Step back so I can see your whole body', AppColors.orange, 'laptop');
    }
    if (!t.inPosition) {
      return _Cue(
        'Get into position: ${t.block.exercise.setupHint.toLowerCase()}',
        AppColors.orange,
        'laptop',
      );
    }
    if (t.liveIssue case final issue?) {
      final main = issue == t.block.exercise.issues.first;
      return _Cue(issue.cue, main ? AppColors.red : AppColors.orange, 'laptop');
    }
    final since = t.sinceLastRep;
    if (t.repLog.isNotEmpty &&
        t.repLog.last &&
        since != null &&
        since < const Duration(milliseconds: 700)) {
      final words = t.block.exercise.timed ? _holdPraise : _praise;
      return _Cue(words[t.reps % words.length], AppColors.green, 'cheer');
    }
    final left = t.block.units - t.reps;
    if (left <= 3 && left > 0) {
      final unit = t.block.exercise.timed ? '${left * Exercise.holdSegment}s' : '$left more';
      return _Cue("$unit, you've got this!", AppColors.purple, 'lift');
    }
    // The exercise's own first cue, e.g. "Hips to knee height". Between
    // exercises, prepare for the next one.
    final upcoming = t.phase == TrackerPhase.transition ? t.nextBlock : null;
    final (cue, detail) = (upcoming ?? t.block).exercise.cues.first;
    return _Cue(
      '$cue: ${detail[0].toLowerCase()}${detail.substring(1)}',
      Colors.white.withValues(alpha: .12),
      'zen',
    );
  }
}

class _CantSeeYou extends StatelessWidget {
  const _CantSeeYou({required this.onDemo});

  final VoidCallback onDemo;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
        decoration: BoxDecoration(color: AppColors.orange, borderRadius: BorderRadius.circular(18)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("I can't see you yet", style: baloo(18, color: Colors.white)),
            Text(
              'Step back so your whole body fits, turn on more light, and check nothing covers the camera.',
              style: nunito(13, weight: FontWeight.w700, color: Colors.white),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onDemo,
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                child: Text('Try the demo set', style: nunito(14, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
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
  const _TopBar({required this.setup, required this.tag, required this.onBack});

  final bool setup;
  final String tag;
  final VoidCallback onBack;

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
          // Balances the back button so the tag stays centred.
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}

class _RepCounter extends StatelessWidget {
  const _RepCounter({required this.tracker});

  final WorkoutTracker tracker;

  @override
  Widget build(BuildContext context) {
    final t = tracker;
    final b = t.block;
    final timed = b.exercise.timed;
    final value = timed ? t.heldSeconds.floor().clamp(0, b.target) : t.reps;
    final target = timed ? b.target : b.units;
    final step = t.blocks.length > 1 ? ' · ${t.blockIndex + 1}/${t.blocks.length}' : '';
    return Semantics(
      label: timed
          ? '$value of $target seconds of ${b.exercise.label}'
          : '$value of $target ${b.exercise.plural}',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${b.exercise.label.toUpperCase()}$step',
            style: nunito(
              10,
              weight: FontWeight.w900,
              letterSpacing: 1.4,
              color: AppColors.textOnDark,
            ),
          ),
          Text.rich(
            TextSpan(
              text: '$value',
              children: [
                TextSpan(
                  text: timed ? '/${target}s' : '/$target',
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
    required this.total,
    required this.paused,
    required this.onTogglePause,
    required this.onEnd,
  });

  final _Cue cue;
  final List<bool> repLog;
  final int total;
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
                    child: Image.asset(
                      'assets/mascot/${cue.mascot}.png',
                      fit: BoxFit.contain,
                      // Keep the old mascot until the new one is decoded.
                      gaplessPlayback: true,
                    ),
                  ),
                  Expanded(child: Text(cue.text, style: nunito(16, height: 1.25))),
                ],
              ),
            ),
          ),
          RepDots(
            repLog: repLog,
            total: total,
            height: 8,
            empty: Colors.white.withValues(alpha: .15),
          ),
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
