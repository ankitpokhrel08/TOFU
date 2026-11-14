import 'package:flutter/material.dart';

import '../../game/levels.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../app_controller.dart';
import 'home_screen.dart' show StarRow;

/// The 20-level map, grouped into units.
class LevelsScreen extends StatelessWidget {
  const LevelsScreen({super.key, required this.app, required this.onPlay});

  final AppController app;
  final ValueChanged<GameLevel> onPlay;

  // Left insets that zig-zag each unit.
  static const _insets = [12.0, 90.0, 150.0, 90.0, 40.0];

  @override
  Widget build(BuildContext context) {
    final stars = app.levelStars;
    final current = app.currentLevel.number;
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 6, 22, 24),
      children: [
        Row(
          spacing: 8,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Levels', style: baloo(28, height: 1.05)),
                  const SizedBox(height: 4),
                  Text(
                    '${app.levelsCleared} of ${gameLevels.length} cleared · '
                    '${app.totalStars}/${gameLevels.length * 3} stars',
                    style: nunito(13, weight: FontWeight.w700, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            Image.asset('assets/mascot/summit.png', width: 90),
          ],
        ),
        for (var u = 0; u < unitNames.length; u++) ...[
          const SizedBox(height: 18),
          _UnitHeader(unit: u + 1, unlocked: app.isUnlocked(u * levelsPerUnit + 1)),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, box) {
              final scale = ((box.maxWidth - 210) / 150).clamp(0.0, 1.0);
              return Column(
                spacing: 14,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < levelsPerUnit; i++)
                    Builder(
                      builder: (context) {
                        final level = gameLevels[u * levelsPerUnit + i];
                        return Padding(
                          padding: EdgeInsets.only(left: _insets[i] * scale),
                          child: _Node(
                            level: level,
                            stars: stars[level.number] ?? 0,
                            unlocked: app.isUnlocked(level.number),
                            current: level.number == current,
                            onTap: () => onPlay(level),
                          ),
                        );
                      },
                    ),
                ],
              );
            },
          ),
        ],
      ],
    );
  }
}

class _UnitHeader extends StatelessWidget {
  const _UnitHeader({required this.unit, required this.unlocked});

  final int unit;
  final bool unlocked;

  static const _new = {
    1: 'Squat · Glute bridge',
    2: '+ Push-up · Plank',
    3: '+ Reverse lunge',
    4: '+ Jumping jacks',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: unlocked ? AppColors.pinkTint : AppColors.lavender,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Eyebrow('UNIT $unit', color: unlocked ? AppColors.pink : AppColors.textFaint),
                Text(unitNames[unit - 1], style: baloo(19, height: 1.1)),
              ],
            ),
          ),
          Text(_new[unit]!, style: nunito(12, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _Node extends StatelessWidget {
  const _Node({
    required this.level,
    required this.stars,
    required this.unlocked,
    required this.current,
    required this.onTap,
  });

  final GameLevel level;
  final int stars;
  final bool unlocked;
  final bool current;
  final VoidCallback onTap;

  static const _lockedFg = Color(0xFFA893B5);

  @override
  Widget build(BuildContext context) {
    final cleared = stars > 0;
    final (bg, shadow) = !unlocked
        ? (const Color(0xFFE8DAF0), const Color(0xFFD2BEDD))
        : cleared
        ? (AppColors.yellow, const Color(0xFFD99A0B))
        : current
        ? (AppColors.pink, AppColors.pinkDark)
        : (AppColors.purple, AppColors.purpleDark);
    final size = level.boss ? 68.0 : 58.0;
    final tag = !unlocked
        ? 'LOCKED'
        : current
        ? 'PLAY NOW'
        : level.boss
        ? 'BOSS'
        : '';

    return Semantics(
      container: true,
      button: unlocked,
      enabled: unlocked,
      label:
          'Level ${level.number}, ${level.title}${level.boss ? ', boss' : ''}, '
          '${unlocked ? '$stars of 3 stars' : 'locked'}',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: unlocked
            ? onTap
            : () => ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text('Pass level ${level.number - 1} to unlock ${level.title}.'),
                  ),
                ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 14,
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                if (current)
                  Container(
                    width: size + 14,
                    height: size + 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFFFD3E8), width: 4),
                    ),
                  ),
                Container(
                  width: size,
                  height: size,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: bg,
                    shape: BoxShape.circle,
                    boxShadow: hardShadow(shadow, 6),
                  ),
                  child: unlocked
                      ? Text('${level.number}', style: baloo(22, color: Colors.white))
                      : const Icon(Icons.lock_rounded, color: _lockedFg, size: 22),
                ),
                if (level.boss)
                  const Positioned(
                    top: -14,
                    child: Icon(Icons.emoji_events_rounded, color: AppColors.orange, size: 24),
                  ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (tag.isNotEmpty)
                  Text(
                    tag,
                    style: nunito(
                      10,
                      weight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: current ? AppColors.pink : _lockedFg,
                    ),
                  ),
                Text(level.title, style: nunito(16, color: unlocked ? AppColors.ink : _lockedFg)),
                if (unlocked) StarRow(stars: stars, size: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
