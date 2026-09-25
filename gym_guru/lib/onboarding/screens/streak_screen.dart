import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/decor.dart';
import '../onboarding_controller.dart';

class StreakScreen extends StatefulWidget {
  const StreakScreen({super.key, required this.nav});

  final FlowNav nav;

  @override
  State<StreakScreen> createState() => _StreakScreenState();
}

class _StreakScreenState extends State<StreakScreen> {
  static const _demoDays = 5;
  Timer? _timer;
  int _days = 0;

  @override
  void initState() {
    super.initState();
    // Tick the week in one day at a time to show the streak growing.
    _timer = Timer.periodic(const Duration(milliseconds: 800), (t) {
      setState(() => _days++);
      if (_days >= _demoDays) t.cancel();
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
      header: OnboardingHeader(step: 8, onBack: widget.nav.back),
      footer: ChunkyButton(label: "I'm in", onPressed: widget.nav.next),
      bodyPadding: const EdgeInsets.fromLTRB(22, 14, 22, 8),
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Center(child: _Flame(count: _days)),
        ),
        Column(
          children: [
            Text(
              'Keep the flame alive',
              textAlign: TextAlign.center,
              style: baloo(30, height: 1.05),
            ),
            const SizedBox(height: 6),
            Text(
              "One lesson a day grows your streak. Miss a day and it resets — that's what makes it work.",
              textAlign: TextAlign.center,
              style: nunito(15, weight: FontWeight.w600, height: 1.4, color: AppColors.textMuted),
            ),
          ],
        ),
        OutlinedCard(
          padding: const EdgeInsets.all(12),
          radius: 20,
          child: WeekStrip(done: _days, ringAt: _days),
        ),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Eyebrow('MILESTONES TO SHARE'),
            SizedBox(height: 8),
            Row(
              spacing: 8,
              children: [
                _Milestone('7', 'Spark', Color(0xFFFFE9D6), Color(0xFFE26F0A), Color(0xFF9A6A3D)),
                _Milestone('30', 'Blaze', Color(0xFFFFE0EF), Color(0xFFE0217F), Color(0xFFA0476F)),
                _Milestone(
                  '100',
                  'Inferno',
                  AppColors.purpleTint,
                  AppColors.purple,
                  Color(0xFF6A4D9C),
                ),
                _Milestone('365', 'Legend', AppColors.ink, AppColors.yellow, AppColors.textOnDark),
              ],
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF4FF),
            border: Border.all(color: const Color(0xFFD6E2FA), width: 2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Image.asset('assets/mascot/sleep.png', width: 76),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Streak Freeze', style: nunito(15)),
                    Text(
                      'Rest days happen. A freeze protects your streak while you recover.',
                      style: nunito(
                        13,
                        weight: FontWeight.w600,
                        height: 1.35,
                        color: const Color(0xFF5C6B8A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Two stacked teardrops with the streak count on top.
class _Flame extends StatelessWidget {
  const _Flame({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    Widget drop(double size, double top, Color color, [Color? shadow]) => Positioned(
      top: top,
      child: Teardrop(size: size, color: color, shadow: shadow),
    );

    return SizedBox(
      width: 150,
      height: 150,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          drop(104, 34, AppColors.orange, AppColors.orangeDark),
          drop(62, 68, AppColors.yellow),
          Positioned.fill(
            top: 44,
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, a) => ScaleTransition(scale: a, child: child),
                child: Text(
                  '$count',
                  key: ValueKey(count),
                  style: baloo(46, height: 1, color: Colors.white).copyWith(
                    shadows: const [Shadow(color: AppColors.orangeDark, offset: Offset(0, 2))],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Milestone extends StatelessWidget {
  const _Milestone(this.value, this.label, this.bg, this.fg, this.labelColor);

  final String value;
  final String label;
  final Color bg;
  final Color fg;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: StatTile(
        value: value,
        label: label,
        background: bg,
        valueColor: fg,
        labelColor: labelColor,
        valueSize: 24,
        labelSize: 11,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        radius: 16,
        centered: true,
      ),
    );
  }
}
