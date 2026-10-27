import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../onboarding_controller.dart';

enum _NodeState { current, unlocked, locked }

class SkillPathScreen extends StatelessWidget {
  const SkillPathScreen({super.key, required this.nav});

  final FlowNav nav;

  // (label, left inset, state) — insets zig-zag the path.
  static const _nodes = [
    ('Hip hinge', 12.0, _NodeState.current),
    ('Squat depth', 100.0, _NodeState.unlocked),
    ('Core bracing', 160.0, _NodeState.unlocked),
    ('Push-up form', 100.0, _NodeState.unlocked),
    ('Pull mechanics', 12.0, _NodeState.locked),
    ('Mobility flow', 100.0, _NodeState.locked),
  ];

  @override
  Widget build(BuildContext context) {
    return FlowPage(
      header: OnboardingHeader(step: 5, onBack: nav.back),
      footer: ChunkyButton(label: 'Continue', onPressed: nav.next),
      spacing: 16,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Skills you'll master", style: baloo(30, height: 1.05)),
                  const SizedBox(height: 4),
                  Text(
                    'One micro-lesson at a time. 40+ skills on your path.',
                    style: nunito(
                      15,
                      weight: FontWeight.w600,
                      height: 1.35,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Image.asset('assets/mascot/summit.png', width: 104),
          ],
        ),
        LayoutBuilder(
          builder: (context, box) {
            // Keep the zig-zag inside narrow screens (node + label ≈ 190px).
            final scale = ((box.maxWidth - 190) / 160).clamp(0.0, 1.0);
            return Column(
              spacing: 14,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (i, n) in _nodes.indexed)
                  Padding(
                    padding: EdgeInsets.only(left: n.$2 * scale),
                    child: _Node(index: i + 1, label: n.$1, state: n.$3),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _Node extends StatelessWidget {
  const _Node({required this.index, required this.label, required this.state});

  final int index;
  final String label;
  final _NodeState state;

  @override
  Widget build(BuildContext context) {
    final (bg, shadow, fg) = switch (state) {
      _NodeState.current => (AppColors.pink, AppColors.pinkDark, Colors.white),
      _NodeState.unlocked => (AppColors.purple, AppColors.purpleDark, Colors.white),
      _NodeState.locked => (
        const Color(0xFFE8DAF0),
        const Color(0xFFD2BEDD),
        const Color(0xFFA893B5),
      ),
    };
    final current = state == _NodeState.current;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 58,
          height: 58,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            boxShadow: [
              if (current) const BoxShadow(color: Color(0xFFFFD3E8), spreadRadius: 6),
              BoxShadow(color: shadow, offset: const Offset(0, 6)),
            ],
          ),
          child: Text('$index', style: baloo(26, color: fg)),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (current)
              Text(
                'START HERE',
                style: nunito(
                  11,
                  weight: FontWeight.w900,
                  letterSpacing: 1.3,
                  color: AppColors.pink,
                ),
              ),
            Text(
              label,
              style: nunito(
                17,
                color: state == _NodeState.locked ? const Color(0xFFA893B5) : AppColors.ink,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
