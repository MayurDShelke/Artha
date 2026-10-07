import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Tactile, modern card widget modeled after the smart device tiles in the reference design.
/// Features a top circular icon badge + toggle switch, bold title, and subtitle.
class StatCard extends StatelessWidget {
  final String title;
  final String amount;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final Color? iconBgColor;
  final bool isHighlight; // If true, displays the dark matte charcoal aesthetic from the reference
  final bool isActiveToggle;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.title,
    required this.amount,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.iconBgColor,
    this.isHighlight = false,
    this.isActiveToggle = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Use charcoal for highlighted card (like Smart Light in reference), or crisp white
    final cardBg = isHighlight
        ? AppColors.charcoal
        : (isDark ? AppColors.darkCard : Colors.white);

    final titleColor = isHighlight
        ? Colors.white
        : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary);

    final amountColor = isHighlight
        ? AppColors.cyanLight
        : (isDark ? AppColors.primaryLight : AppColors.charcoal);

    final subColor = isHighlight
        ? Colors.white.withAlpha(165)
        : (isDark ? AppColors.darkTextMuted : AppColors.lightTextSecondary);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isHighlight
                  ? Colors.white.withAlpha(20)
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
              width: 0.8,
            ),
            boxShadow: isHighlight
                ? [
                    BoxShadow(
                      color: Colors.black.withAlpha(50),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : AppColors.softCardShadow(isDark),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Icon circle
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isHighlight
                      ? Colors.white.withAlpha(28)
                      : (isDark
                          ? const Color(0xFF242730)
                          : const Color(0xFFF3F4F6)),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon ?? Icons.wallet_rounded,
                  size: 21,
                  color: isHighlight
                      ? Colors.white
                      : (iconColor ?? (isDark ? Colors.white : AppColors.charcoal)),
                ),
              ),

              const SizedBox(height: 12),

              // Bottom Section: Title & Amount/Subtitle
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 3),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      amount,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: amountColor,
                      ),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: subColor,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
