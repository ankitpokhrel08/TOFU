import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../app_controller.dart';

/// One segment per target rep: lime = clean, red = form error.
class RepDots extends StatelessWidget {
  const RepDots({super.key, required this.repLog, required this.height, required this.empty});

  final List<bool> repLog;
  final double height;
  final Color empty;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 4,
      children: [
        for (var i = 0; i < repTarget; i++)
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
