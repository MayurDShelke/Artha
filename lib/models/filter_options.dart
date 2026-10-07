enum QuickFilterType {
  oneWeek('1W', 'Last 7 Days', 7),
  oneMonth('1M', 'Last 30 Days', 30),
  threeMonths('3M', 'Last 3 Months', 90),
  sixMonths('6M', 'Last 6 Months', 180),
  twelveMonths('12M', 'Last 12 Months', 365),
  oneYear('1Y', 'Last 1 Year', 365),
  twoYears('2Y', 'Last 2 Years', 730),
  threeYears('3Y', 'Last 3 Years', 1095),
  allTime('All', 'All Time', null),
  thisWeek('This Wk', 'This Week', null),
  lastWeek('Last Wk', 'Last Week', null),
  thisMonth('This Mo', 'This Month', null),
  lastMonth('Last Mo', 'Last Month', null),
  thisYear('This Yr', 'This Year', null),
  lastYear('Last Yr', 'Last Year', null),
  custom('Custom', 'Custom Range', null);

  final String label;
  final String title;
  final int? rollingDays;
  const QuickFilterType(this.label, this.title, this.rollingDays);
}

class ExpenseFilter {
  final QuickFilterType quickFilter;
  final DateTime? customStartDate;
  final DateTime? customEndDate;
  final Set<String> selectedCategoryIds;
  final Set<String> selectedPaymentMethods;
  final double? minAmount;
  final double? maxAmount;
  final String searchQuery;

  ExpenseFilter({
    this.quickFilter = QuickFilterType.twelveMonths,
    this.customStartDate,
    this.customEndDate,
    this.selectedCategoryIds = const {},
    this.selectedPaymentMethods = const {},
    this.minAmount,
    this.maxAmount,
    this.searchQuery = '',
  });

  ExpenseFilter copyWith({
    QuickFilterType? quickFilter,
    DateTime? customStartDate,
    DateTime? customEndDate,
    Set<String>? selectedCategoryIds,
    Set<String>? selectedPaymentMethods,
    double? minAmount,
    double? maxAmount,
    String? searchQuery,
    bool clearCustomDates = false,
  }) {
    return ExpenseFilter(
      quickFilter: quickFilter ?? this.quickFilter,
      customStartDate: clearCustomDates ? null : (customStartDate ?? this.customStartDate),
      customEndDate: clearCustomDates ? null : (customEndDate ?? this.customEndDate),
      selectedCategoryIds: selectedCategoryIds ?? this.selectedCategoryIds,
      selectedPaymentMethods: selectedPaymentMethods ?? this.selectedPaymentMethods,
      minAmount: minAmount ?? this.minAmount,
      maxAmount: maxAmount ?? this.maxAmount,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  /// Calculates the inclusive [startDate, endDate] for the filter
  ({DateTime? start, DateTime? end}) getDateRange(DateTime referenceDate) {
    final now = DateTime(referenceDate.year, referenceDate.month, referenceDate.day, 23, 59, 59);

    if (quickFilter == QuickFilterType.custom) {
      DateTime? s = customStartDate != null
          ? DateTime(customStartDate!.year, customStartDate!.month, customStartDate!.day, 0, 0, 0)
          : null;
      DateTime? e = customEndDate != null
          ? DateTime(customEndDate!.year, customEndDate!.month, customEndDate!.day, 23, 59, 59)
          : null;
      return (start: s, end: e);
    }

    if (quickFilter == QuickFilterType.allTime) {
      return (start: null, end: null);
    }

    if (quickFilter.rollingDays != null) {
      final days = quickFilter.rollingDays!;
      // Rolling date range ending today
      final s = DateTime(now.year, now.month, now.day).subtract(Duration(days: days - 1));
      return (start: s, end: now);
    }

    switch (quickFilter) {
      case QuickFilterType.thisWeek:
        // Week starting Monday
        final weekday = referenceDate.weekday; // 1 = Monday
        final s = DateTime(referenceDate.year, referenceDate.month, referenceDate.day)
            .subtract(Duration(days: weekday - 1));
        final e = s.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
        return (start: s, end: e);

      case QuickFilterType.lastWeek:
        final weekday = referenceDate.weekday;
        final thisMonday = DateTime(referenceDate.year, referenceDate.month, referenceDate.day)
            .subtract(Duration(days: weekday - 1));
        final lastMonday = thisMonday.subtract(const Duration(days: 7));
        final lastSunday = lastMonday.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
        return (start: lastMonday, end: lastSunday);

      case QuickFilterType.thisMonth:
        final s = DateTime(referenceDate.year, referenceDate.month, 1);
        final nextMo = referenceDate.month == 12
            ? DateTime(referenceDate.year + 1, 1, 1)
            : DateTime(referenceDate.year, referenceDate.month + 1, 1);
        final e = nextMo.subtract(const Duration(seconds: 1));
        return (start: s, end: e);

      case QuickFilterType.lastMonth:
        final lastMoYear = referenceDate.month == 1 ? referenceDate.year - 1 : referenceDate.year;
        final lastMo = referenceDate.month == 1 ? 12 : referenceDate.month - 1;
        final s = DateTime(lastMoYear, lastMo, 1);
        final thisMoStart = DateTime(referenceDate.year, referenceDate.month, 1);
        final e = thisMoStart.subtract(const Duration(seconds: 1));
        return (start: s, end: e);

      case QuickFilterType.thisYear:
        final s = DateTime(referenceDate.year, 1, 1);
        final e = DateTime(referenceDate.year, 12, 31, 23, 59, 59);
        return (start: s, end: e);

      case QuickFilterType.lastYear:
        final s = DateTime(referenceDate.year - 1, 1, 1);
        final e = DateTime(referenceDate.year - 1, 12, 31, 23, 59, 59);
        return (start: s, end: e);

      default:
        return (start: null, end: null);
    }
  }

  bool get hasAdvancedFiltersActive =>
      selectedCategoryIds.isNotEmpty ||
      selectedPaymentMethods.isNotEmpty ||
      minAmount != null ||
      maxAmount != null;
}
