import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// One segment per graded unit: lime = clean, red = form error.
class RepDots extends StatelessWidget {
  const RepDots({
    super.key,
    required this.repLog,
    required this.total,
    required this.height,
    required this.empty,
  });

  final List<bool> repLog;

  /// Segments to draw (reps, or hold segments).
  final int total;
  final double height;
  final Color empty;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 4,
      children: [
        for (var i = 0; i < total; i++)
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: height,
              decoration: BoxDecoration(
                color: i >= repLog.length
                    ? empty
                    : repLog[i]
                    ? AppColors.lime
                    : AppColors.red,
                borderRadius: BorderRadius.circular(math.min(height, 8)),
              ),
            ),
          ),
      ],
    );
  }
}
