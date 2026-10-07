import 'package:flutter/material.dart';
import '../models/category.dart';
import '../state/expense_scope.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/category_detail_sheet.dart';
import '../widgets/category_form_dialog.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = ExpenseScope.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Calculate total spend and count per category across entire database
    final Map<String, ({double total, int count})> catStats = {};
    for (final exp in state.expenses) {
      final cur = catStats[exp.categoryId] ?? (total: 0.0, count: 0);
      catStats[exp.categoryId] = (total: cur.total + exp.amount, count: cur.count + 1);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        actions: [
          IconButton(
            tooltip: 'Add Category',
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const CategoryFormDialog(),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: state.categories.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final cat = state.categories[index];
          final stats = catStats[cat.id] ?? (total: 0.0, count: 0);

          return InkWell(
            onTap: () => CategoryDetailSheet.show(context, cat),
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: cat.color.withAlpha(isDark ? 50 : 35),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(cat.iconData, color: cat.color, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              cat.name,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                            ),
                            if (cat.isDefault) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Default',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${stats.count} transactions • Total: ${CurrencyFormatter.format(stats.total, symbol: state.currencySymbol)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Actions: Edit & Delete
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      size: 20,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                    onSelected: (action) {
                      if (action == 'edit') {
                        showDialog(
                          context: context,
                          builder: (_) => CategoryFormDialog(initialCategory: cat),
                        );
                      } else if (action == 'delete') {
                        _handleDeleteCategory(context, cat, stats.count);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: AppColors.danger)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_cat',
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => const CategoryFormDialog(),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Future<void> _handleDeleteCategory(BuildContext context, Category cat, int expensesCount) async {
    final state = ExpenseScope.of(context);

    if (expensesCount > 0) {
      // Must safely reassign existing expenses
      String targetCategoryId = state.categories.firstWhere((c) => c.id != cat.id).id;

      final result = await showDialog<String>(
        context: context,
        builder: (dialogCtx) => StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            final availableTargets = state.categories.where((c) => c.id != cat.id).toList();

            return AlertDialog(
              title: Text('Delete "${cat.name}"?'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'There are $expensesCount expenses assigned to "${cat.name}". Please choose another category to reassign them to:',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: targetCategoryId,
                    decoration: const InputDecoration(labelText: 'Reassign to'),
                    items: availableTargets.map((c) {
                      return DropdownMenuItem(
                        value: c.id,
                        child: Row(
                          children: [
                            Icon(c.iconData, size: 18, color: c.color),
                            const SizedBox(width: 8),
                            Text(c.name),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          targetCategoryId = val;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(null),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                  onPressed: () => Navigator.of(dialogCtx).pop(targetCategoryId),
                  child: const Text('Reassign & Delete'),
                ),
              ],
            );
          },
        ),
      );

      if (result != null) {
        await state.deleteCategory(cat.id, reassignToCategoryId: result);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Category deleted and $expensesCount expenses reassigned')),
          );
        }
      }
    } else {
      // Safe to delete directly
      final confirm = await showDialog<bool>(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          title: Text('Delete "${cat.name}"?'),
          content: const Text('Are you sure you want to delete this category?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
              onPressed: () => Navigator.of(dialogCtx).pop(true),
              child: const Text('Delete'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        await state.deleteCategory(cat.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Category deleted')),
          );
        }
      }
    }
  }
}
