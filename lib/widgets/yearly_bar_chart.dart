import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class YearlyBarChart extends StatefulWidget {
  final Map<int, double> yearlySpending;
  final String currencySymbol;
  final Function(int year) onYearSelected;
  final int? selectedYear;

  const YearlyBarChart({
    super.key,
    required this.yearlySpending,
    required this.currencySymbol,
    required this.onYearSelected,
    this.selectedYear,
  });

  @override
  State<YearlyBarChart> createState() => _YearlyBarChartState();
}

class _YearlyBarChartState extends State<YearlyBarChart> {
  int? _activeYear;

  @override
  void initState() {
    super.initState();
    _activeYear = widget.selectedYear ??
        (widget.yearlySpending.keys.isNotEmpty
            ? widget.yearlySpending.keys.reduce(max)
            : DateTime.now().year);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final sortedYears = widget.yearlySpending.keys.toList()..sort();
    if (sortedYears.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Center(
          child: Text(
            'No multi-year records found',
            style: TextStyle(
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
          ),
        ),
      );
    }

    final maxVal = widget.yearlySpending.values.isEmpty
        ? 1000.0
        : widget.yearlySpending.values.reduce(max);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Yearly Spending Comparison',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tap a year to inspect monthly breakdown',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                  ),
                ],
              ),
              if (_activeYear != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(isDark ? 50 : 30),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Year $_activeYear',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 190,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxVal * 1.25,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final year = sortedYears[group.x.toInt()];
                      return BarTooltipItem(
                        '$year\n${CurrencyFormatter.format(rod.toY, symbol: widget.currencySymbol)}',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                  touchCallback: (event, response) {
                    if (event is FlTapUpEvent && response != null && response.spot != null) {
                      final idx = response.spot!.touchedBarGroupIndex;
                      if (idx >= 0 && idx < sortedYears.length) {
                        final y = sortedYears[idx];
                        setState(() {
                          _activeYear = y;
                        });
                        widget.onYearSelected(y);
                      }
                    }
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        return Text(
                          CurrencyFormatter.format(value,
                              symbol: widget.currencySymbol, compact: true),
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                          textAlign: TextAlign.right,
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx >= 0 && idx < sortedYears.length) {
                          final year = sortedYears[idx];
                          final isSelected = year == _activeYear;
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              year.toString(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                color: isSelected
                                    ? AppColors.primary
                                    : (isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary),
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF1F5F9),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(sortedYears.length, (i) {
                  final year = sortedYears[i];
                  final val = widget.yearlySpending[year] ?? 0.0;
                  final isSelected = year == _activeYear;

                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: val,
                        width: 28,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: isSelected
                              ? [AppColors.primaryDark, AppColors.primary]
                              : [
                                  isDark ? const Color(0xFF334155) : const Color(0xFF94A3B8),
                                  isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                                ],
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Quick list of years with exact values
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: sortedYears.reversed.map((year) {
              final isSelected = year == _activeYear;
              final val = widget.yearlySpending[year] ?? 0.0;
              return InkWell(
                onTap: () {
                  setState(() {
                    _activeYear = year;
                  });
                  widget.onYearSelected(year);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withAlpha(isDark ? 45 : 25)
                        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$year: ',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? AppColors.primary
                              : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                        ),
                      ),
                      Text(
                        CurrencyFormatter.format(val, symbol: widget.currencySymbol),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
