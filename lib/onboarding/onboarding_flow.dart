import 'package:flutter/material.dart';

import '../data/models.dart';
import 'onboarding_controller.dart';
import 'screens/form_check_screen.dart';
import 'screens/goals_screen.dart';
import 'screens/limitations_screen.dart';
import 'screens/name_screen.dart';
import 'screens/personalize_screen.dart';
import 'screens/plan_ready_screen.dart';

/// Profile setup after sign-in: name → goal → time & experience →
/// limitations → form-check demo → plan ready.
class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key, required this.initialName, required this.onDone, this.onExit});

  /// Prefill from the Google account.
  final String initialName;

  /// Saves the profile and enters the app.
  final Future<void> Function(Profile profile) onDone;

  /// Back from the first step (signs out).
  final VoidCallback? onExit;

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  static const _curve = Cubic(0.2, 0.8, 0.2, 1);
  static const _count = 6;

  final _pages = PageController();
  late final _controller = OnboardingController(name: widget.initialName);
  int _index = 0;
  bool _saving = false;

  void _go(int i) {
    if (i < 0) return widget.onExit?.call();
    if (i >= _count) {
      _finish();
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _index = i);
    _pages.animateToPage(i, duration: const Duration(milliseconds: 500), curve: _curve);
  }

  Future<void> _finish() async {
    if (_saving) return;
    _saving = true;
    try {
      await widget.onDone(_controller.toProfile(DateTime.now()));
    } finally {
      _saving = false;
    }
  }

  @override
  void dispose() {
    _pages.dispose();
    _controller.dispose();
    super.dispose();
  }

  Widget _screen(int i) {
    final nav = FlowNav(next: () => _go(i + 1), back: () => _go(i - 1), step: i + 1, total: _count);
    final c = _controller;
    return switch (i) {
      0 => NameScreen(nav: nav, c: c),
      1 => GoalsScreen(nav: nav, c: c),
      2 => PersonalizeScreen(nav: nav, c: c),
      3 => LimitationsScreen(nav: nav, c: c),
      4 => FormCheckScreen(nav: nav, c: c),
      _ => PlanReadyScreen(nav: nav, c: c),
    };
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
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
