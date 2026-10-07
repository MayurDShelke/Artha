import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/expense.dart';
import '../state/expense_scope.dart';
import '../state/expense_state.dart';
import '../theme/app_theme.dart';
import '../utils/app_date_utils.dart';
import '../utils/formatters.dart';
import 'expense_form_dialog.dart';

class ExpenseCard extends StatelessWidget {
  final Expense expense;
  final Category? category;
  final bool showDate;

  const ExpenseCard({
    super.key,
    required this.expense,
    this.category,
    this.showDate = true,
  });

  @override
  Widget build(BuildContext context) {
    final state = ExpenseScope.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cat = category ??
        state.categoryMap[expense.categoryId] ??
        Category(
          id: expense.categoryId,
          name: 'Other',
          iconCodePoint: Icons.category.codePoint,
          colorValue: Colors.grey.toARGB32(),
          createdAt: DateTime.now(),
        );

    final dateText = AppDateUtils.formatListDate(expense.date);

    return InkWell(
      onTap: () => _showExpenseDetailsSheet(context, state, cat),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 0.8,
          ),
          boxShadow: AppColors.softCardShadow(isDark),
        ),
        child: Row(
          children: [
            // Circular Category Icon Badge (matching reference)
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF242730) : const Color(0xFFF3F4F6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                cat.iconData,
                color: cat.color,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            // Title & Category/Date subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if (showDate) ...[
                        Text(
                          dateText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                        ),
                        Text(
                          ' • ',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                        ),
                      ],
                      Text(
                        cat.name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: cat.color,
                        ),
                      ),
                      if (expense.paymentMethod.isNotEmpty) ...[
                        Text(
                          ' • ',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                        ),
                        Text(
                          expense.paymentMethod,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Amount
            Text(
              CurrencyFormatter.format(expense.amount, symbol: state.currencySymbol),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExpenseDetailsSheet(BuildContext context, ExpenseState state, Category cat) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cat.color.withAlpha(isDark ? 50 : 35),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(cat.iconData, color: cat.color, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            expense.title,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            cat.name,
                            style: TextStyle(color: cat.color, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(expense.amount, symbol: state.currencySymbol),
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),
                _buildDetailRow('Date', AppDateUtils.formatFull(expense.date)),
                _buildDetailRow('Payment Method', expense.paymentMethod),
                if (expense.location.isNotEmpty) _buildDetailRow('Location', expense.location),
                if (expense.notes.isNotEmpty) _buildDetailRow('Notes', expense.notes),
                _buildDetailRow('Recorded On', expense.createdAt.toString().split('.')[0]),
                if (expense.isRecurring) _buildDetailRow('Type', 'Recurring Expense'),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Edit'),
                        onPressed: () {
                          Navigator.of(sheetContext).pop();
                          ExpenseFormDialog.show(context, expense: expense);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Delete'),
                        onPressed: () async {
                          Navigator.of(sheetContext).pop();
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete Expense?'),
                              content: Text('Are you sure you want to delete "${expense.title}"?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                                  onPressed: () => Navigator.of(ctx).pop(true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await state.deleteExpense(expense.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Expense deleted')),
                              );
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
