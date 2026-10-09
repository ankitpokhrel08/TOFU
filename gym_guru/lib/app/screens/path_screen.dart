import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../app_controller.dart';

enum _Status { mastered, current, unlocked, locked }

class PathScreen extends StatelessWidget {
  const PathScreen({super.key, required this.app, required this.onStartLesson});

  final AppController app;
  final VoidCallback onStartLesson;

  // Left insets that zig-zag the path.
  static const _insets = [12.0, 90.0, 150.0, 90.0, 12.0, 90.0, 150.0, 90.0];

  @override
  Widget build(BuildContext context) {
    final mastered = app.masteredCount;
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 6, 22, 16),
      children: [
        Row(
          spacing: 8,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Eyebrow('UNIT 1 · FOUNDATIONS', color: AppColors.pink),
                  const SizedBox(height: 2),
                  Text('Your path', style: baloo(28, height: 1.05)),
                  const SizedBox(height: 4),
                  Text(
                    '$mastered of ${pathLessons.length} skills mastered',
                    style: nunito(13, weight: FontWeight.w700, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            Image.asset('assets/mascot/summit.png', width: 96),
          ],
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, box) {
            // Keep the zig-zag inside narrow screens (node + label ≈ 200px).
            final scale = ((box.maxWidth - 200) / 150).clamp(0.0, 1.0);
            return Column(
              spacing: 14,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (i, lesson) in pathLessons.indexed)
                  Padding(
                    padding: EdgeInsets.only(left: _insets[i] * scale),
                    child: _Node(
                      lesson: lesson,
                      status: _statusFor(i, mastered),
                      doneToday: app.doneToday,
                      onTap: onStartLesson,
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  static _Status _statusFor(int i, int mastered) {
    if (i < mastered) return _Status.mastered;
    if (i == mastered) return _Status.current;
    return i < unlockedLessons ? _Status.unlocked : _Status.locked;
  }
}

class _Node extends StatelessWidget {
  const _Node({
    required this.lesson,
    required this.status,
    required this.doneToday,
    required this.onTap,
  });

  final Lesson lesson;
  final _Status status;
  final bool doneToday;
  final VoidCallback onTap;

  static const _lockedFg = Color(0xFFA893B5);

  @override
  Widget build(BuildContext context) {
    final (bg, shadow) = switch (status) {
      _Status.mastered => (AppColors.yellow, const Color(0xFFD99A0B)),
      _Status.current => (AppColors.pink, AppColors.pinkDark),
      _Status.unlocked => (AppColors.purple, AppColors.purpleDark),
      _Status.locked => (const Color(0xFFE8DAF0), const Color(0xFFD2BEDD)),
    };
    final locked = status == _Status.locked;
    final current = status == _Status.current;
    // Only one lesson a day: the next one waits until tomorrow.
    final (tag, tagColor) = switch (status) {
      _Status.mastered => ('MASTERED', const Color(0xFFC08A00)),
      _Status.current => (doneToday ? 'TOMORROW' : 'TAP TO START', AppColors.pink),
      _ => ('', AppColors.pink),
    };
    final canStart = current && !doneToday;

    return Semantics(
      container: true,
      button: canStart,
      label: [lesson.name, if (tag.isNotEmpty) tag.toLowerCase()].join(', '),
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: canStart ? onTap : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 14,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                if (current)
                  Positioned(
                    left: -7,
                    top: -7,
                    right: -7,
                    bottom: -7,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFFFD3E8), width: 4),
                      ),
                    ),
                  ),
                Container(
                  width: 58,
                  height: 58,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: bg,
                    shape: BoxShape.circle,
                    boxShadow: hardShadow(shadow, 6),
                  ),
                  child: status == _Status.mastered
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 28)
                      : Text(
                          '${lesson.number}',
                          style: baloo(22, color: locked ? _lockedFg : Colors.white),
                        ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (tag.isNotEmpty)
                  Text(
                    tag,
                    style: nunito(10, weight: FontWeight.w900, letterSpacing: 1.2, color: tagColor),
                  ),
                Text(lesson.name, style: nunito(16, color: locked ? _lockedFg : AppColors.ink)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
