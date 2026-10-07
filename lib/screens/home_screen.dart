import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../state/auth_scope.dart';
import '../state/expense_scope.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/advanced_filter_sheet.dart';
import '../widgets/category_detail_sheet.dart';
import '../widgets/expense_card.dart';
import '../widgets/expense_form_dialog.dart';
import '../widgets/filter_bar.dart';
import '../widgets/spending_chart.dart';
import '../widgets/spending_dial_controller.dart';
import '../widgets/stat_card.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onNavigateToExpenses;

  const HomeScreen({super.key, required this.onNavigateToExpenses});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _activeSegmentIdx = 0; // 0: Overview, 1: Controller, 2: Categories

  @override
  Widget build(BuildContext context) {
    final state = ExpenseScope.of(context);
    final auth = AuthScope.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final topCategories = state.categoryBreakdown.take(5).toList();
    final recentExpenses = state.filteredExpenses.take(6).toList();
    final todayFormatted = DateFormat('EEE, MMMM d').format(DateTime.now());

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            // 1. Top Greeting Header (Modeled directly after "Hello, Rocky" in reference)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello, ${auth.displayName}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.6,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          todayFormatted,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                        ),
                      ],
                    ),
                    // Notification / Quick Action Bell circle from reference
                    GestureDetector(
                      onTap: () => ExpenseFormDialog.show(context),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                            width: 0.8,
                          ),
                          boxShadow: AppColors.softCardShadow(isDark),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(
                              Icons.notifications_none_rounded,
                              size: 22,
                              color: isDark ? Colors.white : AppColors.charcoal,
                            ),
                            Positioned(
                              top: 11,
                              right: 12,
                              child: Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: AppColors.cyanAccent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2. Weather-Style Hero Dark Card (Matching 18° C Cloudy card from reference)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AppColors.charcoal, // Deep matte charcoal from reference
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(60),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Big headline amount + glowing weather/wallet icon
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  CurrencyFormatter.format(state.totalSpent, symbol: state.currencySymbol),
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -1,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Total Spent • ${state.filter.quickFilter.title}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                          // Glowing weather/cloud badge from reference
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(30),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Stack(
                              alignment: Alignment.center,
                              children: [
                                Icon(Icons.cloud_rounded, color: Colors.white, size: 26),
                                Positioned(
                                  top: 10,
                                  right: 9,
                                  child: Icon(Icons.nightlight_round, color: AppColors.cyanLight, size: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Divider inside card
                      Container(
                        height: 0.8,
                        color: Colors.white.withAlpha(30),
                      ),

                      const SizedBox(height: 16),

                      // Bottom 3 Sub-Metrics (matching Indoor temp, Humidity, Air Quality)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSubMetric(
                            label: 'Today',
                            value: CurrencyFormatter.format(state.todaySpending, symbol: state.currencySymbol),
                          ),
                          _buildSubMetric(
                            label: 'This Week',
                            value: CurrencyFormatter.format(state.thisWeekSpending, symbol: state.currencySymbol),
                          ),
                          _buildSubMetric(
                            label: 'Daily Avg',
                            value: CurrencyFormatter.format(state.dailyAverage, symbol: state.currencySymbol, compact: true),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 14)),

            // 3. Pill Segmented Switcher (matching Room | Devices in reference)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E2026) : AppColors.lightPillBg,
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: Row(
                    children: [
                      _buildPillTab(0, 'Overview', isDark),
                      _buildPillTab(1, 'Controller', isDark),
                      _buildPillTab(2, 'Categories', isDark),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 10)),

            // Tab 1: Overview View
            if (_activeSegmentIdx == 0) ...[
              // 4. 2x2 Smart Cards Grid (Smart Light, Smart AC, Smart TV, Smart Speaker)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Column(
                    children: [
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Card 1: Featured Dark Card
                            Expanded(
                              child: StatCard(
                                title: 'This Month',
                                amount: CurrencyFormatter.format(state.thisMonthSpending, symbol: state.currencySymbol),
                                subtitle: '${state.totalTransactions} Transactions',
                                icon: Icons.calendar_today_rounded,
                                isHighlight: true,
                              ),
                            ),
                            const SizedBox(width: 14),
                            // Card 2: Highest Expense (Clean White Card)
                            Expanded(
                              child: StatCard(
                                title: 'Peak Expense',
                                amount: CurrencyFormatter.format(state.highestExpense, symbol: state.currencySymbol, compact: true),
                                subtitle: state.highestExpense > 0 ? 'Single highest' : 'None recorded',
                                icon: Icons.trending_up_rounded,
                                isHighlight: false,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Card 3: Top Category (Clean White Card)
                            Expanded(
                              child: StatCard(
                                title: topCategories.isNotEmpty ? topCategories.first.category.name : 'Top Category',
                                amount: topCategories.isNotEmpty
                                    ? CurrencyFormatter.format(topCategories.first.total, symbol: state.currencySymbol, compact: true)
                                    : '₹0',
                                subtitle: topCategories.isNotEmpty ? '${topCategories.first.count} items' : 'No data',
                                icon: Icons.category_rounded,
                                isHighlight: false,
                              ),
                            ),
                            const SizedBox(width: 14),
                            // Card 4: Daily Average (Clean White Card)
                            Expanded(
                              child: StatCard(
                                title: 'Daily Pace',
                                amount: CurrencyFormatter.format(state.dailyAverage, symbol: state.currencySymbol, compact: true),
                                subtitle: 'Average per day',
                                icon: Icons.speed_rounded,
                                isHighlight: false,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 14)),

              // Rolling Filter Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
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

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // Spending Chart Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SpendingChart(
                    expenses: state.filteredExpenses,
                    currencySymbol: state.currencySymbol,
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // Recent Transactions Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Transactions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      TextButton(
                        onPressed: widget.onNavigateToExpenses,
                        child: const Text('See All', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.cyanAccent)),
                      ),
                    ],
                  ),
                ),
              ),

              // Recent Transactions List
              if (recentExpenses.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.receipt_long_outlined, size: 44, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                          const SizedBox(height: 10),
                          Text(
                            'No expenses recorded yet',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: ExpenseCard(expense: recentExpenses[index]),
                        );
                      },
                      childCount: recentExpenses.length,
                    ),
                  ),
                ),
            ],

            // Tab 2: Controller View (Matching the right screen in reference)
            if (_activeSegmentIdx == 1) ...[
              const SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                sliver: SliverToBoxAdapter(
                  child: SpendingDialController(),
                ),
              ),
            ],

            // Tab 3: Categories View
            if (_activeSegmentIdx == 2) ...[
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Category Breakdown',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (topCategories.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(child: Text('No category data recorded yet.')),
                        )
                      else
                        ...topCategories.map((item) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              onTap: () => CategoryDetailSheet.show(context, item.category),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkCard : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, width: 0.8),
                                  boxShadow: AppColors.softCardShadow(isDark),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: item.category.color.withAlpha(45),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(item.category.iconData, color: item.category.color, size: 20),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.category.name,
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w700,
                                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                                ),
                                              ),
                                              Text(
                                                '${item.count} expenses • ${item.percentage.toStringAsFixed(1)}%',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          CurrencyFormatter.format(item.total, symbol: state.currencySymbol),
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: LinearProgressIndicator(
                                        value: (item.percentage / 100.0).clamp(0.0, 1.0),
                                        backgroundColor: isDark ? const Color(0xFF242730) : const Color(0xFFE5E7EB),
                                        valueColor: AlwaysStoppedAnimation(item.category.color),
                                        minHeight: 6,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
            ],

            // Padding at the bottom to accommodate floating pill nav bar
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubMetric({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: Colors.white60,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildPillTab(int index, String label, bool isDark) {
    final isSelected = _activeSegmentIdx == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _activeSegmentIdx = index;
          });
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? Colors.white : AppColors.charcoal)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withAlpha(30),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? (isDark ? AppColors.charcoal : Colors.white)
                    : (isDark ? AppColors.darkTextMuted : AppColors.lightTextSecondary),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
