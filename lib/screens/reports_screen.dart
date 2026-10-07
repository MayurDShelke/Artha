import 'package:flutter/material.dart';
import '../models/category.dart';
import '../state/expense_scope.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/advanced_filter_sheet.dart';
import '../widgets/category_detail_sheet.dart';
import '../widgets/category_pie_chart.dart';
import '../widgets/filter_bar.dart';
import '../widgets/spending_chart.dart';
import '../widgets/yearly_bar_chart.dart';
import 'export_report_sheet.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int? _selectedYearForMonthlyBreakdown;

  @override
  Widget build(BuildContext context) {
    final state = ExpenseScope.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final filterTitle = state.filter.quickFilter.title;
    final monthComp = state.monthComparison;
    final weekComp = state.weekComparison;
    final yearComp = state.yearComparison;

    final selectedYear = _selectedYearForMonthlyBreakdown ??
        (state.yearlySpendingOverview.keys.isNotEmpty
            ? state.yearlySpendingOverview.keys.reduce((a, b) => a > b ? a : b)
            : DateTime.now().year);

    final monthlyBreakdownForYear = state.getMonthlySpendingForYear(selectedYear);

    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Reports & Analytics'),
        actions: [
          IconButton(
            tooltip: 'Export Report',
            icon: const Icon(Icons.file_download_outlined),
            onPressed: () {
              ExportReportSheet.show(context);
            },
          ),
          IconButton(
            tooltip: 'Filter',
            icon: const Icon(Icons.tune_rounded),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => AdvancedFilterSheet(initialFilter: state.filter),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Filter Chips Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: FilterBar(
                currentFilter: state.filter,
                onSelectQuickFilter: (type) => state.setQuickFilter(type),
                onOpenAdvancedFilters: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => AdvancedFilterSheet(initialFilter: state.filter),
                  );
                },
              ),
            ),
          ),

          // Main Reports Body
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Report Overview Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(isDark ? 30 : 6),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'EXPENSE REPORT',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withAlpha(isDark ? 45 : 25),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                filterTitle,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            CurrencyFormatter.format(state.totalSpent, symbol: state.currencySymbol),
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Divider(),
                        const SizedBox(height: 12),
                        // Statistics Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildStatColumn(
                              'Average',
                              '${CurrencyFormatter.format(state.monthlyAverage, symbol: state.currencySymbol, compact: true)}/mo',
                              isDark,
                            ),
                            _buildStatColumn(
                              'Highest',
                              CurrencyFormatter.format(state.highestExpense,
                                  symbol: state.currencySymbol, compact: true),
                              isDark,
                            ),
                            _buildStatColumn(
                              'Lowest',
                              CurrencyFormatter.format(state.lowestExpense,
                                  symbol: state.currencySymbol, compact: true),
                              isDark,
                            ),
                            _buildStatColumn(
                              'Count',
                              '${state.totalTransactions} txns',
                              isDark,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 2. Spending Trend Chart
                  SpendingChart(
                    expenses: state.filteredExpenses,
                    currencySymbol: state.currencySymbol,
                    defaultInterval: ChartInterval.monthly,
                  ),

                  const SizedBox(height: 24),

                  // 3. Category Analytics Donut & List
                  CategoryPieChart(
                    breakdown: state.categoryBreakdown,
                    currencySymbol: state.currencySymbol,
                    onCategoryTap: (Category cat) {
                      CategoryDetailSheet.show(context, cat);
                    },
                  ),

                  const SizedBox(height: 24),

                  // 4. Time Comparison Section (This Month vs Last Month, This Week vs Last Week, This Year vs Last Year)
                  Text(
                    'Time Comparisons',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildComparisonCard(
                    title: 'This Month vs Last Month',
                    currentLabel: 'This Month',
                    currentValue: state.thisMonthSpending,
                    previousLabel: 'Last Month',
                    previousValue: state.lastMonthSpending,
                    diff: monthComp.diff,
                    percent: monthComp.percentChange,
                    symbol: state.currencySymbol,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 10),
                  _buildComparisonCard(
                    title: 'This Week vs Last Week',
                    currentLabel: 'This Week',
                    currentValue: state.thisWeekSpending,
                    previousLabel: 'Last Week',
                    previousValue: state.lastWeekSpending,
                    diff: weekComp.diff,
                    percent: weekComp.percentChange,
                    symbol: state.currencySymbol,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 10),
                  _buildComparisonCard(
                    title: 'This Year vs Last Year',
                    currentLabel: 'This Year',
                    currentValue: state.thisYearSpending,
                    previousLabel: 'Last Year',
                    previousValue: state.lastYearSpending,
                    diff: yearComp.diff,
                    percent: yearComp.percentChange,
                    symbol: state.currencySymbol,
                    isDark: isDark,
                  ),

                  const SizedBox(height: 28),

                  // 5. Yearly Overview (Multi-year comparison)
                  YearlyBarChart(
                    yearlySpending: state.yearlySpendingOverview,
                    currencySymbol: state.currencySymbol,
                    selectedYear: selectedYear,
                    onYearSelected: (y) {
                      setState(() {
                        _selectedYearForMonthlyBreakdown = y;
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  // 6. Monthly Breakdown for Selected Year
                  Container(
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
                            Text(
                              'Monthly Breakdown: $selectedYear',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                            ),
                            Text(
                              'Full Year Total: ${CurrencyFormatter.format(monthlyBreakdownForYear.fold(0.0, (s, a) => s + a), symbol: state.currencySymbol)}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ...List.generate(12, (mIdx) {
                          final amt = monthlyBreakdownForYear[mIdx];
                          final maxMo = monthlyBreakdownForYear.reduce((a, b) => a > b ? a : b);
                          final fraction = maxMo > 0 ? (amt / maxMo).clamp(0.0, 1.0) : 0.0;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 36,
                                  child: Text(
                                    monthNames[mIdx],
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: LinearProgressIndicator(
                                      value: fraction,
                                      minHeight: 8,
                                      backgroundColor: isDark
                                          ? const Color(0xFF1E293B)
                                          : const Color(0xFFF1F5F9),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        amt > 0 ? AppColors.primary : Colors.transparent,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                SizedBox(
                                  width: 80,
                                  child: Text(
                                    amt > 0
                                        ? CurrencyFormatter.format(amt, symbol: state.currencySymbol)
                                        : '—',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: amt > 0 ? FontWeight.w700 : FontWeight.w400,
                                      color: amt > 0
                                          ? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)
                                          : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Export CTA Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () => ExportReportSheet.show(context),
                      icon: const Icon(Icons.download_rounded),
                      label: const Text('Export Report (CSV / Summary / Print)'),
                    ),
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildComparisonCard({
    required String title,
    required String currentLabel,
    required double currentValue,
    required String previousLabel,
    required double previousValue,
    required double diff,
    required double percent,
    required String symbol,
    required bool isDark,
  }) {
    final isIncrease = diff > 0;
    final isNeutral = diff == 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161F30) : Colors.white,
        borderRadius: BorderRadius.circular(18),
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
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isNeutral
                      ? Colors.grey.withAlpha(40)
                      : (isIncrease
                          ? AppColors.danger.withAlpha(isDark ? 40 : 25)
                          : AppColors.primary.withAlpha(isDark ? 40 : 25)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isNeutral
                          ? Icons.remove
                          : (isIncrease ? Icons.arrow_upward : Icons.arrow_downward),
                      size: 12,
                      color: isNeutral
                          ? Colors.grey
                          : (isIncrease ? AppColors.danger : AppColors.primary),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${CurrencyFormatter.formatPercent(percent.abs(), includeSign: false)} (${diff >= 0 ? '+' : ''}${CurrencyFormatter.format(diff, symbol: symbol)})',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isNeutral
                            ? Colors.grey
                            : (isIncrease ? AppColors.danger : AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentLabel,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.format(currentValue, symbol: symbol),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      previousLabel,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.format(previousValue, symbol: symbol),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
