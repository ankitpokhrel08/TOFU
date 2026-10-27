import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/decor.dart';
import '../app_controller.dart';
import 'camera_screen.dart';

const _cues = [
  ('Hips to knee height', 'Thighs parallel to the floor', Color(0xFFFFE0EF), Color(0xFFE0217F)),
  ('Knees track over toes', 'No caving inward', AppColors.purpleTint, AppColors.purple),
  ('Chest proud', 'Keep your torso tall', Color(0xFFE3F7EE), Color(0xFF0F8A63)),
];

/// Lesson step 1: watch the move and learn the cues.
class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key, required this.app});

  final AppController app;

  @override
  Widget build(BuildContext context) {
    final lesson = app.todaysLesson;
    return Scaffold(
      body: FlowPage(
        header: Padding(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 0),
          child: Row(
            spacing: 12,
            children: [
              SquareIconButton(
                icon: Icons.close_rounded,
                label: 'Close lesson',
                onTap: () => Navigator.of(context).pop(),
              ),
              const Expanded(child: LessonSteps(current: 0)),
              Text('1 · Learn', style: nunito(13, color: AppColors.textFaint)),
            ],
          ),
        ),
        bodyPadding: const EdgeInsets.fromLTRB(22, 16, 22, 8),
        footer: ChunkyButton(
          label: 'Got it, open camera',
          onPressed: () =>
              Navigator.of(context)
                  .push(MaterialPageRoute<void>(builder: (_) => CameraScreen(app: app))),
        ),
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Eyebrow('LESSON ${lesson.number} · 1 MIN', color: AppColors.pink),
              const SizedBox(height: 2),
              Text(lesson.name, style: baloo(30, height: 1.05)),
            ],
          ),
          const _VideoPlaceholder(),
          Text('3 cues Guru will check live', style: nunito(17)),
          for (final (i, (title, detail, bg, fg)) in _cues.indexed)
            OutlinedCard(
              radius: 18,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                spacing: 12,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
                    child: Text(
                      '${i + 1}',
                      style: nunito(15, weight: FontWeight.w900, color: fg),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: nunito(15)),
                        Text(
                          detail,
                          style: nunito(13, weight: FontWeight.w600, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Three-segment lesson progress (learn → practice → check).
class LessonSteps extends StatelessWidget {
  const LessonSteps({super.key, required this.current});

  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 6,
      children: [
        for (var i = 0; i < 3; i++)
          Expanded(
            child: Container(
              height: 10,
              decoration: BoxDecoration(
                color: i <= current ? AppColors.pink : AppColors.track,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
      ],
    );
  }
}

/// Demo-video stand-in until real lesson media exists.
class _VideoPlaceholder extends StatelessWidget {
  const _VideoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: 200,
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Positioned.fill(
              child: CustomPaint(
                painter: StripePainter(base: Color(0xFFEADCF2), stripe: Color(0x0D2B0F3F)),
              ),
            ),
            Semantics(
              button: true,
              label: 'Play demo video',
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: hardShadow(const Color(0xFFD2BEDD), 4),
                ),
                child: const Icon(Icons.play_arrow_rounded, color: AppColors.pink, size: 40),
              ),
            ),
            Positioned(
              right: 12,
              top: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text('0:42', style: nunito(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
