import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../onboarding_controller.dart';

const _benefits = [
  ('Unlimited lessons', 'every skill, every day'),
  ('Personalized paths', 'built around your goals'),
  ('Advanced analytics', 'form trends, rep history'),
  ('Exclusive content', 'pro programs & drills'),
  ('Challenges', 'compete with friends'),
];

class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key, required this.nav, required this.c});

  final FlowNav nav;
  final OnboardingController c;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        final annual = c.plan == Plan.annual;
        return ColoredBox(
          color: AppColors.cream,
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(22, 0, 22, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 14,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              onPressed: nav.back,
                              tooltip: 'Close',
                              icon: const Icon(Icons.close_rounded, color: AppColors.textGhost),
                            ),
                            TextButton(
                              onPressed: () {},
                              child: Text('Restore', style: nunito(13, color: AppColors.textFaint)),
                            ),
                          ],
                        ),
                        Transform.translate(
                          offset: const Offset(0, -8),
                          child: Row(
                            spacing: 6,
                            children: [
                              Image.asset('assets/mascot/cheer.png', width: 104),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Eyebrow('GURU PREMIUM', color: AppColors.pink),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Your plan is ready. Start free.',
                                      style: baloo(28, height: 1.02),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          spacing: 9,
                          children: [for (final (t, d) in _benefits) _Benefit(title: t, detail: d)],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: _PlanOption(
                            selected: annual,
                            onTap: () => c.setPlan(Plan.annual),
                            badge: 'BEST VALUE · SAVE 58%',
                            title: 'Annual',
                            subtitle: '7 days free, then \$59.99/yr',
                            price: '\$4.99',
                          ),
                        ),
                        _PlanOption(
                          selected: !annual,
                          onTap: () => c.setPlan(Plan.monthly),
                          title: 'Monthly',
                          subtitle: 'Billed monthly',
                          price: '\$11.99',
                        ),
                        if (annual && c.showTrialTimeline) const _TrialTimeline(),
                      ],
                    ),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.cream,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.ink.withValues(alpha: .12),
                        offset: const Offset(0, -10),
                        blurRadius: 20,
                        spreadRadius: -10,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 10, 22, 12),
                    child: Column(
                      children: [
                        ChunkyButton(
                          label: annual ? 'Start my 7-day free trial' : 'Continue with Monthly',
                          height: 60,
                          onPressed: annual ? nav.startTrial : nav.next,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          annual
                              ? 'Free for 7 days, then \$59.99/year. Cancel anytime.'
                              : '\$11.99/month, billed today. Cancel anytime.',
                          textAlign: TextAlign.center,
                          style: nunito(12, weight: FontWeight.w700, color: AppColors.textFaint),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.title, required this.detail});

  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(color: AppColors.pink, shape: BoxShape.circle),
          child: const Icon(Icons.check_rounded, size: 15, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: title,
                  style: nunito(15, weight: FontWeight.w900),
                ),
                const TextSpan(text: ' '),
                TextSpan(
                  text: detail,
                  style: nunito(15, weight: FontWeight.w700, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PlanOption extends StatelessWidget {
  const _PlanOption({
    required this.selected,
    required this.onTap,
    required this.title,
    required this.subtitle,
    required this.price,
    this.badge,
  });

  final bool selected;
  final VoidCallback onTap;
  final String title;
  final String subtitle;
  final String price;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final bd = selected ? AppColors.pink : AppColors.line;
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Stack(
          fit: StackFit.passthrough,
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: badge != null ? 16 : 14),
              decoration: BoxDecoration(
                color: selected ? AppColors.pinkTint : Colors.white,
                border: Border.all(color: bd, width: 2.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: bd, width: 2.5),
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected ? AppColors.pink : Colors.transparent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: nunito(17)),
                        Text(
                          subtitle,
                          style: nunito(13, weight: FontWeight.w700, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(price, style: baloo(20, height: 1)),
                      Text(
                        '/month',
                        style: nunito(12, weight: FontWeight.w700, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (badge != null)
              Positioned(
                top: -11,
                left: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.purple,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    badge!,
                    style: nunito(
                      10,
                      weight: FontWeight.w900,
                      letterSpacing: .8,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TrialTimeline extends StatelessWidget {
  const _TrialTimeline();

  static const _items = [
    ('Today', 'Full access unlocked', AppColors.pink),
    ('Day 5', "We'll remind you", AppColors.pinkSoft),
    ('Day 7', 'Trial ends, cancel anytime before', AppColors.purple),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
      child: Column(
        children: [
          for (final (i, (title, detail, color)) in _items.indexed)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    if (i < _items.length - 1)
                      Container(width: 2, height: 22, color: const Color(0xFFF0C6DC)),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Transform.translate(
                    offset: const Offset(0, -2),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: title,
                            style: nunito(13, weight: FontWeight.w900),
                          ),
                          TextSpan(
                            text: ' · $detail',
                            style: nunito(13, weight: FontWeight.w700, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
