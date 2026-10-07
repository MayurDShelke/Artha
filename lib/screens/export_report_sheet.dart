import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/expense_scope.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class ExportReportSheet extends StatelessWidget {
  const ExportReportSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ExportReportSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ExpenseScope.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final filterTitle = state.filter.quickFilter.title;
    final topCat = state.categoryBreakdown.isNotEmpty ? state.categoryBreakdown.first : null;

    final summaryText = '''
==============================
IMREXPENSE - EXPENSE REPORT
==============================
Date Range: $filterTitle
Generated: ${DateTime.now().toString().split('.')[0]}

SUMMARY:
• Total Expenses: ${CurrencyFormatter.format(state.totalSpent, symbol: state.currencySymbol)}
• Number of Transactions: ${state.totalTransactions}
• Average Expense: ${CurrencyFormatter.format(state.averageExpense, symbol: state.currencySymbol)}
• Highest Expense: ${CurrencyFormatter.format(state.highestExpense, symbol: state.currencySymbol)}
• Top Category: ${topCat != null ? '${topCat.category.name} (${CurrencyFormatter.format(topCat.total, symbol: state.currencySymbol)} - ${topCat.percentage.toStringAsFixed(1)}%)' : 'N/A'}

CATEGORY BREAKDOWN:
${state.categoryBreakdown.map((c) => '• ${c.category.name.padRight(16)}: ${CurrencyFormatter.format(c.total, symbol: state.currencySymbol)} (${c.percentage.toStringAsFixed(1)}%) - ${c.count} txns').join('\n')}

TRANSACTIONS (${state.filteredExpenses.length}):
Date       | Category       | Amount       | Title
${state.filteredExpenses.map((e) {
      final cName = state.categoryMap[e.categoryId]?.name ?? 'Other';
      return '${e.dateString} | ${cName.padRight(14)} | ${CurrencyFormatter.format(e.amount, symbol: state.currencySymbol).padRight(12)} | ${e.title}';
    }).join('\n')}
==============================
''';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 6),
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Export Expense Report',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    Text(
                      'Filter: $filterTitle (${state.filteredExpenses.length} records)',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Summary Highlights Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161F30) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Column(
              children: [
                _buildRow('Total Spending', CurrencyFormatter.format(state.totalSpent, symbol: state.currencySymbol), isDark),
                _buildRow('Transactions', '${state.totalTransactions}', isDark),
                _buildRow('Average Expense', CurrencyFormatter.format(state.averageExpense, symbol: state.currencySymbol), isDark),
                _buildRow('Highest Expense', CurrencyFormatter.format(state.highestExpense, symbol: state.currencySymbol), isDark),
                if (topCat != null)
                  _buildRow('Top Category', '${topCat.category.name} (${topCat.percentage.toStringAsFixed(1)}%)', isDark),
              ],
            ),
          ),

          // Export Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.table_view_rounded, size: 18),
                    label: const Text('Copy CSV'),
                    onPressed: () {
                      final csv = state.exportCsv();
                      Clipboard.setData(ClipboardData(text: csv));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('CSV report copied to clipboard! Ready to paste into Excel or Sheets.'),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                      foregroundColor: isDark ? Colors.white : AppColors.lightTextPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: const Text('Copy Summary'),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: summaryText));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Report summary copied to clipboard!'),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Preview Area
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Report Preview',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),

          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  summaryText,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String val, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
          Text(val, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
        ],
      ),
    );
  }
}
