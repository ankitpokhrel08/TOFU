import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/decor.dart';
import '../app_controller.dart';
import '../widgets/rep_dots.dart';
import 'share_screen.dart';

const _successFg = Color(0xFF0F8A63);

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key, required this.app, required this.result});

  final AppController app;
  final SessionResult result;

  @override
  Widget build(BuildContext context) {
    final streak = app.streak;
    return Scaffold(
      body: FlowPage(
        bodyPadding: const EdgeInsets.fromLTRB(22, 4, 22, 8),
        footer: Row(
          spacing: 10,
          children: [
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
                    builder: (_) => ShareScreen(result: result, streak: streak),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: ChunkyButton(
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
              Image.asset('assets/mascot/cheer.png', width: 112),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Eyebrow('LESSON COMPLETE', color: AppColors.pink),
                    const SizedBox(height: 2),
                    Text(result.title, style: baloo(30, height: 1.02)),
                  ],
                ),
              ),
            ],
          ),
          IntrinsicHeight(
            child: Row(
              spacing: 8,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (value, label, bg, fg, lf) in [
                  (
                    '${result.reps}',
                    'reps',
                    const Color(0xFFFFE0EF),
                    const Color(0xFFE0217F),
                    const Color(0xFFA0476F),
                  ),
                  (
                    '${result.form}',
                    'form score',
                    AppColors.purpleTint,
                    AppColors.purple,
                    const Color(0xFF6A4D9C),
                  ),
                  (
                    '+${result.xpGain}',
                    'XP',
                    const Color(0xFFE3F7EE),
                    _successFg,
                    const Color(0xFF3F7A64),
                  ),
                ])
                  Expanded(
                    child: StatTile(
                      value: value,
                      label: label,
                      background: bg,
                      valueColor: fg,
                      labelColor: lf,
                      valueSize: 26,
                      labelSize: 12,
                      padding: const EdgeInsets.all(12),
                      radius: 18,
                    ),
                  ),
              ],
            ),
          ),
          _StreakBanner(streak: streak),
          _Breakdown(result: result),
        ],
      ),
    );
  }
}

class _StreakBanner extends StatelessWidget {
  const _StreakBanner({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.orange,
        borderRadius: BorderRadius.circular(22),
        boxShadow: hardShadow(AppColors.orangeDark, 5),
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
                Text('$streak-day streak!', style: baloo(19, height: 1.1, color: Colors.white)),
                Text(
                  // Badges land on every 7th day.
                  streak % 7 == 6
                      ? '1 more day to your next badge'
                      : 'Come back tomorrow to keep it',
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
  const _Breakdown({required this.result});

  final SessionResult result;

  @override
  Widget build(BuildContext context) {
    return OutlinedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Rep-by-rep breakdown', style: nunito(15)),
          const SizedBox(height: 10),
          RepDots(repLog: result.repLog, height: 30, empty: AppColors.track),
          const SizedBox(height: 12),
          if (result.errors.isEmpty)
            Text('No form errors. Clean set!', style: nunito(14, color: _successFg))
          else
            Column(
              spacing: 8,
              children: [
                for (final e in result.errors)
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
                          'REP ${e.rep}',
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
