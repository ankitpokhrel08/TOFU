import 'package:flutter/material.dart';

import '../../game/progression.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../app_controller.dart';

const _successFg = Color(0xFF0F8A63);

/// "Progress" tab: headline stats, recent form trend and achievements.
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key, required this.app});

  final AppController app;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 6, 22, 16),
      children: [
        Text('Your progress', style: baloo(28, height: 1.05)),
        const SizedBox(height: 14),
        _grid(
          [
            StatTile(
              value: '${app.streak}',
              label: 'day streak',
              background: const Color(0xFFFFE9D6),
              valueColor: const Color(0xFFE26F0A),
              labelColor: const Color(0xFF9A6A3D),
            ),
            StatTile(
              value: '${app.totalReps}',
              label: 'reps tracked',
              background: const Color(0xFFFFE0EF),
              valueColor: const Color(0xFFE0217F),
              labelColor: const Color(0xFFA0476F),
            ),
            StatTile(
              value: app.avgForm == null ? '–' : '${app.avgForm}',
              label: 'avg form score',
              background: AppColors.purpleTint,
              valueColor: AppColors.purple,
              labelColor: const Color(0xFF6A4D9C),
            ),
            StatTile(
              value: '${app.errorsCaught}',
              label: 'form errors caught',
              background: const Color(0xFFE3F7EE),
              valueColor: _successFg,
              labelColor: const Color(0xFF3F7A64),
            ),
          ],
          columns: 2,
          gap: 10,
        ),
        const SizedBox(height: 14),
        _FormChart(values: app.formHistory),
        const SizedBox(height: 14),
        Eyebrow('BADGES · ${app.badges.length}/${Achievement.values.length}'),
        const SizedBox(height: 14),
        _grid(
          [
            for (final (n, t, bg, fg, lf, earned) in _badges(app))
              Opacity(
                opacity: earned ? 1 : .45,
                child: StatTile(
                  value: n,
                  label: t,
                  background: bg,
                  valueColor: fg,
                  labelColor: lf,
                  valueSize: 22,
                  labelSize: 11,
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                  radius: 18,
                  centered: true,
                ),
              ),
          ],
          columns: 3,
          gap: 8,
        ),
      ],
    );
  }

  static const _tints = [
    (Color(0xFFFFE9D6), Color(0xFFE26F0A), Color(0xFF9A6A3D)),
    (Color(0xFFFFE0EF), Color(0xFFE0217F), Color(0xFFA0476F)),
    (AppColors.purpleTint, AppColors.purple, Color(0xFF6A4D9C)),
    (Color(0xFFE3F7EE), _successFg, Color(0xFF3F7A64)),
  ];

  static List<(String, String, Color, Color, Color, bool)> _badges(AppController app) {
    final earned = app.badges;
    return [
      for (final (i, b) in Achievement.values.indexed)
        (b.mark, b.label, _tints[i % 4].$1, _tints[i % 4].$2, _tints[i % 4].$3, earned.contains(b)),
    ];
  }

  /// Equal-width, equal-height grid rows.
  static Widget _grid(List<Widget> items, {required int columns, required double gap}) {
    return Column(
      spacing: gap,
      children: [
        for (var r = 0; r < items.length; r += columns)
          IntrinsicHeight(
            child: Row(
              spacing: gap,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [for (final w in items.sublist(r, r + columns)) Expanded(child: w)],
            ),
          ),
      ],
    );
  }
}

class _FormChart extends StatelessWidget {
  const _FormChart({required this.values});

  final List<int> values;

  static const _slots = 7;

  String? get _trend {
    if (values.length < 2) return null;
    final d = values.last - values.first;
    return d > 2
        ? 'trending up'
        : d < -2
        ? 'trending down'
        : 'holding steady';
  }

  @override
  Widget build(BuildContext context) {
    final trend = _trend;
    return OutlinedCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(child: Text('Form score · last 7 sessions', style: nunito(15))),
              if (trend != null)
                Text(
                  trend,
                  style: nunito(
                    12,
                    color: trend == 'trending down' ? AppColors.orangeDark : _successFg,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (values.isEmpty)
            SizedBox(
              height: 120,
              child: Center(
                child: Text(
                  'Finish your first lesson to start your trend.',
                  textAlign: TextAlign.center,
                  style: nunito(14, weight: FontWeight.w600, color: AppColors.textMuted),
                ),
              ),
            )
          else
            SizedBox(
              height: 120,
              child: LayoutBuilder(
                builder: (context, box) {
                  // Bars show the 50–100 range; leave room for the value label.
                  final barSpace = box.maxHeight - 20;
                  return Row(
                    spacing: 8,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Empty slots keep bar widths stable with fewer sessions.
                      for (var i = values.length; i < _slots; i++)
                        const Expanded(child: SizedBox()),
                      for (final (i, v) in values.indexed)
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            spacing: 4,
                            children: [
                              Text(
                                '$v',
                                style: nunito(
                                  11,
                                  color: i == values.length - 1
                                      ? AppColors.pinkDark
                                      : AppColors.textFaint,
                                ),
                              ),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 400),
                                height: barSpace * ((v - 50) / 50).clamp(0.0, 1.0),
                                decoration: BoxDecoration(
                                  color: i == values.length - 1
                                      ? AppColors.pink
                                      : const Color(0xFFFFC2DF),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
