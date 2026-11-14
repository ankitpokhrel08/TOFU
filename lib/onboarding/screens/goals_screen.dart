import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../onboarding_controller.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key, required this.nav, required this.c});

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
          SpeechBubble(
            image: 'assets/mascot/cheer.png',
            imageWidth: 92,
            bubbleLift: 18,
            text: 'Nice to meet you, ${c.name}! What brings you here?',
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('What should we work on?', style: baloo(28, height: 1.1)),
              const SizedBox(height: 4),
              Text(
                'Pick your main goal. It shapes your bonus drills.',
                style: nunito(15, weight: FontWeight.w600, color: AppColors.textMuted),
              ),
            ],
          ),
          Column(
            spacing: 10,
            children: [
              for (final g in goals)
                _GoalTile(goal: g, selected: c.goal == g.id, onTap: () => c.setGoal(g.id)),
            ],
          ),
        ],
      ),
    );
  }
}

class _GoalTile extends StatelessWidget {
  const _GoalTile({required this.goal, required this.selected, required this.onTap});

  final Goal goal;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bd = selected ? AppColors.pink : AppColors.line;
    return SelectableCard(
      selected: selected,
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(goal.title, style: nunito(16)),
                Text(
                  goal.subtitle,
                  style: nunito(13, weight: FontWeight.w600, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: selected ? AppColors.pink : Colors.white,
              border: Border.all(color: bd, width: 2),
              shape: BoxShape.circle,
            ),
            child: selected ? const Icon(Icons.check_rounded, size: 17, color: Colors.white) : null,
          ),
        ],
      ),
    );
  }
}
