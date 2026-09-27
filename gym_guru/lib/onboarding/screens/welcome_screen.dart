import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../onboarding_controller.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key, required this.nav});

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
                  padding: const EdgeInsets.fromLTRB(26, 10, 26, 0),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .08),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          'GYM GURU',
                          style: baloo(15, color: Colors.white, letterSpacing: 2.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const _Hero(),
                      const SizedBox(height: 8),
                      Text.rich(
                        TextSpan(
                          text: 'Your AI trainer. ',
                          children: [
                            TextSpan(
                              text: '5 minutes',
                              style: baloo(40, height: 1.02, color: AppColors.pinkSoft),
                            ),
                            const TextSpan(text: ' a day.'),
                          ],
                        ),
                        textAlign: TextAlign.center,
                        style: baloo(40, height: 1.02, color: Colors.white),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Guru watches your form through the camera, counts every rep, '
                        'and teaches you one new skill daily.',
                        textAlign: TextAlign.center,
                        style: nunito(
                          16,
                          weight: FontWeight.w600,
                          height: 1.45,
                          color: AppColors.textOnDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 12),
                child: Column(
                  children: [
                    ChunkyButton(label: "Let's get started", fontSize: 20, onPressed: nav.next),
                    const SizedBox(height: 5),
                    const GhostButton(label: 'I already have an account'),
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

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 350,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          _circle(290, .22),
          _circle(210, .25),
          Image.asset('assets/mascot/lift.png', width: 270, semanticLabel: 'Guru lifting'),
          const Positioned(
            left: 0,
            top: 44,
            child: Sticker(
              text: 'REPS 12',
              angle: -6,
              bg: AppColors.lime,
              fg: AppColors.ink,
              shadow: AppColors.limeDark,
            ),
          ),
          const Positioned(
            right: 0,
            top: 120,
            child: Sticker(
              text: 'FORM 94%',
              angle: 5,
              bg: Colors.white,
              fg: AppColors.pinkDark,
              shadow: Color(0xFFE7C6DA),
            ),
          ),
          const Positioned(
            left: 14,
            bottom: 30,
            child: Sticker(
              text: '7-DAY STREAK',
              angle: 4,
              bg: AppColors.orange,
              fg: Colors.white,
              shadow: AppColors.orangeDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _circle(double size, double opacity) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: AppColors.pink.withValues(alpha: opacity),
    ),
  );
}
