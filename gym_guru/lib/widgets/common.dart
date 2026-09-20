import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Primary CTA with a solid offset shadow that "presses down" on tap.
class ChunkyButton extends StatefulWidget {
  const ChunkyButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = AppColors.pink,
    this.shadowColor = AppColors.pinkDark,
    this.textColor = Colors.white,
    this.borderColor,
    this.height = 58,
    this.fontSize = 19,
    this.shadowDepth = 5,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final Color shadowColor;
  final Color textColor;
  final Color? borderColor;
  final double height;
  final double fontSize;
  final double shadowDepth;

  @override
  State<ChunkyButton> createState() => _ChunkyButtonState();
}

class _ChunkyButtonState extends State<ChunkyButton> {
  bool _down = false;

  void _set(bool v) {
    if (widget.onPressed != null && _down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final bg = enabled ? widget.color : AppColors.disabled;
    final sh = enabled ? widget.shadowColor : AppColors.disabledShadow;
    return Semantics(
      container: true,
      button: true,
      enabled: enabled,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        onTap: widget.onPressed,
        child: Padding(
          // Reserve room for the shadow so layout doesn't jump on press.
          padding: EdgeInsets.only(bottom: widget.shadowDepth),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 90),
            height: widget.height,
            transform: Matrix4.translationValues(0, _down ? widget.shadowDepth - 1 : 0, 0),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(18),
              border: widget.borderColor == null
                  ? null
                  : Border.all(color: widget.borderColor!, width: 2),
              boxShadow: hardShadow(sh, _down ? 1 : widget.shadowDepth),
            ),
            alignment: Alignment.center,
            child: ExcludeSemantics(
              child: Text(widget.label, style: baloo(widget.fontSize, color: widget.textColor)),
            ),
          ),
        ),
      ),
    );
  }
}

/// Plain text button used for secondary actions on the dark screens.
class GhostButton extends StatelessWidget {
  const GhostButton({super.key, required this.label, this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: TextButton(
        onPressed: onPressed ?? () {},
        style: TextButton.styleFrom(foregroundColor: AppColors.textOnDark),
        child: Text(label, style: nunito(15, color: AppColors.textOnDark)),
      ),
    );
  }
}

/// 40×40 rounded-square icon button used in screen headers.
class SquareIconButton extends StatelessWidget {
  const SquareIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.background = AppColors.lavender,
    this.foreground = AppColors.ink,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(12)),
          alignment: Alignment.center,
          child: Icon(icon, color: foreground, size: icon == Icons.chevron_left_rounded ? 28 : 22),
        ),
      ),
    );
  }
}

/// Back button + progress bar + "n/10" counter.
class OnboardingHeader extends StatelessWidget {
  const OnboardingHeader({super.key, required this.step, required this.onBack, this.total = 10});

  final int step;
  final int total;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 4, 22, 0),
      child: Row(
        children: [
          SquareIconButton(icon: Icons.chevron_left_rounded, label: 'Back', onTap: onBack),
          const SizedBox(width: 14),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: Container(
                height: 10,
                color: AppColors.track,
                alignment: Alignment.centerLeft,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: step / total),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, _) => FractionallySizedBox(
                    widthFactor: v,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.pink,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Text('$step/$total', style: nunito(13, color: AppColors.textFaint)),
        ],
      ),
    );
  }
}

/// Standard light onboarding screen: header, scrollable body, pinned CTA.
class FlowPage extends StatelessWidget {
  const FlowPage({
    super.key,
    this.header,
    required this.children,
    required this.footer,
    this.spacing = 14,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
    this.bodyPadding = const EdgeInsets.fromLTRB(22, 18, 22, 8),
  });

