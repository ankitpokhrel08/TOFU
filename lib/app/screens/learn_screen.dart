import 'package:flutter/material.dart';

import '../../game/exercises.dart';
import '../../game/levels.dart';
import '../../theme/app_theme.dart';
import '../../tracking/tracker.dart';
import '../../widgets/common.dart';
import '../../widgets/exercise_demo.dart';
import '../app_controller.dart';
import 'camera_screen.dart';

const _tints = [
  (Color(0xFFFFE0EF), Color(0xFFE0217F)),
  (AppColors.purpleTint, AppColors.purple),
  (Color(0xFFE3F7EE), Color(0xFF0F8A63)),
  (Color(0xFFFFE9D6), Color(0xFFE26F0A)),
  (Color(0xFFEEF4FF), Color(0xFF3B7BD8)),
];

/// Workout intro: the exercises, how to stand, and what Guru checks.
class LearnScreen extends StatelessWidget {
  const LearnScreen({
    super.key,
    required this.app,
    required this.trackerFactory,
    required this.kind,
    required this.title,
    required this.blocks,
    this.level,
  });

  final AppController app;
  final TrackerFactory trackerFactory;
  final SessionKind kind;
  final String title;
  final List<Block> blocks;
  final GameLevel? level;

  @override
  Widget build(BuildContext context) {
    final l = level;
    final stars = l == null ? 0 : app.levelStars[l.number] ?? 0;
    return Scaffold(
      body: FlowPage(
        header: Padding(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 0),
          child: Row(
            children: [
              SquareIconButton(
                icon: Icons.close_rounded,
                label: 'Close',
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
        bodyPadding: const EdgeInsets.fromLTRB(22, 12, 22, 8),
        footer: ChunkyButton(
          label: 'Start workout',
          onPressed: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) => CameraScreen(
                app: app,
                trackerFactory: trackerFactory,
                kind: kind,
                level: level,
                blocks: blocks,
              ),
            ),
          ),
        ),
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Eyebrow(
                l == null
                    ? 'DRILL'
                    : '${l.boss ? 'BOSS · ' : ''}LEVEL ${l.number} · ${unitNames[l.unit - 1].toUpperCase()}',
                color: AppColors.pink,
              ),
              const SizedBox(height: 2),
              Text(title, style: baloo(30, height: 1.05)),
              const SizedBox(height: 4),
              Text(
                l == null
                    ? 'A quick set to sharpen your form. Earns XP and daily goal minutes.'
                    : stars == 0
                    ? 'Finish every exercise with ${l.passForm}% form to pass and unlock the next level.'
                    : 'Best so far: $stars★. 92% form earns three stars.',
                style: nunito(14, weight: FontWeight.w600, color: AppColors.textMuted),
              ),
            ],
          ),
          for (final (i, b) in blocks.indexed) _BlockCard(index: i, block: b),
          Text(
            'Prop your phone about 2–3 m away at hip height.'
            '${blocks.length > 1 ? ' Guru switches exercises for you and gives you time to turn.' : ''}',
            style: nunito(13, weight: FontWeight.w600, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _BlockCard extends StatelessWidget {
  const _BlockCard({required this.index, required this.block});

  final int index;
  final Block block;

  @override
  Widget build(BuildContext context) {
    final e = block.exercise;
    final (bg, fg) = _tints[index % _tints.length];
    return OutlinedCard(
      radius: 18,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.lavender,
              borderRadius: BorderRadius.circular(14),
            ),
            child: ExerciseDemo(exercise: e, height: 170),
          ),
          Row(
            spacing: 12,
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
                child: Text(
                  '${index + 1}',
                  style: nunito(15, weight: FontWeight.w900, color: fg),
                ),
              ),
              Expanded(child: Text(block.label, style: nunito(16))),
              Icon(
                e.view == CameraView.front
                    ? Icons.accessibility_new_rounded
                    : Icons.switch_left_rounded,
                size: 18,
                color: AppColors.textFaint,
              ),
              Text(
                e.view == CameraView.front ? 'Face camera' : 'Side-on',
                style: nunito(12, color: AppColors.textFaint),
              ),
            ],
          ),
          for (final (cue, detail) in e.cues)
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: '$cue  ', style: nunito(13)),
                  TextSpan(
                    text: detail,
                    style: nunito(13, weight: FontWeight.w600, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
