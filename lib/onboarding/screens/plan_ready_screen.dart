import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../onboarding_controller.dart';

const _steps = [
  'Matching lessons to your goals',
  'Calibrating pose tracking',
  'Picking your first 7 skills',
];

class PlanReadyScreen extends StatefulWidget {
  const PlanReadyScreen({super.key, required this.nav, required this.c});

  final FlowNav nav;
  final OnboardingController c;

  @override
  State<PlanReadyScreen> createState() => _PlanReadyScreenState();
}

class _PlanReadyScreenState extends State<PlanReadyScreen> {
  Timer? _timer;
  int _progress = 0;

  // One extra tick after the last step before revealing the plan.
  bool get _done => _progress > _steps.length;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 800), (t) {
      setState(() => _progress++);
      if (_done) t.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    return FlowPage(
      header: OnboardingHeader(step: 10, onBack: widget.nav.back),
      footer: ChunkyButton(label: 'Unlock my plan', onPressed: _done ? widget.nav.next : null),
      bodyPadding: const EdgeInsets.fromLTRB(22, 16, 22, 8),
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset('assets/mascot/lift.png', width: 170),
        Text(
          _done ? 'Your plan is ready!' : 'Building your plan…',
          textAlign: TextAlign.center,
          style: baloo(30, height: 1.05),
        ),
        Column(
          spacing: 8,
          children: [
            for (final (i, t) in _steps.indexed) _BuildStep(label: t, done: _progress > i),
          ],
        ),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 500),
          curve: const Cubic(.2, .8, .2, 1),
          opacity: _done ? 1 : 0,
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 500),
            curve: const Cubic(.2, .8, .2, 1),
            offset: _done ? Offset.zero : const Offset(0, .12),
            child: _PlanCard(name: c.planName, minutes: c.minutes, level: c.level.short),
          ),
        ),
      ],
    );
  }
}

class _BuildStep extends StatelessWidget {
  const _BuildStep({required this.label, required this.done});

  final String label;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? AppColors.pink : Colors.transparent,
            border: Border.all(color: done ? AppColors.pink : AppColors.disabled, width: 2),
          ),
          child: done ? const Icon(Icons.check_rounded, size: 15, color: Colors.white) : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style: nunito(15, color: done ? AppColors.ink : AppColors.textGhost),
            child: Text(label),
          ),
        ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.name, required this.minutes, required this.level});

  final String name;
  final int minutes;
  final String level;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.purple,
        borderRadius: BorderRadius.circular(24),
        boxShadow: hardShadow(AppColors.purpleDark, 6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Eyebrow('YOUR 30-DAY PLAN', color: AppColors.purpleMuted),
          const SizedBox(height: 2),
          Text(name, style: baloo(24, height: 1.1, color: Colors.white)),
          const SizedBox(height: 12),
          Row(
            spacing: 8,
            children: [
              _Stat(value: '$minutes min', label: 'per day'),
              _Stat(value: level, label: 'level'),
              const _Stat(value: '30', label: 'skills'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .14),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: baloo(18, color: Colors.white)),
            Text(
              label,
              style: nunito(11, weight: FontWeight.w700, color: AppColors.purpleMuted),
            ),
          ],
        ),
      ),
    );
  }
}
