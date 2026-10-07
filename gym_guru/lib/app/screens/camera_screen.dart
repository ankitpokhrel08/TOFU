import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/decor.dart';
import '../app_controller.dart';
import '../widgets/rep_dots.dart';
import 'results_screen.dart';

enum _Phase { setup, countdown, workout }

const _tick = Duration(milliseconds: 300);
const _ticksPerRep = 8;
const _setupTicks = 9;
const _ticksPerCount = 3;

/// Squat depth through one rep, sampled per tick.
const _depthCurve = [0.0, .35, .75, 1.0, 1.0, .7, .35, 0.0];

/// Scripted form errors for the simulated set.
const _scriptedErrors = {
  4: FormError(4, 'Knees caved in', 'Push knees out over your toes'),
  9: FormError(9, 'Too shallow', 'Hips should reach knee height'),
};

const _setupChecks = ['Whole body in frame', 'Good lighting', 'Phone steady at hip height'];
const _praise = ['Nice depth!', 'Clean rep!', 'Chest proud, love it', 'Smooth!'];

/// Camera setup → countdown → live tracked set. The camera feed and pose
/// data are simulated.
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key, required this.app});

  final AppController app;

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late final Timer _timer;
  _Phase _phase = _Phase.setup;
  int _setup = 0;
  int _count = 3;
  int _countTicks = 0;
  int _ticks = 0;
  bool _paused = false;
  bool _voice = true;
  final _repLog = <bool>[];
  final _errors = <FormError>[];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(_tick, (_) => _step());
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _step() {
    switch (_phase) {
      case _Phase.setup:
        setState(() {
          if (++_setup >= _setupTicks) _phase = _Phase.countdown;
        });
      case _Phase.countdown:
        if (++_countTicks < _ticksPerCount) return;
        _countTicks = 0;
        setState(() {
          if (_count > 1) {
            _count--;
          } else {
            _phase = _Phase.workout;
          }
        });
      case _Phase.workout:
        if (_paused) return;
        setState(() {
          _ticks++;
          if (_ticks % _ticksPerRep == 0) {
            final rep = _repLog.length + 1;
            final err = _scriptedErrors[rep];
            _repLog.add(err == null);
            if (err != null) {
              _errors.add(err);
              HapticFeedback.mediumImpact();
            }
          }
        });
        if (_repLog.length >= repTarget) _finish();
    }
  }

  int get _reps => _repLog.length;
  int get _phaseTick => _ticks % _ticksPerRep;
  int get _currentRep => _reps + 1;
  bool get _workout => _phase == _Phase.workout;

  double get _depth => _workout ? _depthCurve[_phaseTick] : 0;
  bool get _kneeError => _workout && _currentRep == 4 && _depth > .6;
  bool get _shallow => _workout && _currentRep == 9;
  bool get _shallowError => _shallow && _phaseTick >= 3 && _phaseTick <= 5;
  bool get _bad => _kneeError || _shallowError;

  int get _form => _reps == 0 ? 100 : 100 - _errors.length * 9 - (_bad ? 6 : 0);

  void _finish() {
    _timer.cancel();
    if (_reps == 0) {
      Navigator.of(context).pop();
      return;
    }
    final result = SessionResult(repLog: List.of(_repLog), errors: List.of(_errors), form: _form);
    widget.app.completeSession(result);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => ResultsScreen(app: widget.app, result: result),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final setup = !_workout;
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
                    voice: _voice,
                    onBack: setup ? () => Navigator.of(context).pop() : _finish,
                    onToggleVoice: () => setState(() => _voice = !_voice),
                  ),
                  Expanded(child: _viewport(setup)),
                  if (setup)
                    _SetupChecks(progress: _setup)
                  else
                    _WorkoutControls(
                      cue: _cue(),
                      repLog: _repLog,
                      paused: _paused,
                      onTogglePause: () => setState(() => _paused = !_paused),
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
    final calibrated = _setup > 2;
    return Stack(
      children: [
        // Fixed 390×500 design canvas, scaled to fit the available space.
        Positioned.fill(
          child: FittedBox(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: 390,
              height: 500,
              child: Stack(
                children: [
                  if (setup)
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
                  Positioned(
                    left: 75,
                    top: 86,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: setup ? (calibrated ? .9 : .3) : 1,
                      child: CustomPaint(
                        size: const Size(240, 360),
                        painter: _PosePainter(
                          depth: _shallow ? _depth * .55 : _depth,
                          kneeError: _kneeError,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_workout) ...[
          Positioned(left: 18, top: 12, child: _RepCounter(reps: _reps)),
          Positioned(
            right: 18,
            top: 12,
            child: _FormReadout(form: _form, seconds: _ticks * .3),
          ),
        ],
        if (_phase == _Phase.countdown)
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
                  '$_count',
                  key: ValueKey(_count),
                  style: baloo(92, height: 1, color: Colors.white),
                ),
              ),
            ),
          ),
        if (_workout && _paused)
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
    if (_kneeError) {
      return const _Cue('Knees caving in! Push them out', AppColors.red, 'laptop');
    }
    if (_shallowError) {
      return const _Cue('Go lower: hips to knee height', AppColors.orange, 'laptop');
    }
    if (_repLog.isNotEmpty && _repLog.last && _phaseTick < 2) {
      return _Cue(_praise[_reps % _praise.length], AppColors.green, 'cheer');
    }
    if (_reps >= repTarget - 3) {
      return _Cue("${repTarget - _reps} more, you've got this!", AppColors.purple, 'lift');
    }
    return _Cue(
      "Sit back like there's a chair behind you",
      Colors.white.withValues(alpha: .12),
      'zen',
    );
  }
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
    required this.voice,
    required this.onBack,
    required this.onToggleVoice,
  });

  final bool setup;
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
                Text(
                  setup ? 'CALIBRATING' : 'TRACKING',
                  style: nunito(11, weight: FontWeight.w900, letterSpacing: 1.1),
                ),
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
  const _SetupChecks({required this.progress});

  final int progress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 20),
      child: Column(
        spacing: 8,
        children: [
          for (final (i, label) in _setupChecks.indexed)
            Builder(
              builder: (context) {
                final ok = progress > i * 3 + 2;
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
