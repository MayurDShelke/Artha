import 'package:flutter/material.dart';
import '../state/expense_scope.dart';
import '../theme/app_theme.dart';
import '../utils/app_date_utils.dart';
import '../utils/formatters.dart';
import '../widgets/advanced_filter_sheet.dart';
import '../widgets/expense_card.dart';
import '../widgets/expense_form_dialog.dart';
import '../widgets/filter_bar.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ExpenseScope.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final groupedExpenses = state.groupedByDateExpenses;
    final sortedDateKeys = groupedExpenses.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    final isSearchActive = state.filter.searchQuery.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search petrol, lunch, notes...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  fillColor: Colors.transparent,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _searchController.clear();
                      state.setSearchQuery('');
                      setState(() {
                        _isSearching = false;
                      });
                    },
                  ),
                ),
                onChanged: (val) => state.setSearchQuery(val),
              )
            : const Text('Expenses History'),
        actions: [
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: 'Search expenses',
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
              },
            ),
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Filter',
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
      body: Column(
        children: [
          // Filter presets bar
          Padding(
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

          // Search Stats banner if search active
          if (isSearchActive)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(isDark ? 30 : 20),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary.withAlpha(60)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Search: "${state.filter.searchQuery}"',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      Text(
                        '${state.totalTransactions} matches • Avg: ${CurrencyFormatter.format(state.averageExpense, symbol: state.currencySymbol)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    CurrencyFormatter.format(state.totalSpent, symbol: state.currencySymbol),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),

          // Total spent for active view
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${state.filteredExpenses.length} transactions (${state.filter.quickFilter.title})',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                ),
                Text(
                  'Total: ${CurrencyFormatter.format(state.totalSpent, symbol: state.currencySymbol)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // Grouped Expense List
          Expanded(
            child: sortedDateKeys.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.receipt_long_rounded,
                            size: 56,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No expenses found',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isSearchActive
                                ? 'No results matching "${state.filter.searchQuery}". Try a different keyword or reset filters.'
                                : 'No expenses recorded in the selected date range.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                            ),
                          ),
                          const SizedBox(height: 18),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Add Expense'),
                            onPressed: () => ExpenseFormDialog.show(context),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: sortedDateKeys.length,
                    itemBuilder: (context, dateIndex) {
                      final dateStr = sortedDateKeys[dateIndex];
                      final dayExpenses = groupedExpenses[dateStr]!;
                      final dayTotal = dayExpenses.fold(0.0, (s, e) => s + e.amount);
                      final dateObj = dayExpenses.first.date;
                      final headerTitle = AppDateUtils.formatGroupHeader(dateObj);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date Group Header
                          Padding(
                            padding: const EdgeInsets.only(top: 14, bottom: 8, left: 4, right: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  headerTitle,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.2,
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF1E293B)
                                        : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    CurrencyFormatter.format(dayTotal,
                                        symbol: state.currencySymbol),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? AppColors.darkTextPrimary
                                          : AppColors.lightTextPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // List of expenses on this day
                          ...dayExpenses.map((expense) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: ExpenseCard(
                                expense: expense,
                                showDate: false, // Header already shows date
                              ),
                            );
                          }),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
