import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/decor.dart';
import '../app_controller.dart';

const _weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.app, required this.onStartLesson});

  final AppController app;
  final VoidCallback onStartLesson;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now().weekday - 1;
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 6, 22, 16),
      children: [
        _Header(app: app, weekday: _weekdays[today]),
        const SizedBox(height: 16),
        if (app.doneToday) ...[
          const _DoneCard(),
          const SizedBox(height: 16),
          ChunkyButton(
            label: 'Practice again for bonus XP',
            onPressed: onStartLesson,
            height: 48,
            fontSize: 15,
            color: Colors.white,
            textColor: AppColors.ink,
            borderColor: AppColors.line,
            shadowColor: AppColors.line,
            shadowDepth: 3,
          ),
        ] else ...[
          const SizedBox(height: 22),
          _LessonCard(lesson: app.todaysLesson, onStart: onStartLesson),
          const SizedBox(height: 16),
          const _StreakReminder(),
        ],
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
                  Text(
                    '${app.streak}-day streak',
                    style: nunito(13, color: const Color(0xFFE26F0A)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              WeekStrip(done: today + (app.doneToday ? 1 : 0), ringAt: today),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _ChallengeCard(progress: app.challenge),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.app, required this.weekday});

  final AppController app;
  final String weekday;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 10,
      children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.purple,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(app.name[0], style: baloo(20, color: Colors.white)),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                weekday,
                style: nunito(13, weight: FontWeight.w700, color: AppColors.textMuted),
              ),
              Text('Hey ${app.name}!', style: baloo(20, height: 1.1)),
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
            angle: 0.785398,
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

class _LessonCard extends StatelessWidget {
  const _LessonCard({required this.lesson, required this.onStart});

  final Lesson lesson;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.passthrough,
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.purple,
            borderRadius: BorderRadius.circular(28),
            boxShadow: hardShadow(AppColors.purpleDark, 6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Eyebrow('TODAY · LESSON ${lesson.number}', color: AppColors.purpleMuted),
              const SizedBox(height: 4),
              Text(lesson.name, style: baloo(30, height: 1.05, color: Colors.white)),
              const SizedBox(height: 6),
              Text(
                '5 min · camera · $repTarget reps',
                style: nunito(14, weight: FontWeight.w700, color: const Color(0xFFE6D6FF)),
              ),
              const SizedBox(height: 16),
              ChunkyButton(
                label: 'Start lesson',
                onPressed: onStart,
                height: 56,
                color: AppColors.lime,
                shadowColor: AppColors.limeDark,
                textColor: AppColors.ink,
              ),
            ],
          ),
        ),
        Positioned(right: -6, top: -44, child: Image.asset('assets/mascot/lift.png', width: 150)),
      ],
    );
  }
}

class _StreakReminder extends StatelessWidget {
  const _StreakReminder();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: AppColors.pinkTint, borderRadius: BorderRadius.circular(20)),
      child: Row(
        spacing: 10,
        children: [
          Expanded(
            child: Text(
              'Your streak ends at midnight. 5 minutes keeps it alive!',
              style: nunito(14, height: 1.35, color: const Color(0xFF8A1A52)),
            ),
          ),
          Image.asset('assets/mascot/laptop.png', width: 58),
        ],
      ),
    );
  }
}

class _DoneCard extends StatelessWidget {
  const _DoneCard();

  @override
  Widget build(BuildContext context) {
    return OutlinedCard(
      radius: 28,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        spacing: 10,
        children: [
          Image.asset('assets/mascot/sleep.png', width: 92),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Eyebrow('DONE FOR TODAY', color: Color(0xFF0F8A63)),
                Text('Streak safe. Rest up!', style: baloo(20, height: 1.1)),
                const SizedBox(height: 4),
                Text(
                  '${pathLessons[2].name} unlocks tomorrow',
                  style: nunito(13, weight: FontWeight.w700, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard({required this.progress});

  final int progress;

  @override
  Widget build(BuildContext context) {
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
                    const Eyebrow('WEEKLY CHALLENGE', color: AppColors.pinkSoft),
                    Text('100 clean squats', style: baloo(18, color: Colors.white)),
                  ],
                ),
              ),
              Text('$progress/100', style: nunito(15, color: AppColors.lime)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: Container(
              height: 10,
              color: Colors.white.withValues(alpha: .12),
              alignment: Alignment.centerLeft,
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: progress / 100),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                builder: (_, v, _) => FractionallySizedBox(
                  widthFactor: v,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.lime,
                      borderRadius: BorderRadius.circular(99),
                    ),
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
