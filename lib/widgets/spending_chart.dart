import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

enum ChartInterval { daily, weekly, monthly }

class SpendingChart extends StatefulWidget {
  final List<Expense> expenses;
  final String currencySymbol;
  final ChartInterval defaultInterval;

  const SpendingChart({
    super.key,
    required this.expenses,
    required this.currencySymbol,
    this.defaultInterval = ChartInterval.monthly,
  });

  @override
  State<SpendingChart> createState() => _SpendingChartState();
}

class _SpendingChartState extends State<SpendingChart> {
  late ChartInterval _interval;

  @override
  void initState() {
    super.initState();
    _interval = widget.defaultInterval;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final dataPoints = _aggregateData();

    return Container(
      padding: const EdgeInsets.all(20),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Spending Trend',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              // Segmented interval selector (pill style)
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF242730) : AppColors.lightPillBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(3.5),
                child: Row(
                  children: [
                    _buildIntervalButton('Daily', ChartInterval.daily, isDark),
                    _buildIntervalButton('Weekly', ChartInterval.weekly, isDark),
                    _buildIntervalButton('Monthly', ChartInterval.monthly, isDark),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: dataPoints.isEmpty || dataPoints.every((p) => p.amount == 0)
                ? Center(
                    child: Text(
                      'No expense records in this timeframe',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: _calcHorizontalInterval(dataPoints),
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF1F5F9),
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 42,
                            interval: _calcHorizontalInterval(dataPoints),
                            getTitlesWidget: (value, meta) {
                              if (value == 0) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: Text(
                                  CurrencyFormatter.format(value,
                                      symbol: widget.currencySymbol, compact: true),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 26,
                            interval: max(1, (dataPoints.length / 5).floor().toDouble()),
                            getTitlesWidget: (value, meta) {
                              final idx = value.toInt();
                              if (idx >= 0 && idx < dataPoints.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    dataPoints[idx].label,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: max(1, dataPoints.length - 1).toDouble(),
                      minY: 0,
                      maxY: _calcMaxY(dataPoints),
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                              final idx = spot.x.toInt();
                              final point = idx >= 0 && idx < dataPoints.length ? dataPoints[idx] : null;
                              final dateLabel = point?.fullLabel ?? '';
                              return LineTooltipItem(
                                '$dateLabel\n${CurrencyFormatter.format(spot.y, symbol: widget.currencySymbol)}',
                                const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              );
                            }).toList();
                          },
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: List.generate(dataPoints.length, (i) {
                            return FlSpot(i.toDouble(), dataPoints[i].amount);
                          }),
                          isCurved: true,
                          curveSmoothness: 0.35,
                          preventCurveOverShooting: true,
                          color: AppColors.primary,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: dataPoints.length <= 14,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 3.5,
                                color: AppColors.primary,
                                strokeWidth: 2,
                                strokeColor: Colors.white,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppColors.primary.withAlpha(isDark ? 90 : 70),
                                AppColors.primary.withAlpha(0),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntervalButton(String label, ChartInterval interval, bool isDark) {
    final isSelected = _interval == interval;
    return GestureDetector(
      onTap: () {
        setState(() {
          _interval = interval;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? Colors.white : AppColors.charcoal)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withAlpha(30),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? (isDark ? AppColors.charcoal : Colors.white)
                : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
          ),
        ),
      ),
    );
  }

  double _calcMaxY(List<_DataPoint> points) {
    if (points.isEmpty) return 1000;
    final maxAmt = points.map((p) => p.amount).reduce(max);
    if (maxAmt == 0) return 1000;
    return maxAmt * 1.25;
  }

  double _calcHorizontalInterval(List<_DataPoint> points) {
    final maxY = _calcMaxY(points);
    final raw = maxY / 4;
    if (raw <= 0) return 250;
    return raw;
  }

  List<_DataPoint> _aggregateData() {
    if (widget.expenses.isEmpty) return [];

    final sorted = List<Expense>.from(widget.expenses)
      ..sort((a, b) => a.date.compareTo(b.date));

    final oldest = sorted.first.date;
    final newest = sorted.last.date;

    switch (_interval) {
      case ChartInterval.daily:
        // Aggregate by day (max 30 days window)
        final days = newest.difference(oldest).inDays;
        final start = days > 30 ? newest.subtract(const Duration(days: 30)) : oldest;

        final Map<String, double> map = {};
        for (final exp in sorted) {
          if (!exp.date.isBefore(start)) {
            map[exp.dateString] = (map[exp.dateString] ?? 0.0) + exp.amount;
          }
        }

        final points = <_DataPoint>[];
        var cur = DateTime(start.year, start.month, start.day);
        final end = DateTime(newest.year, newest.month, newest.day);
        final dayFmt = DateFormat('d MMM');

        while (!cur.isAfter(end)) {
          final s = Expense.formatDate(cur);
          points.add(
            _DataPoint(
              label: dayFmt.format(cur),
              fullLabel: DateFormat('d MMM yyyy').format(cur),
              amount: map[s] ?? 0.0,
            ),
          );
          cur = cur.add(const Duration(days: 1));
        }
        return points;

      case ChartInterval.weekly:
        // Aggregate by calendar week
        final Map<String, double> map = {};
        final Map<String, String> labels = {};
        final Map<String, DateTime> weekDates = {};

        for (final exp in sorted) {
          final dt = exp.date;
          final monday = dt.subtract(Duration(days: dt.weekday - 1));
          final key = '${monday.year}-W${monday.month}-${monday.day}';
          map[key] = (map[key] ?? 0.0) + exp.amount;
          labels[key] = DateFormat('d MMM').format(monday);
          weekDates[key] = monday;
        }

        final sortedKeys = map.keys.toList()
          ..sort((a, b) => weekDates[a]!.compareTo(weekDates[b]!));

        return sortedKeys
            .map(
              (k) => _DataPoint(
                label: labels[k]!,
                fullLabel: 'Week of ${DateFormat('d MMM yyyy').format(weekDates[k]!)}',
                amount: map[k]!,
              ),
            )
            .toList();

      case ChartInterval.monthly:
        // Aggregate by month (e.g. Jan 24, Feb 24)
        final Map<String, double> map = {};
        final Map<String, String> labels = {};
        final Map<String, DateTime> monthDates = {};

        for (final exp in sorted) {
          final dt = exp.date;
          final key = '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
          map[key] = (map[key] ?? 0.0) + exp.amount;
          labels[key] = DateFormat('MMM yy').format(dt);
          monthDates[key] = DateTime(dt.year, dt.month, 1);
        }

        final sortedKeys = map.keys.toList()
          ..sort((a, b) => monthDates[a]!.compareTo(monthDates[b]!));

        return sortedKeys
            .map(
              (k) => _DataPoint(
                label: labels[k]!,
                fullLabel: DateFormat('MMMM yyyy').format(monthDates[k]!),
                amount: map[k]!,
              ),
            )
            .toList();
    }
  }
}

class _DataPoint {
  final String label;
  final String fullLabel;
  final double amount;

  _DataPoint({
    required this.label,
    required this.fullLabel,
    required this.amount,
  });
}
