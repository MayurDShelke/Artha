import 'dart:math';
import 'package:flutter/material.dart';
import '../models/filter_options.dart';
import '../state/expense_scope.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'expense_form_dialog.dart';

/// Radial Spending Controller modeled directly after the right screen in the reference image.
/// Displays an interactive circular arc dial, mode pills, power/spending consumption stats,
/// and quick actions.
class SpendingDialController extends StatefulWidget {
  const SpendingDialController({super.key});

  @override
  State<SpendingDialController> createState() => _SpendingDialControllerState();
}

class _SpendingDialControllerState extends State<SpendingDialController> {
  int _selectedFilterIdx = 1; // Default 1M
  int _selectedModeIdx = 0; // 0: All, 1: UPI, 2: Card, 3: Cash

  final List<(String, QuickFilterType)> _filters = [
    ('1W', QuickFilterType.oneWeek),
    ('1M', QuickFilterType.oneMonth),
    ('3M', QuickFilterType.threeMonths),
    ('6M', QuickFilterType.sixMonths),
    ('1Y', QuickFilterType.oneYear),
    ('All', QuickFilterType.allTime),
  ];

  final List<(String, IconData)> _modes = [
    ('All', Icons.apps_rounded),
    ('UPI', Icons.bolt_rounded),
    ('Card', Icons.credit_card_rounded),
    ('Cash', Icons.payments_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final state = ExpenseScope.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Calculate intensity percentage (relative to monthly budget or last month comparison)
    final thisMonth = state.thisMonthSpending;
    final lastMonth = state.lastMonthSpending;
    double intensityPct = 0.0;
    if (lastMonth > 0) {
      intensityPct = min(100.0, (thisMonth / lastMonth) * 100.0);
    } else if (thisMonth > 0) {
      intensityPct = 75.0; // Default sensible reading if no previous baseline
    } else {
      intensityPct = 0.0;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 1. Top Pill Filter Row (Matching the 8 watt, 9 watt, 12.5 watt pills in reference)
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            itemCount: _filters.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, idx) {
              final isSelected = _selectedFilterIdx == idx;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedFilterIdx = idx;
                  });
                  state.setQuickFilter(_filters[idx].$2);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark ? Colors.white : AppColors.charcoal)
                        : (isDark ? AppColors.darkSurface : Colors.white),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      width: 0.8,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Colors.black.withAlpha(30),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      _filters[idx].$1,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: isSelected
                            ? (isDark ? AppColors.charcoal : Colors.white)
                            : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 24),

        // "Controller" Label from reference
        Text(
          'Spending Intensity',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            letterSpacing: 0.2,
          ),
        ),

        const SizedBox(height: 18),

        // 2. Circular Arc Dial Gauge (1:1 with reference image!)
        SizedBox(
          width: 220,
          height: 180,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(200, 170),
                painter: _ArcDialPainter(
                  percentage: intensityPct,
                  isDark: isDark,
                  accentColor: AppColors.cyanAccent,
                ),
              ),
              // Inside Center Reading
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 14),
                  Text(
                    '${intensityPct.toInt()}%',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                      color: isDark ? Colors.white : AppColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Pace vs Last Mo',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                  ),
                ],
              ),
              // Min • and • Max Indicator Labels
              Positioned(
                bottom: 6,
                left: 14,
                child: Row(
                  children: [
                    Text(
                      'Min',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 6,
                right: 14,
                child: Row(
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Max',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // 3. 4 Mode Control Buttons (Auto, Cool, Day, Night style in reference)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(_modes.length, (idx) {
            final isSelected = _selectedModeIdx == idx;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedModeIdx = idx;
                });
              },
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.charcoal
                          : (isDark ? AppColors.darkCard : Colors.white),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        width: 0.8,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.black.withAlpha(50),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : AppColors.softCardShadow(isDark),
                    ),
                    child: Icon(
                      _modes[idx].$2,
                      size: 22,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _modes[idx].$1,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? (isDark ? Colors.white : AppColors.charcoal)
                          : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),

        const SizedBox(height: 24),

        // 4. Power / Spending Consumption Card (Matching reference card)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 0.8,
            ),
            boxShadow: AppColors.softCardShadow(isDark),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Spending Consumption',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  // Today Stat
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF242730) : AppColors.charcoal,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              CurrencyFormatter.format(state.todaySpending, symbol: state.currencySymbol),
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                            ),
                            Text(
                              'Today',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // This Month Stat
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF242730) : const Color(0xFFE5E7EB),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.account_balance_wallet_rounded,
                              color: isDark ? Colors.white : AppColors.charcoal, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              CurrencyFormatter.format(state.thisMonthSpending, symbol: state.currencySymbol),
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                            ),
                            Text(
                              'This month',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 5. "Add Expense" Bottom Button (matching "Add new device" in reference)
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? Colors.white : AppColors.charcoal,
              foregroundColor: isDark ? AppColors.charcoal : Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
              elevation: 0,
            ),
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text(
              'Add New Expense',
              style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
            ),
            onPressed: () => ExpenseFormDialog.show(context),
          ),
        ),
      ],
    );
  }
}

/// Custom Arc Painter for the Dial Controller
class _ArcDialPainter extends CustomPainter {
  final double percentage;
  final bool isDark;
  final Color accentColor;

  _ArcDialPainter({
    required this.percentage,
    required this.isDark,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.72);
    final radius = size.width * 0.44;

    const startAngle = pi * 0.8;
    const totalAngle = pi * 1.4;

    // Background track arc
    final trackPaint = Paint()
      ..color = isDark ? const Color(0xFF242730) : const Color(0xFFE5E7EB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      totalAngle,
      false,
      trackPaint,
    );

    // Active cyan arc
    final sweepAngle = (percentage / 100.0).clamp(0.02, 1.0) * totalAngle;
    final activePaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      activePaint,
    );

    // Thumb dot at arc tip
    final thumbAngle = startAngle + sweepAngle;
    final thumbX = center.dx + radius * cos(thumbAngle);
    final thumbY = center.dy + radius * sin(thumbAngle);

    final dotPaint = Paint()..color = isDark ? Colors.white : AppColors.charcoal;
    canvas.drawCircle(Offset(thumbX, thumbY), 6.5, dotPaint);

    final innerDotPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(thumbX, thumbY), 2.5, innerDotPaint);
  }

  @override
  bool shouldRepaint(covariant _ArcDialPainter oldDelegate) {
    return oldDelegate.percentage != percentage ||
        oldDelegate.isDark != isDark ||
        oldDelegate.accentColor != accentColor;
  }
}
