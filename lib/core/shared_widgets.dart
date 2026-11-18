import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'constants.dart';

class PrimaryPillButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? trailingIcon;
  final IconData? leadingIcon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double height;

  const PrimaryPillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.trailingIcon,
    this.leadingIcon,
    this.backgroundColor,
    this.foregroundColor,
    this.height = 54.0,
  });

  @override
  State<PrimaryPillButton> createState() => _PrimaryPillButtonState();
}

class _PrimaryPillButtonState extends State<PrimaryPillButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final enabled = widget.onPressed != null && !widget.isLoading;
    final themePrimary = Theme.of(context).colorScheme.primary;
    final themeSecondary = Theme.of(context).colorScheme.secondary;
    final bg = widget.backgroundColor ?? themePrimary;
    final fg = widget.foregroundColor ?? Colors.white;

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _isPressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _isPressed = false) : null,
        onTap: enabled ? widget.onPressed : null,
        child: AnimatedScale(
          scale: (!reduceMotion && _isPressed) ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: widget.height,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(FitNepalSpacing.pillRadius),
              gradient: enabled && widget.backgroundColor == null
                  ? LinearGradient(
                      colors: [themeSecondary, themePrimary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: !enabled
                  ? bg.withOpacity(0.42)
                  : (widget.backgroundColor != null ? bg : null),
              boxShadow: enabled
                  ? [
                      BoxShadow(
                        color: bg.withOpacity(_isPressed ? 0.16 : 0.28),
                        blurRadius: _isPressed ? 8 : 16,
                        offset: Offset(0, _isPressed ? 2 : 6),
                      ),
                    ]
                  : const [],
            ),
            child: Center(
              child: widget.isLoading
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(fg),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.leadingIcon != null) ...[
                          Icon(widget.leadingIcon, color: fg, size: 20),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Text(
                            widget.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: fg,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        if (widget.trailingIcon != null) ...[
                          const SizedBox(width: 8),
                          Icon(widget.trailingIcon, color: fg, size: 20),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class FitNepalCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final VoidCallback? onTap;
  final double borderRadius;
  final Border? border;

  const FitNepalCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(FitNepalSpacing.cardPadding),
    this.color,
    this.onTap,
    this.borderRadius = FitNepalSpacing.cardRadius,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final bgColor = color ?? Theme.of(context).colorScheme.surface;
    final defaultBorder = border ??
        Border.all(
          color: isDark
              ? FitNepalColors.darkBorder
              : primaryColor.withOpacity(0.14),
          width: 1.0,
        );

    final box = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: defaultBorder,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.22)
                : primaryColor.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );

    if (onTap == null) return box;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: box,
      ),
    );
  }
}

class AnimatedCalorieRing extends StatelessWidget {
  final double progress;
  final String centerLabel;
  final String? subLabel;
  final double size;
  final double strokeWidth;
  final Color activeColor;
  final Color trackColor;
  final TextStyle? centerTextStyle;
  final TextStyle? subTextStyle;
  final String semanticLabel;

  const AnimatedCalorieRing({
    super.key,
    required this.progress,
    required this.centerLabel,
    this.subLabel,
    this.size = 76,
    this.strokeWidth = 8.0,
    this.activeColor = Colors.white,
    this.trackColor = const Color(0x44FFFFFF),
    this.centerTextStyle,
    this.subTextStyle,
    required this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final safeProgress = progress.clamp(0.0, 1.0);

    return Semantics(
      label: semanticLabel,
      value: centerLabel,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(
          begin: reduceMotion ? safeProgress : 0.0,
          end: safeProgress,
        ),
        duration: reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 550),
        curve: Curves.easeOutCubic,
        builder: (context, animatedValue, _) {
          return SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              painter: _CalorieRingPainter(
                progress: animatedValue,
                strokeWidth: strokeWidth,
                activeColor: activeColor,
                trackColor: trackColor,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      centerLabel,
                      style: centerTextStyle ??
                          const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                    ),
                    if (subLabel != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subLabel!,
                        style: subTextStyle ??
                            const TextStyle(
                              color: FitNepalColors.mutedPlum,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CalorieRingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color activeColor;
  final Color trackColor;

  _CalorieRingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.activeColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress > 0.001) {
      final activePaint = Paint()
        ..color = activeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        activePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CalorieRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.trackColor != trackColor;
  }
}

class MacroMetricCard extends StatelessWidget {
  final String label;
  final double consumedG;
  final double targetG;
  final IconData icon;
  final Color backgroundColor;
  final Color accentColor;
  final VoidCallback? onTap;

  const MacroMetricCard({
    super.key,
    required this.label,
    required this.consumedG,
    required this.targetG,
    required this.icon,
    required this.backgroundColor,
    required this.accentColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg =
        isDark ? Theme.of(context).colorScheme.surface : backgroundColor;
    final textColor =
        isDark ? FitNepalColors.darkTextPrimary : FitNepalColors.deepPlum;
    final subColor =
        isDark ? FitNepalColors.darkTextSecondary : FitNepalColors.mutedPlum;
    final ratio = (consumedG / math.max(1.0, targetG)).clamp(0.0, 1.0);

    return Semantics(
      label:
          '$label: ${consumedG.round()} grams consumed of ${targetG.round()} grams target',
      button: onTap != null,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: accentColor.withOpacity(isDark ? 0.35 : 0.16),
              width: 1.0,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: accentColor, size: 24),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: subColor,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${consumedG.round()}g',
                style: TextStyle(
                  color: textColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 4,
                  backgroundColor: accentColor.withOpacity(0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CategoryChipBar extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onSelected;

  const CategoryChipBar({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onSelected,
  });

  static String _localizeCat(BuildContext context, String cat) {
    final lang = Localizations.localeOf(context).languageCode;
    if (lang != 'ne') return cat;
    switch (cat) {
      case 'All':
        return 'सबै';
      case 'Fruits':
        return 'फलफूल';
      case 'Meals':
        return 'मुख्य खाना';
      case 'Snacks':
        return 'खाजा';
      case 'Drinks':
        return 'पेय पदार्थ';
      case 'Dairy':
        return 'दुग्ध पदार्थ';
      case 'Custom':
        return 'कस्टम';
      default:
        return cat;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: FitNepalSpacing.screenHorizontal,
        ),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = cat == selectedCategory;

          return Semantics(
            selected: isSelected,
            button: true,
            label: '$cat category filter',
            child: InkWell(
              onTap: () => onSelected(cat),
              borderRadius: BorderRadius.circular(FitNepalSpacing.pillRadius),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                decoration: BoxDecoration(
                  color: isSelected
                      ? primaryColor
                      : (isDark
                          ? Theme.of(context).colorScheme.surface
                          : FitNepalColors.chipUnselectedFill),
                  borderRadius:
                      BorderRadius.circular(FitNepalSpacing.pillRadius),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  _localizeCat(context, cat),
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : (isDark
                            ? FitNepalColors.darkTextPrimary
                            : FitNepalColors.deepPlum),
                    fontSize: 13.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class EmptyStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const EmptyStateCard({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    return FitNepalCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: primaryColor, size: 26),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark
                  ? FitNepalColors.darkTextPrimary
                  : FitNepalColors.deepPlum,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark
                  ? FitNepalColors.darkTextSecondary
                  : FitNepalColors.mutedPlum,
              fontSize: 13.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 44,
            child: ElevatedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(actionLabel),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(FitNepalSpacing.pillRadius),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
