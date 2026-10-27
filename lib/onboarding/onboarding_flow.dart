import 'package:flutter/material.dart';

import '../app/main_shell.dart';

import 'onboarding_controller.dart';
import 'screens/form_check_screen.dart';
import 'screens/goals_screen.dart';
import 'screens/lessons_screen.dart';
import 'screens/paywall_screen.dart';
import 'screens/personalize_screen.dart';
import 'screens/plan_ready_screen.dart';
import 'screens/progress_screen.dart';
import 'screens/quiz_screen.dart';
import 'screens/skill_path_screen.dart';
import 'screens/streak_screen.dart';
import 'screens/success_screen.dart';
import 'screens/welcome_screen.dart';

/// Welcome → 10-step onboarding → paywall → success.
class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  static const _curve = Cubic(0.2, 0.8, 0.2, 1);
  static const _count = 12;

  final _pages = PageController();
  final _controller = OnboardingController();
  int _index = 0;

  late final _nav = FlowNav(
    next: () => _go(_index + 1),
    back: () => _go(_index - 1),
    restart: () => _go(0),
    startTrial: _startTrial,
  );

  void _startTrial() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, _, _) => const MainShell(),
        transitionsBuilder: (_, a, _, child) => FadeTransition(opacity: a, child: child),
      ),
    );
  }

  void _go(int i) {
    final target = i.clamp(0, _count - 1);
    if (target == _index) return;
    setState(() => _index = target);
    _pages.animateToPage(target, duration: const Duration(milliseconds: 500), curve: _curve);
  }

  @override
  void dispose() {
    _pages.dispose();
    _controller.dispose();
    super.dispose();
  }

  Widget _screen(int i) => switch (i) {
    0 => WelcomeScreen(nav: _nav),
    1 => GoalsScreen(nav: _nav, c: _controller),
    2 => FormCheckScreen(nav: _nav, c: _controller),
    3 => LessonsScreen(nav: _nav, c: _controller),
    4 => SkillPathScreen(nav: _nav),
    5 => PersonalizeScreen(nav: _nav, c: _controller),
    6 => QuizScreen(nav: _nav, c: _controller),
    7 => StreakScreen(nav: _nav),
    8 => ProgressScreen(nav: _nav),
    9 => PlanReadyScreen(nav: _nav, c: _controller),
    10 => PaywallScreen(nav: _nav, c: _controller),
    _ => SuccessScreen(nav: _nav),
  };

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _go(_index - 1);
      },
      child: Scaffold(
        body: PageView.builder(
          controller: _pages,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _count,
          itemBuilder: (_, i) => _screen(i),
        ),
      ),
    );
  }
}
