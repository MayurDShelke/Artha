import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../state/expense_scope.dart';
import '../theme/app_theme.dart';
import '../utils/app_date_utils.dart';
import '../utils/formatters.dart';
import '../widgets/expense_card.dart';
import '../widgets/expense_form_dialog.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _displayedMonth;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _displayedMonth = DateTime(now.year, now.month, 1);
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    final state = ExpenseScope.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final selectedDateStr = Expense.formatDate(_selectedDate);
    final dayExpenses = state.expenses.where((e) => e.dateString == selectedDateStr).toList();
    final dayTotal = dayExpenses.fold(0.0, (s, e) => s + e.amount);

    // Compute month totals map
    final Map<int, double> dailyTotalsThisMonth = {};
    for (final exp in state.expenses) {
      if (exp.date.year == _displayedMonth.year && exp.date.month == _displayedMonth.month) {
        final day = exp.date.day;
        dailyTotalsThisMonth[day] = (dailyTotalsThisMonth[day] ?? 0.0) + exp.amount;
      }
    }
    final monthTotal = dailyTotalsThisMonth.values.fold(0.0, (s, v) => s + v);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Calendar'),
        actions: [
          IconButton(
            tooltip: 'Jump to Month / Year',
            icon: const Icon(Icons.date_range_outlined),
            onPressed: () => _pickMonthYear(context),
          ),
          IconButton(
            tooltip: 'Today',
            icon: const Icon(Icons.today_outlined),
            onPressed: () {
              final now = DateTime.now();
              setState(() {
                _displayedMonth = DateTime(now.year, now.month, 1);
                _selectedDate = DateTime(now.year, now.month, now.day);
              });
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Month navigation bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: isDark ? const Color(0xFF111827) : Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: () {
                    setState(() {
                      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month - 1, 1);
                    });
                  },
                ),
                GestureDetector(
                  onTap: () => _pickMonthYear(context),
                  child: Column(
                    children: [
                      Text(
                        DateFormat('MMMM yyyy').format(_displayedMonth),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      Text(
                        'Total: ${CurrencyFormatter.format(monthTotal, symbol: state.currencySymbol)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed: () {
                    setState(() {
                      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 1);
                    });
                  },
                ),
              ],
            ),
          ),

          // Day of week headers
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            child: Row(
              children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                  .map(
                    (d) => Expanded(
                      child: Text(
                        d,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),

          // Calendar Grid
          Container(
            color: isDark ? const Color(0xFF111827) : Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: _buildMonthGrid(dailyTotalsThisMonth, state.currencySymbol, isDark),
          ),

          const Divider(height: 1),

          // Selected date header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${AppDateUtils.formatFull(_selectedDate)} (${dayExpenses.length})',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                Text(
                  CurrencyFormatter.format(dayTotal, symbol: state.currencySymbol),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),

          // Expenses on selected date
          Expanded(
            child: dayExpenses.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.event_available_rounded,
                          size: 40,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No expenses on this date',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add For This Date'),
                          onPressed: () {
                            ExpenseFormDialog.show(
                              context,
                              expense: Expense(
                                id: '',
                                amount: 0,
                                title: '',
                                categoryId: 'food',
                                dateString: selectedDateStr,
                                paymentMethod: 'UPI',
                                createdAt: DateTime.now(),
                                updatedAt: DateTime.now(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                    itemCount: dayExpenses.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, idx) {
                      return ExpenseCard(
                        expense: dayExpenses[idx],
                        showDate: false,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthGrid(Map<int, double> dailyTotals, String symbol, bool isDark) {
    final daysInMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0).day;
    // 1 = Monday ... 7 = Sunday
    final firstWeekday = DateTime(_displayedMonth.year, _displayedMonth.month, 1).weekday;
    final leadingEmpty = firstWeekday - 1;

    final totalCells = leadingEmpty + daysInMonth;
    final totalRows = (totalCells / 7).ceil();

    return Column(
      children: List.generate(totalRows, (r) {
        return Row(
          children: List.generate(7, (c) {
            final cellIndex = r * 7 + c;
            final dayNumber = cellIndex - leadingEmpty + 1;

            if (dayNumber < 1 || dayNumber > daysInMonth) {
              return const Expanded(child: SizedBox(height: 48));
            }

            final cellDate = DateTime(_displayedMonth.year, _displayedMonth.month, dayNumber);
            final isSelected = _selectedDate.year == cellDate.year &&
                _selectedDate.month == cellDate.month &&
                _selectedDate.day == cellDate.day;

            final now = DateTime.now();
            final isToday = now.year == cellDate.year &&
                now.month == cellDate.month &&
                now.day == cellDate.day;

            final dayTotal = dailyTotals[dayNumber] ?? 0.0;
            final hasExpense = dayTotal > 0;

            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDate = cellDate;
                  });
                },
                child: Container(
                  height: 48,
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : (hasExpense
                            ? AppColors.primary.withAlpha(isDark ? 35 : 20)
                            : Colors.transparent),
                    borderRadius: BorderRadius.circular(10),
                    border: isToday && !isSelected
                        ? Border.all(color: AppColors.primary, width: 1.5)
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$dayNumber',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected || isToday ? FontWeight.w800 : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                        ),
                      ),
                      if (hasExpense)
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            CurrencyFormatter.format(dayTotal, symbol: symbol, compact: true),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white70 : AppColors.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        );
      }),
    );
  }

  Future<void> _pickMonthYear(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _displayedMonth,
      firstDate: DateTime(2015, 1, 1),
      lastDate: DateTime(2035, 12, 31),
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'SELECT MONTH & YEAR',
    );
    if (picked != null) {
      setState(() {
        _displayedMonth = DateTime(picked.year, picked.month, 1);
        _selectedDate = picked;
      });
    }
  }
}
