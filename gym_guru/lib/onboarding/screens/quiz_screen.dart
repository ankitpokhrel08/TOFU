import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../onboarding_controller.dart';

const _options = [
  ('A', 'Squat deeper'),
  ('B', 'Brace your core, chest proud'),
  ('C', 'Add more weight'),
];

const _successFg = Color(0xFF0F8A63);
const _successBg = Color(0xFFDFF8EC);
const _missBg = Color(0xFFFFF0E0);

/// "Aha #3": a 30-second sample lesson.
class QuizScreen extends StatelessWidget {
  const QuizScreen({super.key, required this.nav, required this.c});

  final FlowNav nav;
  final OnboardingController c;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        final answered = c.quizAnswered;
        final correct = c.quizCorrectAnswer;
        final (image, bubble) = !answered
            ? ('assets/mascot/zen.png', 'Take a guess — no pressure.')
            : correct
            ? ('assets/mascot/cheer.png', "Yes! You're a natural.")
            : ('assets/mascot/laptop.png', "Ooh, so close. Here's the trick:");

        return FlowPage(
          header: OnboardingHeader(step: 7, onBack: nav.back),
          footer: ChunkyButton(
            label: answered ? 'Continue' : 'Pick an answer',
            onPressed: answered ? nav.next : null,
          ),
          spacing: 12,
          children: [
            if (c.showAhaTags) const AhaTag('AHA #3 · TRY A 30-SECOND LESSON'),
            SpeechBubble(image: image, text: bubble),
            Text(
              "Your squats make your lower back ache. What's the fix?",
              style: baloo(25, height: 1.12),
            ),
            Column(
              spacing: 10,
              children: [
                for (final (key, label) in _options)
                  _Option(
                    letter: key,
                    label: label,
                    answer: c.quizAnswer,
                    onTap: () => c.answerQuiz(key),
                  ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: answered
                  ? _Feedback(correct: correct)
                  : const SizedBox(width: double.infinity),
            ),
          ],
        );
      },
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.letter,
    required this.label,
    required this.answer,
    required this.onTap,
  });

  final String letter;
  final String label;
  final String? answer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    var bd = AppColors.line;
    var bg = Colors.white;
    var kb = AppColors.lavender;
    var kf = AppColors.ink;
    var opacity = 1.0;

    if (answer != null) {
      if (letter == quizCorrect) {
        bd = AppColors.green;
        bg = _successBg;
        kb = AppColors.green;
        kf = Colors.white;
      } else if (letter == answer) {
        bd = AppColors.orange;
        bg = _missBg;
        kb = AppColors.orange;
        kf = Colors.white;
      } else {
        opacity = .5;
      }
    }

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: opacity,
      child: Semantics(
        container: true,
        button: true,
        enabled: answer == null,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: answer == null ? onTap : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: bg,
              border: Border.all(color: bd, width: 2),
              borderRadius: BorderRadius.circular(18),
              boxShadow: hardShadow(bd),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: kb, borderRadius: BorderRadius.circular(10)),
                  child: Text(
                    letter,
                    style: nunito(15, weight: FontWeight.w900, color: kf),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(label, style: nunito(16))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Feedback extends StatelessWidget {
  const _Feedback({required this.correct});

  final bool correct;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: correct ? _successBg : _missBg,
        border: Border.all(color: correct ? AppColors.green : AppColors.orange, width: 2),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            correct ? 'Nailed it!' : "It's B — brace first.",
            style: baloo(19, color: correct ? _successFg : AppColors.orangeDark),
          ),
          Text(
            correct
                ? "That's lesson 3 on your path. Guru checks your brace live, on every rep."
                : "Back strain usually means a lost brace. You'll master it in lesson 3 "
                      '— with live camera feedback.',
            style: nunito(14, weight: FontWeight.w600, height: 1.4, color: const Color(0xFF4A3559)),
          ),
        ],
      ),
    );
  }
}
