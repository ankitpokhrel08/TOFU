import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../game/levels.dart';
import '../app_controller.dart';

enum _CardKind { streak, form, skill }

class _CardStyle {
  const _CardStyle(this.big, this.unit, this.sub, this.bg, this.fg, this.mascot);
  final String big;
  final String unit;
  final String sub;
  final Color bg;
  final Color fg;
  final String mascot;
}

/// Pick a stat card and share it.
class ShareScreen extends StatefulWidget {
  const ShareScreen({super.key, required this.app, required this.result, this.level});

  final AppController app;
  final SessionResult result;
  final GameLevel? level;

  @override
  State<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends State<ShareScreen> {
  _CardKind _kind = _CardKind.streak;

  _CardStyle get _style => switch (_kind) {
    _CardKind.streak => _CardStyle(
      '${widget.app.streak}',
      'day streak',
      widget.app.streak <= 1
          ? 'Day one, done'
          : '${widget.app.rank.title} rank · ${widget.app.xp} XP',
      AppColors.orange,
      Colors.white,
      'summit',
    ),
    _CardKind.form => _CardStyle(
      '${widget.result.form}%',
      'form score',
      '${widget.result.reps} reps, AI-checked',
      AppColors.purple,
      Colors.white,
      'lift',
    ),
    _CardKind.skill => _CardStyle(
      widget.level == null ? '+${widget.result.xp}' : 'Lvl ${widget.level!.number}',
      widget.level == null ? 'XP earned' : widget.level!.title,
      widget.level == null
          ? 'Drill done'
          : '${'★' * widget.result.stars}${'☆' * (3 - widget.result.stars)}',
      AppColors.lime,
      AppColors.ink,
      'cheer',
    ),
  };

  @override
  Widget build(BuildContext context) {
    final c = _style;
    final translucent = Colors.white.withValues(alpha: .12);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.inkDeep,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 4, 22, 0),
                child: Row(
                  children: [
                    SquareIconButton(
                      icon: Icons.close_rounded,
                      label: 'Close',
                      onTap: () => Navigator.of(context).pop(),
                      background: translucent,
                      foreground: Colors.white,
                    ),
                    Expanded(
                      child: Text(
                        'Share your win',
                        textAlign: TextAlign.center,
                        style: nunito(15, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                    child: Column(
                      spacing: 16,
                      children: [
                        _KindPicker(value: _kind, onChanged: (k) => setState(() => _kind = k)),
                        _Card(style: c),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 16),
                child: Row(
                  spacing: 8,
                  children: [
                    for (final (label, primary) in [
                      ('Story', true),
                      ('Message', false),
                      ('Save', false),
                    ])
                      Expanded(
                        child: Material(
                          color: primary ? AppColors.pink : translucent,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {},
                            child: SizedBox(
                              height: 52,
                              child: Center(
                                child: Text(label, style: nunito(14, color: Colors.white)),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KindPicker extends StatelessWidget {
  const _KindPicker({required this.value, required this.onChanged});

  final _CardKind value;
  final ValueChanged<_CardKind> onChanged;

  static const _labels = {
    _CardKind.streak: 'Streak',
    _CardKind.form: 'Form score',
    _CardKind.skill: 'Level',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 6,
        children: [
          for (final k in _CardKind.values)
            Semantics(
              container: true,
              button: true,
              selected: k == value,
              child: GestureDetector(
                onTap: () => onChanged(k),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: k == value ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _labels[k]!,
                    style: nunito(13, color: k == value ? AppColors.ink : AppColors.textOnDark),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.style});

  final _CardStyle style;

  @override
  Widget build(BuildContext context) {
    final fg = style.fg;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 270,
      height: 420,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Color(0x80000000),
            offset: Offset(0, 20),
            blurRadius: 40,
            spreadRadius: -12,
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GYM GURU',
                  style: baloo(13, color: fg.withValues(alpha: .8), letterSpacing: 2.3),
                ),
                const SizedBox(height: 18),
                Text(style.big, style: baloo(64, height: .9, color: fg)),
                const SizedBox(height: 4),
                Text(style.unit, style: baloo(26, height: 1, color: fg)),
                const SizedBox(height: 12),
                Text(style.sub, style: nunito(15, color: fg.withValues(alpha: .9))),
              ],
            ),
          ),
          Positioned(
            right: -10,
            bottom: -6,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Image.asset(
                'assets/mascot/${style.mascot}.png',
                key: ValueKey(style.mascot),
                width: 180,
              ),
            ),
          ),
          Positioned(
            left: 24,
            bottom: 22,
            child: Text(
              'Train with Guru\ngymguru.app',
              style: nunito(12, color: fg.withValues(alpha: .8)),
            ),
          ),
        ],
      ),
    );
  }
}
