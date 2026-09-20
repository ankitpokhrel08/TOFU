import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Solid fill with faint 135° stripes (10px on, 10px off) — the camera /
/// video placeholder texture.
class StripePainter extends CustomPainter {
  const StripePainter({required this.base, required this.stripe});

  final Color base;
  final Color stripe;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = base);
    final paint = Paint()
      ..color = stripe
      ..strokeWidth = 10 / math.sqrt2;
    const step = 20 * math.sqrt2;
    for (double x = -size.height; x < size.width + size.height; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(StripePainter old) => old.base != base || old.stripe != stripe;
}

/// Dashed outline around a rounded rect (or a circle when [circle] is set).
class DashedOutlinePainter extends CustomPainter {
  const DashedOutlinePainter({
    required this.color,
    this.strokeWidth = 2,
    this.radius = BorderRadius.zero,
    this.circle = false,
    this.dash = 6,
    this.gap = 5,
  });

  final Color color;
  final double strokeWidth;
  final BorderRadius radius;
  final bool circle;
  final double dash;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(strokeWidth / 2);
    final path = circle ? (Path()..addOval(rect)) : (Path()..addRRect(radius.toRRect(rect)));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    for (final metric in path.computeMetrics()) {
      for (double d = 0; d < metric.length; d += dash + gap) {
        canvas.drawPath(metric.extractPath(d, math.min(d + dash, metric.length)), paint);
      }
    }
  }

  @override
  bool shouldRepaint(DashedOutlinePainter old) =>
      old.color != color || old.radius != radius || old.circle != circle;
}

/// Upward-pointing teardrop (a square with three rounded corners, turned
/// 45°). [child] is kept upright.
class Teardrop extends StatelessWidget {
  const Teardrop({
    super.key,
    required this.size,
    required this.color,
    this.shadow,
    this.shadowOffset = const Offset(-6, 6),
    this.child,
  });

  final double size;
  final Color color;
  final Color? shadow;
  final Offset shadowOffset;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final r = Radius.circular(size / 2);
    return Transform.rotate(
      angle: -math.pi / 4,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.only(topLeft: r, bottomLeft: r, bottomRight: r),
          boxShadow: shadow == null ? null : [BoxShadow(color: shadow!, offset: shadowOffset)],
        ),
        child: child == null ? null : Transform.rotate(angle: math.pi / 4, child: child),
      ),
    );
  }
}

/// M–S week row: first [done] days filled, optional dashed ring on [ringAt].
class WeekStrip extends StatelessWidget {
  const WeekStrip({super.key, required this.done, this.ringAt});

  final int done;
  final int? ringAt;

  static const _labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var i = 0; i < 7; i++)
          Column(
            spacing: 6,
            children: [
              Text(_labels[i], style: nunito(12, color: AppColors.textFaint)),
              SizedBox(
                width: 36,
                height: 36,
                child: CustomPaint(
                  foregroundPainter: i == ringAt && i >= done
                      ? const DashedOutlinePainter(
                          color: AppColors.orange,
                          circle: true,
                          dash: 5,
                          gap: 4,
                        )
                      : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i < done ? AppColors.orange : const Color(0xFFF6EEF9),
                    ),
                    child: i < done
                        ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
                        : null,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
