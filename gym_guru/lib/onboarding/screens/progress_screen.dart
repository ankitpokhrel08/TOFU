import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../onboarding_controller.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key, required this.nav});

  final FlowNav nav;

  @override
  Widget build(BuildContext context) {
    return FlowPage(
      header: OnboardingHeader(step: 9, onBack: nav.back),
      footer: ChunkyButton(label: 'Build my plan', onPressed: nav.next),
      bodyPadding: const EdgeInsets.fromLTRB(22, 16, 22, 8),
      children: [
        Text('Watch yourself level up. Then flex it.', style: baloo(29, height: 1.05)),
        const _FormScoreChart(),
        const SizedBox(height: 210, child: Center(child: _ShareCard())),
        const Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [_Chip('Share to Story', primary: true), _Chip('Message'), _Chip('Copy link')],
        ),
      ],
    );
  }
}

class _FormScoreChart extends StatelessWidget {
  const _FormScoreChart();

  // (score, bar height fraction, bar color, label color, has shadow)
  static const _weeks = [
    (62, .42, AppColors.track, AppColors.textFaint, false),
    (71, .55, Color(0xFFFFC2DF), AppColors.textFaint, false),
    (84, .70, AppColors.pinkSoft, AppColors.pink, false),
    (91, .82, AppColors.pink, AppColors.pinkDark, true),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.line, width: 2),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('Form score', style: nunito(15)),
              Text(
                'example · first month',
                style: nunito(12, weight: FontWeight.w700, color: AppColors.textFaint),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 110,
            child: Row(
              spacing: 12,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final (i, w) in _weeks.indexed)
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, box) => Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        spacing: 4,
                        children: [
                          Text('${w.$1}', style: nunito(13, color: w.$4)),
                          Container(
                            // Scale so the tallest bar fills the space left by the labels.
                            height: (box.maxHeight - 48) * w.$2 / _weeks.last.$2,
                            decoration: BoxDecoration(
                              color: w.$3,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: w.$5 ? hardShadow(AppColors.pinkDark, 4) : null,
                            ),
                          ),
                          Text(
                            'W${i + 1}',
                            style: nunito(11, weight: FontWeight.w700, color: AppColors.textFaint),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareCard extends StatelessWidget {
  const _ShareCard();

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -4 * math.pi / 180,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 250,
            height: 196,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.ink,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: AppColors.ink.withValues(alpha: .5),
                  offset: const Offset(0, 14),
                  blurRadius: 28,
                  spreadRadius: -10,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('GYM GURU', style: baloo(13, color: AppColors.pinkSoft, letterSpacing: 2)),
                const SizedBox(height: 8),
                Text('30 day\nstreak', style: baloo(44, height: .95, color: Colors.white)),
                const SizedBox(height: 8),
                Text('Form score 91 · 142 lessons', style: nunito(14, color: AppColors.lime)),
              ],
            ),
          ),
          Positioned(
            right: -26,
            bottom: -14,
            child: Image.asset('assets/mascot/summit.png', width: 118),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label, {this.primary = false});

  final String label;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: primary ? AppColors.pink : AppColors.lavender,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Text(label, style: nunito(13, color: primary ? Colors.white : AppColors.ink)),
        ),
      ),
    );
  }
}
