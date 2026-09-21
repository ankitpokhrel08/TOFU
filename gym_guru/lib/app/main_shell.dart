import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import 'app_controller.dart';
import 'screens/home_screen.dart';
import 'screens/learn_screen.dart';
import 'screens/path_screen.dart';
import 'screens/stats_screen.dart';

/// Main app: Today / Path / Progress tabs.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final _controller = AppController();
  int _tab = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openLesson() =>
      Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => LearnScreen(app: _controller)));

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: ListenableBuilder(
            listenable: _controller,
            builder: (context, _) => IndexedStack(
              index: _tab,
              children: [
                HomeScreen(app: _controller, onStartLesson: _openLesson),
                PathScreen(app: _controller, onStartLesson: _openLesson),
                StatsScreen(app: _controller),
              ],
            ),
          ),
        ),
        bottomNavigationBar: _TabBar(index: _tab, onSelect: (i) => setState(() => _tab = i)),
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({required this.index, required this.onSelect});

  final int index;
  final ValueChanged<int> onSelect;

  static const _tabs = [
    ('Today', BoxShape.circle, 0.0, 0.0),
    ('Path', BoxShape.rectangle, 6.0, math.pi / 4),
    ('Progress', BoxShape.rectangle, 4.0, 0.0),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.track, width: 2)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (final (i, (label, shape, radius, angle)) in _tabs.indexed)
                Semantics(
                  container: true,
                  button: true,
                  selected: i == index,
                  label: label,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onSelect(i),
                    child: ExcludeSemantics(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          spacing: 5,
                          children: [
                            Transform.rotate(
                              angle: angle,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: i == index ? AppColors.pink : AppColors.textGhost,
                                  shape: shape,
                                  borderRadius: shape == BoxShape.circle
                                      ? null
                                      : BorderRadius.circular(radius),
                                ),
                              ),
                            ),
                            Text(
                              label,
                              style: nunito(
                                12,
                                color: i == index ? AppColors.pink : AppColors.textGhost,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
