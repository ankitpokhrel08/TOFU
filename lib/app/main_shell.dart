import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/auth.dart';
import '../game/levels.dart';
import '../game/progression.dart';
import '../theme/app_theme.dart';
import '../tracking/tracker.dart';
import 'app_controller.dart';
import 'screens/home_screen.dart';
import 'screens/leaderboard_screen.dart';
import 'screens/learn_screen.dart';
import 'screens/levels_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/stats_screen.dart';

/// Main app: Today / Levels / Ranks / Progress tabs.
class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.app, required this.auth, required this.trackerFactory});

  final AppController app;
  final AuthService auth;

  /// Tracker used for each workout. The real camera in the app.
  final TrackerFactory trackerFactory;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _tab = 0;

  AppController get _app => widget.app;

  void _push(Widget screen) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));

  void _playLevel(GameLevel level) => _push(
    LearnScreen(
      app: _app,
      trackerFactory: widget.trackerFactory,
      kind: SessionKind.level,
      level: level,
      title: level.title,
      blocks: _app.blocksFor(level),
    ),
  );

  void _playDrill(Drill drill) => _push(
    LearnScreen(
      app: _app,
      trackerFactory: widget.trackerFactory,
      kind: SessionKind.drill,
      title: drill.title,
      blocks: [drill.block],
    ),
  );

  void _openProfile() => _push(ProfileScreen(app: _app, auth: widget.auth));

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: ListenableBuilder(
            listenable: _app,
            builder: (context, _) => IndexedStack(
              index: _tab,
              children: [
                HomeScreen(
                  app: _app,
                  onPlayLevel: _playLevel,
                  onPlayDrill: _playDrill,
                  onOpenProfile: _openProfile,
                ),
                LevelsScreen(app: _app, onPlay: _playLevel),
                LeaderboardScreen(app: _app, visible: _tab == 2),
                StatsScreen(app: _app),
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
    ('Levels', BoxShape.rectangle, 6.0, math.pi / 4),
    ('Ranks', BoxShape.rectangle, 2.0, math.pi / 4 / 3),
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
            children: [
              for (final (i, (label, shape, radius, angle)) in _tabs.indexed)
                Expanded(
                  child: Semantics(
                    container: true,
                    button: true,
                    selected: i == index,
                    label: label,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onSelect(i),
                      child: ExcludeSemantics(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
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
                ),
            ],
          ),
        ),
      ),
    );
  }
}
