import 'package:flutter/material.dart';

import '../../game/levels.dart';
import '../../theme/app_theme.dart';
import '../../tracking/tracker.dart';
import '../../widgets/common.dart';
import '../../widgets/decor.dart';
import '../app_controller.dart';
import '../widgets/rep_dots.dart';
import 'camera_screen.dart';
import 'home_screen.dart' show StarRow;
import 'learn_screen.dart';
import 'share_screen.dart';

const _successFg = Color(0xFF0F8A63);

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({
    super.key,
    required this.app,
    required this.outcome,
    required this.trackerFactory,
    this.level,
  });

  final AppController app;
  final WorkoutOutcome outcome;
  final TrackerFactory trackerFactory;
  final GameLevel? level;

  SessionResult get _s => outcome.session;

  void _retry(BuildContext context) => Navigator.of(context).pushReplacement(
    MaterialPageRoute<void>(
      builder: (_) => CameraScreen(
        app: app,
        trackerFactory: trackerFactory,
        kind: _s.kind,
        level: level,
        blocks: [for (final b in _s.blocks) Block(b.exercise, b.target)],
      ),
    ),
  );

  void _next(BuildContext context, GameLevel next) => Navigator.of(context).pushReplacement(
    MaterialPageRoute<void>(
      builder: (_) => LearnScreen(
        app: app,
        trackerFactory: trackerFactory,
        kind: SessionKind.level,
        level: next,
        title: next.title,
        blocks: app.blocksFor(next),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l = level;
    final demo = outcome.demo;
    final passed = _s.stars > 0;
    final failed = l != null && !passed && !demo;
    final next = outcome.unlocked;
    return Scaffold(
      body: FlowPage(
        bodyPadding: const EdgeInsets.fromLTRB(22, 4, 22, 8),
        footer: Row(
          spacing: 10,
          children: [
            if (!demo)
              Expanded(
                child: ChunkyButton(
                  label: 'Share',
                  fontSize: 17,
                  color: Colors.white,
                  textColor: AppColors.ink,
                  borderColor: AppColors.line,
                  shadowColor: AppColors.line,
                  shadowDepth: 4,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ShareScreen(app: app, result: _s, level: l),
                    ),
                  ),
                ),
              ),
            Expanded(
              flex: 2,
              child: failed
                  ? ChunkyButton(label: 'Try again', onPressed: () => _retry(context))
                  : next != null
                  ? ChunkyButton(
                      label: 'Next: level ${next.number}',
                      onPressed: () => _next(context, next),
                    )
                  : ChunkyButton(
                      label: 'Continue',
                      onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                    ),
            ),
          ],
        ),
        children: [
          Row(
            spacing: 6,
            children: [
              Image.asset(
                failed ? 'assets/mascot/laptop.png' : 'assets/mascot/cheer.png',
                width: 108,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Eyebrow(
                      demo
                          ? 'DEMO SET · NOT SAVED'
                          : l == null
                          ? 'DRILL COMPLETE'
                          : passed
                          ? 'LEVEL ${l.number} CLEARED'
                          : 'LEVEL ${l.number}',
                      color: AppColors.pink,
                    ),
                    const SizedBox(height: 2),
                    Text(demo ? 'Demo complete' : _s.title, style: baloo(30, height: 1.02)),
                    if (l != null && !demo) ...[
                      const SizedBox(height: 4),
                      StarRow(stars: _s.stars, size: 30),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (demo)
            Text(
              'This was a scripted demo of how tracking works, so it earns no XP, stars or '
              'streak time. Train in front of the camera to make progress.',
              style: nunito(14, weight: FontWeight.w600, color: AppColors.textMuted),
            ),
          if (failed)
            Text(
              _s.complete
                  ? 'You need ${l.passForm}% form to pass. You got ${_s.form}%. Check the tips below and go again.'
                  : 'Finish every exercise to pass the level.',
              style: nunito(14, weight: FontWeight.w600, color: AppColors.textMuted),
            ),
          IntrinsicHeight(
            child: Row(
              spacing: 8,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: StatTile(
                    value: '${_s.form}%',
                    label: 'form',
                    background: AppColors.purpleTint,
                    valueColor: AppColors.purple,
                    labelColor: const Color(0xFF6A4D9C),
                    valueSize: 26,
                    labelSize: 12,
                    padding: const EdgeInsets.all(12),
                    radius: 18,
                  ),
                ),
                Expanded(
                  child: StatTile(
                    value: '${_s.reps}',
                    label: 'reps tracked',
                    background: const Color(0xFFFFE0EF),
                    valueColor: const Color(0xFFE0217F),
                    labelColor: const Color(0xFFA0476F),
                    valueSize: 26,
                    labelSize: 12,
                    padding: const EdgeInsets.all(12),
                    radius: 18,
                  ),
                ),
                Expanded(
                  child: StatTile(
                    value: '+${_s.xp}',
                    label: 'XP',
                    background: const Color(0xFFE3F7EE),
                    valueColor: _successFg,
                    labelColor: const Color(0xFF3F7A64),
                    valueSize: 26,
                    labelSize: 12,
                    padding: const EdgeInsets.all(12),
                    radius: 18,
                  ),
                ),
              ],
            ),
          ),
          if (!demo) ...[..._rewards(), _StreakBanner(app: app, justMet: outcome.goalJustMet)],
          for (final b in _s.blocks) _Breakdown(block: b),
        ],
      ),
    );
  }

  List<Widget> _rewards() => [
    if (outcome.firstClear && level!.boss)
      _Reward(
        Icons.emoji_events_rounded,
        'Boss beaten! ${unitNames[level!.unit - 1]} cleared',
        AppColors.orange,
      ),
    if (outcome.unlocked case final u?)
      _Reward(Icons.lock_open_rounded, 'Level ${u.number} unlocked: ${u.title}', AppColors.purple),
    if (outcome.rankUp case final r?)
      _Reward(Icons.military_tech_rounded, 'Rank up! You\'re now ${r.title}', AppColors.pink),
    for (final b in outcome.newBadges)
      _Reward(Icons.workspace_premium_rounded, 'Achievement earned: ${b.label}', AppColors.green),
  ];
}

class _Reward extends StatelessWidget {
  const _Reward(this.icon, this.text, this.color);

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: .85, end: 1),
    duration: const Duration(milliseconds: 450),
    curve: Curves.elasticOut,
    builder: (_, s, child) => Transform.scale(scale: s, child: child),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        spacing: 10,
        children: [
          Icon(icon, color: color),
          Expanded(child: Text(text, style: nunito(15))),
        ],
      ),
    ),
  );
}

