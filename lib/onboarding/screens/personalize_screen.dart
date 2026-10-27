import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../onboarding_controller.dart';

class PersonalizeScreen extends StatelessWidget {
  const PersonalizeScreen({super.key, required this.nav, required this.c});

  final FlowNav nav;
  final OnboardingController c;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) => FlowPage(
        header: OnboardingHeader(step: 6, onBack: nav.back),
        footer: ChunkyButton(label: 'Continue', onPressed: nav.next),
        children: [
          const SpeechBubble(
            image: 'assets/mascot/water.png',
            imageWidth: 84,
            text: 'Even 3 minutes counts. Seriously.',
          ),
          Text('How much time can you give me daily?', style: baloo(28, height: 1.08)),
          Column(
            spacing: 10,
            children: [
              for (var row = 0; row < timeOptions.length; row += 2)
                Row(
                  spacing: 10,
                  children: [
                    for (final o in timeOptions.sublist(row, row + 2))
                      Expanded(
                        child: _TimeCard(
                          option: o,
                          selected: c.minutes == o.minutes,
                          onTap: () => c.setMinutes(o.minutes),
                        ),
                      ),
                  ],
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text('Your experience', style: nunito(17)),
          ),
          _LevelPicker(value: c.level, onChanged: c.setLevel),
        ],
      ),
    );
  }
}

class _TimeCard extends StatelessWidget {
  const _TimeCard({required this.option, required this.selected, required this.onTap});

  final TimeOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.passthrough,
      clipBehavior: Clip.none,
      children: [
        SelectableCard(
          selected: selected,
          onTap: onTap,
          radius: 20,
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${option.minutes} min',
                style: baloo(30, height: 1, color: selected ? AppColors.pinkDark : AppColors.ink),
              ),
              const SizedBox(height: 4),
              Text(
                option.label,
                style: nunito(14, weight: FontWeight.w700, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        if (option.recommended)
          Positioned(
            top: -10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.purple,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                'RECOMMENDED',
                style: nunito(10, weight: FontWeight.w900, letterSpacing: .8, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}

/// Segmented control for experience level.
class _LevelPicker extends StatelessWidget {
  const _LevelPicker({required this.value, required this.onChanged});

  final Level value;
  final ValueChanged<Level> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColors.lavender, borderRadius: BorderRadius.circular(16)),
      child: Row(
        spacing: 4,
        children: [
          for (final l in Level.values)
            Expanded(
              child: Semantics(
                container: true,
                button: true,
                selected: l == value,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(l),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: l == value ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: l == value ? hardShadow(const Color(0xFFE2D0EC), 2) : null,
                    ),
                    child: Text(
                      l.label,
                      style: nunito(14, color: l == value ? AppColors.ink : AppColors.textFaint),
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
