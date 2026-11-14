import 'package:flutter/material.dart';

import '../../game/exercises.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../onboarding_controller.dart';

const _details = {
  Limitation.knees: 'Swaps lunges and jumping for bridges, eases squat depth',
  Limitation.back: 'Shortens plank holds',
};

/// Areas to go easy on. Changes which moves appear and how strict they are.
class LimitationsScreen extends StatelessWidget {
  const LimitationsScreen({super.key, required this.nav, required this.c});

  final FlowNav nav;
  final OnboardingController c;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) => FlowPage(
        header: OnboardingHeader(step: nav.step, total: nav.total, onBack: nav.back),
        footer: ChunkyButton(label: 'Continue', onPressed: nav.next),
        children: [
          const SpeechBubble(
            image: 'assets/mascot/zen.png',
            text: "Anything sore? I'll adjust your workouts.",
          ),
          Text('Any pain or limits?', style: baloo(28, height: 1.1)),
          Column(
            spacing: 10,
            children: [
              for (final l in Limitation.values)
                _Option(
                  title: l.label,
                  subtitle: _details[l]!,
                  selected: c.limitations.contains(l),
                  onTap: () => c.toggleLimitation(l),
                ),
              _Option(
                title: 'None, all good',
                subtitle: 'Full workouts',
                selected: c.limitations.isEmpty,
                onTap: c.clearLimitations,
              ),
            ],
          ),
          Text(
            'Gym Guru is not medical advice. Stop if anything hurts and check with a professional.',
            style: nunito(12, weight: FontWeight.w600, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SelectableCard(
      selected: selected,
      onTap: onTap,
      child: Row(
        spacing: 14,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: nunito(16)),
                Text(
                  subtitle,
                  style: nunito(13, weight: FontWeight.w600, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Icon(
            selected ? Icons.check_circle_rounded : Icons.circle_outlined,
            color: selected ? AppColors.pink : AppColors.line,
            size: 26,
          ),
        ],
      ),
    );
  }
}