  final Widget? header;
  final List<Widget> children;
  final Widget footer;
  final double spacing;
  final CrossAxisAlignment crossAxisAlignment;
  final EdgeInsets bodyPadding;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.cream,
      child: SafeArea(
        child: Column(
          children: [
            ?header,
            Expanded(
              child: SingleChildScrollView(
                padding: bodyPadding,
                child: Column(
                  spacing: spacing,
                  crossAxisAlignment: crossAxisAlignment,
                  children: children,
                ),
              ),
            ),
            Padding(padding: const EdgeInsets.fromLTRB(22, 12, 22, 16), child: footer),
          ],
        ),
      ),
    );
  }
}

/// Mascot with a chat bubble to its right.
class SpeechBubble extends StatelessWidget {
  const SpeechBubble({
    super.key,
    required this.image,
    required this.text,
    this.imageWidth = 88,
    this.bubbleLift = 16,
  });

  final String image;
  final String text;
  final double imageWidth;
  final double bubbleLift;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Image.asset(image, key: ValueKey(image), width: imageWidth),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Container(
            margin: EdgeInsets.only(bottom: bubbleLift),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.line, width: 2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child: Text(text, style: nunito(15, weight: FontWeight.w700, height: 1.35)),
          ),
        ),
      ],
    );
  }
}

/// Small purple "AHA #n" label.
class AhaTag extends StatelessWidget {
  const AhaTag(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.purpleTint,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          text,
          style: nunito(11, weight: FontWeight.w900, letterSpacing: 1.5, color: AppColors.purple),
        ),
      ),
    );
  }
}

/// Small all-caps label (e.g. "TODAY · LESSON 1").
class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.color = AppColors.textFaint});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: nunito(11, weight: FontWeight.w900, letterSpacing: 1.5, color: color),
  );
}

/// Bordered card that highlights pink when selected.
class SelectableCard extends StatelessWidget {
  const SelectableCard({
    super.key,
    required this.selected,
    required this.onTap,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.radius = 18,
    this.selectedColor = AppColors.pink,
    this.selectedFill = AppColors.pinkTint,
  });

  final bool selected;
  final VoidCallback? onTap;
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final Color selectedColor;
  final Color selectedFill;

  @override
  Widget build(BuildContext context) {
    final bd = selected ? selectedColor : AppColors.line;
    return Semantics(
      container: true,
      selected: selected,
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: padding,
          decoration: BoxDecoration(
            color: selected ? selectedFill : Colors.white,
            border: Border.all(color: bd, width: 2),
            borderRadius: BorderRadius.circular(radius),
            boxShadow: hardShadow(bd),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Rotated sticker chip used on the welcome hero.
class Sticker extends StatelessWidget {
  const Sticker({
    super.key,
    required this.text,
    required this.angle,
    required this.bg,
    required this.fg,
    required this.shadow,
  });

  final String text;
  final double angle; // degrees
  final Color bg;
  final Color fg;
  final Color shadow;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle * 3.1415926535 / 180,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          boxShadow: hardShadow(shadow, 4),
        ),
        child: Text(text, style: nunito(14, color: fg)),
      ),
    );
  }
}

/// Tinted tile with a big number and a small caption.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.value,
    required this.label,
    required this.background,
    required this.valueColor,
    required this.labelColor,
    this.valueSize = 30,
    this.labelSize = 13,
    this.padding = const EdgeInsets.all(14),
    this.radius = 20,
    this.centered = false,
  });

  final String value;
  final String label;
  final Color background;
  final Color valueColor;
  final Color labelColor;
  final double valueSize;
  final double labelSize;
  final EdgeInsets padding;
  final double radius;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(radius)),
      child: Column(
        crossAxisAlignment: centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Text(value, style: baloo(valueSize, height: 1, color: valueColor)),
          Text(
            label,
            textAlign: centered ? TextAlign.center : TextAlign.start,
            style: nunito(labelSize, height: 1.2, color: labelColor),
          ),
        ],
      ),
    );
  }
}

/// White card with the standard lilac outline.
class OutlinedCard extends StatelessWidget {
  const OutlinedCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    this.radius = 22,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.line, width: 2),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: child,
    );
  }
}
