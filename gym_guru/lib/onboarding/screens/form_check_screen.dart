import 'dart:async';
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/decor.dart';
import '../onboarding_controller.dart';

/// "Aha #1": simulated live pose tracking that flags caving knees mid-set.
class FormCheckScreen extends StatefulWidget {
  const FormCheckScreen({super.key, required this.nav, required this.c});

  final FlowNav nav;
  final OnboardingController c;

  @override
  State<FormCheckScreen> createState() => _FormCheckScreenState();
}

class _FormCheckScreenState extends State<FormCheckScreen> {
  Timer? _timer;
  int _reps = 0;

  // Reps 6–8 of each set of 12 demo a form error.
  bool get _bad => _reps >= 6 && _reps <= 8;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 800), (_) {
      setState(() => _reps = _reps >= 12 ? 1 : _reps + 1);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FlowPage(
      header: OnboardingHeader(step: 3, onBack: widget.nav.back),
      footer: ChunkyButton(label: 'Whoa, cool', onPressed: widget.nav.next),
      spacing: 12,
      children: [
        if (widget.c.showAhaTags) const AhaTag('AHA #1 · AI FORM CHECK'),
        Text('I see every rep. And every mistake.', style: baloo(30, height: 1.05)),
        _CameraCard(reps: _reps, bad: _bad),
        Text(
          'Pose tracking counts your reps and flags form errors in real time '
          '— before they turn into injuries.',
          style: nunito(15, weight: FontWeight.w600, height: 1.45, color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class _CameraCard extends StatelessWidget {
  const _CameraCard({required this.reps, required this.bad});

  final int reps;
  final bool bad;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: SizedBox(
        height: 410,
        child: Stack(
          children: [
            const Positioned.fill(
              child: CustomPaint(
                painter: StripePainter(base: AppColors.inkDeep, stripe: Color(0x0AFFFFFF)),
              ),
            ),
            Positioned(
              top: 40,
              left: 0,
              right: 0,
              child: Center(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: bad ? 1 : 0),
                  duration: const Duration(milliseconds: 250),
                  builder: (_, t, _) =>
                      CustomPaint(size: const Size(220, 330), painter: _SkeletonPainter(t)),
                ),
              ),
            ),
            Positioned(
              left: 16,
              top: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(16),
                ),
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
                    Text(
                      reps.toString().padLeft(2, '0'),
                      style: baloo(38, height: 1, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              right: 16,
              top: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                spacing: 8,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
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
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Text(
                          'LIVE',
                          style: nunito(
                            11,
                            weight: FontWeight.w900,
                            letterSpacing: 1.1,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      'FORM ${bad ? 78 : 94}',
                      style: nunito(13, weight: FontWeight.w900, color: AppColors.ink),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: bad ? AppColors.red : AppColors.green,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  bad ? 'Knees caving in — push them out' : 'Great depth — keep that chest up',
                  style: nunito(15, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pose skeleton drawn in a 200×300 design space. [t] blends knees from
/// good (pushed out) to bad (caving in).
class _SkeletonPainter extends CustomPainter {
  _SkeletonPainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 200, size.height / 300);

    final kneeColor = Color.lerp(AppColors.lime, AppColors.red, t)!;
    final kL = lerpDouble(66, 88, t)!;
    final kR = lerpDouble(134, 112, t)!;

    Paint stroke(Color c, [double w = 4]) => Paint()
      ..color = c
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final body = stroke(AppColors.lime);
    void line(double x1, double y1, double x2, double y2, Paint p) =>
        canvas.drawLine(Offset(x1, y1), Offset(x2, y2), p);

    line(100, 50, 100, 88, body);
    line(75, 88, 125, 88, body);
    line(75, 88, 58, 128, body);
    line(58, 128, 88, 150, body);
    line(125, 88, 142, 128, body);
    line(142, 128, 112, 150, body);
    line(75, 88, 85, 168, body);
    line(125, 88, 115, 168, body);
    line(85, 168, 115, 168, body);

    final legs = stroke(kneeColor);
    line(85, 168, kL, 218, legs);
    line(kL, 218, 70, 272, legs);
    line(115, 168, kR, 218, legs);
    line(kR, 218, 130, 272, legs);

    canvas.drawCircle(const Offset(100, 34), 16, body);

    final jointFill = Paint()..color = Colors.white;
    final jointStroke = stroke(AppColors.lime, 3);
    for (final p in const [
      Offset(75, 88),
      Offset(125, 88),
      Offset(58, 128),
      Offset(142, 128),
      Offset(85, 168),
      Offset(115, 168),
      Offset(70, 272),
      Offset(130, 272),
    ]) {
      canvas.drawCircle(p, 6, jointFill);
      canvas.drawCircle(p, 6, jointStroke);
    }

    final knee = Paint()..color = kneeColor;
    canvas.drawCircle(Offset(kL, 218), 8, knee);
    canvas.drawCircle(Offset(kR, 218), 8, knee);
  }

  @override
  bool shouldRepaint(_SkeletonPainter old) => old.t != t;
}