class _StreakBanner extends StatelessWidget {
  const _StreakBanner({required this.app, required this.justMet});

  final AppController app;
  final bool justMet;

  @override
  Widget build(BuildContext context) {
    final streak = app.streak;
    final left = ((app.goalSeconds - app.todaySeconds) / 60).ceil();
    final met = app.goalMetToday;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: met ? AppColors.orange : AppColors.ink,
        borderRadius: BorderRadius.circular(22),
        boxShadow: hardShadow(met ? AppColors.orangeDark : Colors.black, 5),
      ),
      child: Row(
        spacing: 14,
        children: [
          Teardrop(
            size: 46,
            color: AppColors.yellow,
            child: Text('$streak', style: baloo(20, color: AppColors.orangeDark)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  met
                      ? (justMet ? 'Daily goal hit! $streak-day streak' : '$streak-day streak!')
                      : '$left min left on today\'s goal',
                  style: baloo(19, height: 1.1, color: Colors.white),
                ),
                Text(
                  met
                      ? 'Come back tomorrow to keep it going'
                      : 'Do a drill or replay a level to finish your ${app.profile.minutes} minutes',
                  style: nunito(13, weight: FontWeight.w700, color: const Color(0xFFFFE9D6)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Breakdown extends StatelessWidget {
  const _Breakdown({required this.block});

  final BlockResult block;

  @override
  Widget build(BuildContext context) {
    final timed = block.exercise.timed;
    return OutlinedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  timed
                      ? '${block.exercise.label} · ${block.target}s'
                      : '${block.done}/${block.target} ${block.exercise.plural}',
                  style: nunito(15),
                ),
              ),
              Text('${block.form}%', style: nunito(15, color: AppColors.purple)),
            ],
          ),
          const SizedBox(height: 10),
          RepDots(repLog: block.repLog, total: block.units, height: 26, empty: AppColors.track),
          const SizedBox(height: 10),
          if (block.errors.isEmpty)
            Text(
              block.done == 0 ? 'Not started' : 'No form errors. Clean set!',
              style: nunito(14, color: block.done == 0 ? AppColors.textFaint : _successFg),
            )
          else
            Column(
              spacing: 8,
              children: [
                for (final e in block.errors)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 10,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 1),
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          timed ? '${(e.rep - 1) * 5}–${e.rep * 5}s' : 'REP ${e.rep}',
                          style: nunito(11, weight: FontWeight.w900, color: Colors.white),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e.title, style: nunito(14)),
                            Text(
                              e.tip,
                              style: nunito(
                                13,
                                weight: FontWeight.w600,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
