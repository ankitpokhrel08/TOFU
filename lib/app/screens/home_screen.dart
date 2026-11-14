import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../game/levels.dart';
import '../../game/progression.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/decor.dart';
import '../app_controller.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.app,
    required this.onPlayLevel,
    required this.onPlayDrill,
    required this.onOpenProfile,
  });

  final AppController app;
  final ValueChanged<GameLevel> onPlayLevel;
  final ValueChanged<Drill> onPlayDrill;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final level = app.currentLevel;
    final drill = app.drill;
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 6, 22, 16),
      children: [
        _Header(app: app, onOpenProfile: onOpenProfile),
        const SizedBox(height: 16),
        _DailyGoal(app: app),
        const SizedBox(height: 40),
        _LevelCard(
          level: level,
          blocks: app.blocksFor(level),
          stars: app.levelStars[level.number] ?? 0,
          onPlay: () => onPlayLevel(level),
        ),
        const SizedBox(height: 16),
        _DrillCard(drill: drill, onPlay: () => onPlayDrill(drill)),
        const SizedBox(height: 16),
        OutlinedCard(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text('This week', style: nunito(15)),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      app.freezes > 0
                          ? '${app.freezes} streak freeze${app.freezes == 1 ? '' : 's'} ready'
                          : 'Freeze every $xpPerFreeze XP',
                      textAlign: TextAlign.end,
                      style: nunito(13, color: const Color(0xFF3B7BD8)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              WeekStrip(days: app.week, ringAt: app.todayIndex),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _RankCard(xp: app.xp),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.app, required this.onOpenProfile});

  final AppController app;
  final VoidCallback onOpenProfile;

  String get _timeOfDay {
    final h = app.now.hour;
    return h < 12
        ? 'Good morning'
        : h < 18
        ? 'Good afternoon'
        : 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 10,
      children: [
        Semantics(
          container: true,
          button: true,
          label: 'Profile',
          child: GestureDetector(
            onTap: onOpenProfile,
            child: Container(
              width: 44,
              height: 44,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: AppColors.purpleTint,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Image.asset('assets/mascot/cheer.png'),
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$_timeOfDay · ${app.rank.title}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: nunito(13, weight: FontWeight.w700, color: AppColors.textMuted),
              ),
              // Short, so it fits beside the streak and XP pills.
              Text(
                'Hey ${app.profile.name}!',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: baloo(20, height: 1.1),
              ),
            ],
          ),
        ),
        _CounterPill(
          semanticLabel: '${app.streak} day streak',
          value: '${app.streak}',
          background: const Color(0xFFFFE9D6),
          color: const Color(0xFFE26F0A),
          icon: const Teardrop(size: 13, color: AppColors.orange),
        ),
        _CounterPill(
          semanticLabel: '${app.xp} XP',
          value: '${app.xp}',
          background: AppColors.purpleTint,
          color: AppColors.purple,
          icon: Transform.rotate(
            angle: math.pi / 4,
            child: Container(
              width: 11,
              height: 11,
              decoration: BoxDecoration(
                color: AppColors.purple,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CounterPill extends StatelessWidget {
  const _CounterPill({
    required this.semanticLabel,
    required this.value,
    required this.background,
    required this.color,
    required this.icon,
  });

  final String semanticLabel;
  final String value;
  final Color background;
  final Color color;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 6, 12, 6),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(99)),
        child: Row(
          spacing: 7,
          children: [
            icon,
            Text(
              value,
              style: nunito(15, weight: FontWeight.w900, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ring showing minutes trained today against the daily goal.
class _DailyGoal extends StatelessWidget {
  const _DailyGoal({required this.app});

  final AppController app;

  @override
  Widget build(BuildContext context) {
    final done = app.goalMetToday;
    final mins = app.todaySeconds ~/ 60;
    final left = math.max(1, ((app.goalSeconds - app.todaySeconds) / 60).ceil());
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: done ? const Color(0xFFE3F7EE) : AppColors.pinkTint,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        spacing: 14,
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: app.goalProgress),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (_, v, _) => CustomPaint(
                painter: _RingPainter(v, done ? AppColors.green : AppColors.pink),
                child: Center(
                  child: done
                      ? const Icon(Icons.check_rounded, color: AppColors.green, size: 30)
                      : Text('$mins', style: baloo(22, height: 1)),
                ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Eyebrow(
                  'DAILY GOAL · ${app.profile.minutes} MIN',
                  color: done ? const Color(0xFF0F8A63) : AppColors.pinkDark,
                ),
                Text(
                  done
                      ? 'Goal hit! ${app.streak}-day streak'
                      : app.streak > 0
                      ? '$left min to keep your ${app.streak}-day streak'
                      : '$left min to start a streak',
                  style: baloo(19, height: 1.15),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.value, this.color);

  final double value;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(4);
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    canvas.drawArc(rect, 0, math.pi * 2, false, paint);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * value,
      false,
      paint
        ..color = color
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.value != value || old.color != color;
}

/// Row of 1–3 stars.
class StarRow extends StatelessWidget {
  const StarRow({super.key, required this.stars, this.size = 18, this.empty = AppColors.disabled});

  final int stars;
  final double size;
  final Color empty;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$stars of 3 stars',
    excludeSemantics: true,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++)
          Icon(Icons.star_rounded, size: size, color: i < stars ? AppColors.yellow : empty),
      ],
    ),
  );
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({
    required this.level,
    required this.blocks,
    required this.stars,
    required this.onPlay,
  });

  final GameLevel level;
  final List<Block> blocks;
  final int stars;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.passthrough,
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: level.boss ? AppColors.ink : AppColors.purple,
            borderRadius: BorderRadius.circular(28),
            boxShadow: hardShadow(level.boss ? Colors.black : AppColors.purpleDark, 6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Eyebrow(
                '${level.boss ? 'BOSS · ' : ''}LEVEL ${level.number} · '
                '${unitNames[level.unit - 1].toUpperCase()}',
                color: level.boss ? AppColors.yellow : AppColors.purpleMuted,
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(right: 110),
                child: Text(level.title, style: baloo(28, height: 1.05, color: Colors.white)),
              ),
              const SizedBox(height: 6),
              Text(
                blocks.map((b) => b.label).join(' · '),
                style: nunito(14, weight: FontWeight.w700, color: const Color(0xFFE6D6FF)),
              ),
              const SizedBox(height: 4),
              Row(
                spacing: 8,
                children: [
                  StarRow(stars: stars, empty: Colors.white.withValues(alpha: .25)),
                  Text(
                    'Pass with ${level.passForm}% form',
                    style: nunito(12, color: AppColors.purpleMuted),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ChunkyButton(
                label: stars > 0 ? 'Replay for more stars' : 'Play level ${level.number}',
                onPressed: onPlay,
                height: 56,
                color: AppColors.lime,
                shadowColor: AppColors.limeDark,
                textColor: AppColors.ink,
              ),
            ],
          ),
        ),
        Positioned(right: -6, top: -44, child: Image.asset('assets/mascot/lift.png', width: 140)),
      ],
    );
  }
}

class _DrillCard extends StatelessWidget {
  const _DrillCard({required this.drill, required this.onPlay});

  final Drill drill;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return OutlinedCard(
      child: Row(
        spacing: 12,
        children: [
          Image.asset('assets/mascot/zen.png', width: 64),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Eyebrow('RECOMMENDED DRILL', color: AppColors.pink),
                Text(drill.title, style: baloo(19, height: 1.1)),
                Text(
                  '${drill.block.label} · ${drill.reason}',
                  style: nunito(13, weight: FontWeight.w600, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: onPlay,
            style: FilledButton.styleFrom(backgroundColor: AppColors.pink),
            child: Text('Go', style: nunito(15, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _RankCard extends StatelessWidget {
  const _RankCard({required this.xp});

  final int xp;

  @override
  Widget build(BuildContext context) {
    final rank = rankFor(xp), next = nextRank(xp);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(22)),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Eyebrow('YOUR RANK', color: AppColors.pinkSoft),
                    Text(rank.title, style: baloo(20, color: Colors.white)),
                  ],
                ),
              ),
              Text(
                next == null ? 'Max rank' : '${next.minXp - xp} XP to ${next.title}',
                style: nunito(13, color: AppColors.lime),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: Container(
              height: 10,
              color: Colors.white.withValues(alpha: .12),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: rankProgress(xp),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.lime,
                    borderRadius: BorderRadius.circular(99),
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
