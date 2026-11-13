import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../onboarding_controller.dart';

class SuccessScreen extends StatelessWidget {
  const SuccessScreen({super.key, required this.nav});

  final FlowNav nav;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: ColoredBox(
        color: AppColors.ink,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(26, 30, 26, 0),
                  child: Column(
                    spacing: 14,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: Stack(
                          alignment: Alignment.topCenter,
                          clipBehavior: Clip.none,
                          children: [
                            const Positioned.fill(child: _Confetti()),
                            const Image(image: AssetImage('assets/mascot/summit.png'), width: 230),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          "You're in, champ!",
                          textAlign: TextAlign.center,
                          style: baloo(38, height: 1, color: Colors.white),
                        ),
                      ),
                      Text(
                        'Premium unlocked. Day 1 of your streak starts now.',
                        textAlign: TextAlign.center,
                        style: nunito(
                          16,
                          weight: FontWeight.w600,
                          height: 1.4,
                          color: AppColors.textOnDark,
                        ),
                      ),
                      const Padding(padding: EdgeInsets.only(top: 8), child: _TodayCard()),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 12),
                child: Column(
                  children: [
                    ChunkyButton(
                      label: 'Start lesson 1',
                      color: AppColors.lime,
                      shadowColor: AppColors.limeDark,
                      textColor: AppColors.ink,
                      onPressed: nav.enterApp,
                    ),
                    const SizedBox(height: 5),
                    const GhostButton(label: 'Share my Day 1'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        spacing: 14,
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.pink,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text('1', style: baloo(22, color: Colors.white)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Eyebrow("TODAY'S LESSON", color: AppColors.pinkSoft),
                Text('Hip hinge 101 · 5 min', style: nunito(17, color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Static confetti scattered around the mascot.
class _Confetti extends StatelessWidget {
  const _Confetti();

  @override
  Widget build(BuildContext context) {
    Widget piece({
      double? left,
      double? right,
      required double top,
      required double size,
      required Color color,
      double radius = 0,
      double angle = 0,
      bool circle = false,
    }) => Positioned(
      left: left,
      right: right,
      top: top,
      child: Transform.rotate(
        angle: angle * math.pi / 180,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: circle ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: circle ? null : BorderRadius.circular(radius),
          ),
        ),
      ),
    );

    return Stack(
      children: [
        piece(left: 14, top: 30, size: 14, color: AppColors.lime, radius: 3, angle: 20),
        piece(right: 26, top: 60, size: 12, color: AppColors.pinkSoft, circle: true),
        piece(left: 40, top: 170, size: 10, color: AppColors.yellow, radius: 2, angle: 45),
        piece(right: 30, top: 150, size: 16, color: AppColors.purple, radius: 4, angle: -15),
        piece(right: 94, top: 10, size: 9, color: AppColors.orange, circle: true),
      ],
    );
  }
}
