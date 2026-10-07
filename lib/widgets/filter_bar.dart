import 'package:flutter/material.dart';
import '../models/filter_options.dart';
import '../theme/app_theme.dart';
import 'advanced_filter_sheet.dart';

class FilterBar extends StatelessWidget {
  final ExpenseFilter currentFilter;
  final ValueChanged<QuickFilterType> onSelectQuickFilter;
  final VoidCallback onOpenAdvancedFilters;
  final bool showCalendarPresets;

  const FilterBar({
    super.key,
    required this.currentFilter,
    required this.onSelectQuickFilter,
    required this.onOpenAdvancedFilters,
    this.showCalendarPresets = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primaryFilters = [
      QuickFilterType.oneWeek,
      QuickFilterType.oneMonth,
      QuickFilterType.threeMonths,
      QuickFilterType.sixMonths,
      QuickFilterType.twelveMonths,
      QuickFilterType.oneYear,
      QuickFilterType.twoYears,
      QuickFilterType.threeYears,
      QuickFilterType.allTime,
      QuickFilterType.custom,
    ];

    final calendarFilters = [
      QuickFilterType.thisWeek,
      QuickFilterType.lastWeek,
      QuickFilterType.thisMonth,
      QuickFilterType.lastMonth,
      QuickFilterType.thisYear,
      QuickFilterType.lastYear,
    ];

    final filtersToDisplay = showCalendarPresets ? calendarFilters : primaryFilters;

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filtersToDisplay.length + 1, // +1 for advanced filter button
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            // Advanced Filter button with badge
            final hasActive = currentFilter.hasAdvancedFiltersActive;
            return InkWell(
              onTap: onOpenAdvancedFilters,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: hasActive
                      ? AppColors.primary
                      : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: hasActive
                        ? AppColors.primary
                        : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.tune_rounded,
                      size: 16,
                      color: hasActive
                          ? Colors.white
                          : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Filter',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: hasActive
                            ? Colors.white
                            : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                      ),
                    ),
                    if (hasActive) ...[
                      const SizedBox(width: 6),
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }

          final type = filtersToDisplay[index - 1];
          final isSelected = currentFilter.quickFilter == type;

          return InkWell(
            onTap: () {
              if (type == QuickFilterType.custom) {
                // Open custom date range picker
                _pickCustomRange(context);
              } else {
                onSelectQuickFilter(type);
              }
            },
            borderRadius: BorderRadius.circular(18),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark ? Colors.white : AppColors.charcoal)
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
                          color: Colors.black.withAlpha(30),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : AppColors.softCardShadow(isDark),
              ),
              child: Center(
                child: Text(
                  type.label,
                  style: TextStyle(
                    fontSize: 13,
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
    );
  }

  Future<void> _pickCustomRange(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDateRange: currentFilter.customStartDate != null && currentFilter.customEndDate != null
          ? DateTimeRange(
              start: currentFilter.customStartDate!,
              end: currentFilter.customEndDate!,
            )
          : DateTimeRange(
              start: now.subtract(const Duration(days: 30)),
              end: now,
            ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primary,
                  onPrimary: Colors.white,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && context.mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => AdvancedFilterSheet(
          initialFilter: currentFilter.copyWith(
            quickFilter: QuickFilterType.custom,
            customStartDate: picked.start,
            customEndDate: picked.end,
          ),
        ),
      );
    }
  }
}
