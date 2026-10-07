import 'dart:math';
import 'package:flutter/material.dart';
import '../models/category.dart';
import '../state/expense_scope.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'expense_card.dart';

class CategoryDetailSheet extends StatelessWidget {
  final Category category;

  const CategoryDetailSheet({super.key, required this.category});

  static void show(BuildContext context, Category category) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CategoryDetailSheet(category: category),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ExpenseScope.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final catExpenses = state.filteredExpenses
        .where((e) => e.categoryId == category.id)
        .toList();

    final total = catExpenses.fold(0.0, (sum, e) => sum + e.amount);
    final count = catExpenses.length;
    final avg = count > 0 ? total / count : 0.0;
    final highest = count > 0 ? catExpenses.map((e) => e.amount).reduce(max) : 0.0;

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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: category.color.withAlpha(isDark ? 50 : 35),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(category.iconData, color: category.color, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${category.name} Expenses',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      Text(
                        '$count transactions in selected range',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Statistics Summary row
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildMetricBox('Total', CurrencyFormatter.format(total, symbol: state.currencySymbol), isDark),
                const SizedBox(width: 8),
                _buildMetricBox('Average', CurrencyFormatter.format(avg, symbol: state.currencySymbol), isDark),
                const SizedBox(width: 8),
                _buildMetricBox('Highest', CurrencyFormatter.format(highest, symbol: state.currencySymbol), isDark),
              ],
            ),
          ),
          // Transactions list
          Expanded(
            child: catExpenses.isEmpty
                ? Center(
                    child: Text(
                      'No ${category.name} expenses found',
                      style: TextStyle(color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: catExpenses.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, idx) {
                      return ExpenseCard(
                        expense: catExpenses[idx],
                        category: category,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricBox(String label, String value, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
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
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
