import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../onboarding_controller.dart';

/// "Aha #2": the 5-minute micro-lesson format.
class LessonsScreen extends StatelessWidget {
  const LessonsScreen({super.key, required this.nav, required this.c});

  final FlowNav nav;
  final OnboardingController c;

  @override
  Widget build(BuildContext context) {
    return FlowPage(
      header: OnboardingHeader(step: 4, onBack: nav.back),
      footer: ChunkyButton(label: 'I can do 5 minutes', onPressed: nav.next),
      children: [
        if (c.showAhaTags) const AhaTag('AHA #2 · MICRO-LESSONS'),
        Text("5 minutes. Every day. That's the whole trick.", style: baloo(32, height: 1.02)),
        Padding(
          padding: const EdgeInsets.only(top: 36),
          child: Stack(
            fit: StackFit.passthrough,
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.purple,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: hardShadow(AppColors.purpleDark, 6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Eyebrow('TODAY · LESSON 1', color: AppColors.purpleMuted),
                    const SizedBox(height: 4),
                    Text('Hip hinge 101', style: baloo(28, height: 1.1, color: Colors.white)),
                    const SizedBox(height: 16),
                    const Column(
                      spacing: 10,
                      children: [
                        _Step(
                          n: 1,
                          label: 'Learn the move',
                          time: '1 min',
                          bg: Colors.white,
                          fg: AppColors.purple,
                        ),
                        _Step(
                          n: 2,
                          label: 'Practice on camera',
                          time: '3 min',
                          bg: AppColors.lime,
                          fg: AppColors.ink,
                        ),
                        _Step(
                          n: 3,
                          label: 'Quick form check',
                          time: '1 min',
                          bg: AppColors.pinkSoft,
                          fg: Colors.white,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                right: -6,
                top: -46,
                child: Image.asset('assets/mascot/music.png', width: 118),
              ),
            ],
          ),
        ),
        const IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 10,
            children: [
              Expanded(
                child: _Fact(
                  title: 'One skill',
                  body: 'per day, never a firehose',
                  color: AppColors.pink,
                ),
              ),
              Expanded(
                child: _Fact(
                  title: 'Anywhere',
                  body: 'living room, gym, hotel',
                  color: AppColors.purple,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.n,
    required this.label,
    required this.time,
    required this.bg,
    required this.fg,
  });

  final int n;
  final String label;
  final String time;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
            child: Text(
              '$n',
              style: nunito(15, weight: FontWeight.w900, color: fg),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: nunito(15, color: Colors.white)),
          ),
          Text(time, style: nunito(13, color: AppColors.purpleMuted)),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.title, required this.body, required this.color});

  final String title;
  final String body;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.line, width: 2),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: baloo(22, color: color)),
          Text(
            body,
            style: nunito(13, weight: FontWeight.w700, height: 1.3, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
