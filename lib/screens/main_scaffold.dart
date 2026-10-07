import 'dart:ui';
import 'package:flutter/material.dart';
import '../state/auth_scope.dart';
import '../state/expense_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/expense_form_dialog.dart';
import 'calendar_screen.dart';
import 'categories_screen.dart';
import 'expenses_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'reports_screen.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = AuthScope.of(context);
    final expense = ExpenseScope.of(context);
    if (auth.user?.uid != expense.userId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        expense.setUserId(
          auth.user?.uid,
          email: auth.user?.email,
          displayName: auth.user?.displayName,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ExpenseScope.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (state.isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(isDark ? 40 : 25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary, size: 40),
              ),
              const SizedBox(height: 18),
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 12),
              const Text(
                'Loading your expense journal...',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    final pages = [
      HomeScreen(
        onNavigateToExpenses: () {
          setState(() {
            _currentIndex = 1;
          });
        },
      ),
      const ExpensesScreen(),
      const ReportsScreen(),
      const CalendarScreen(),
      const ProfileScreen(),
      const CategoriesScreen(),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 840;

        if (isDesktop) {
          // Desktop & Tablet: Modern Sidebar Layout
          return Scaffold(
            body: Row(
              children: [
                // Sidebar
                Container(
                  width: 240,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : Colors.white,
                    border: Border(
                      right: BorderSide(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Sidebar Header / Brand
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.account_balance_wallet_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'IMREXPENSE',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.5,
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                  ),
                                ),
                                Text(
                                  'Expense Tracker',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Add Expense Button in sidebar
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            icon: const Icon(Icons.add_rounded, size: 20),
                            label: const Text('Add Expense', style: TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: () => ExpenseFormDialog.show(context),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Nav items
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          children: [
                            _buildSidebarTile(0, 'Dashboard', Icons.dashboard_outlined, Icons.dashboard_rounded, isDark),
                            _buildSidebarTile(1, 'Expenses', Icons.receipt_long_outlined, Icons.receipt_long_rounded, isDark),
                            _buildSidebarTile(2, 'Reports', Icons.analytics_outlined, Icons.analytics_rounded, isDark),
                            _buildSidebarTile(3, 'Calendar', Icons.calendar_month_outlined, Icons.calendar_month_rounded, isDark),
                            _buildSidebarTile(4, 'Profile', Icons.person_outline_rounded, Icons.person_rounded, isDark),
                            _buildSidebarTile(5, 'Categories', Icons.category_outlined, Icons.category_rounded, isDark),
                          ],
                        ),
                      ),

                      // Sidebar Footer
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Cloud Synced • Safe Historical',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Main body area
                Expanded(
                  child: IndexedStack(
                    index: _currentIndex,
                    children: pages,
                  ),
                ),
              ],
            ),
          );
        }

        // Mobile: Floating iPhone Glass Dock Navigation Bar
        return Scaffold(
          extendBody: true,
          body: IndexedStack(
            index: _currentIndex > 4 ? 4 : _currentIndex,
            children: pages,
          ),
          bottomNavigationBar: SafeArea(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(34),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(isDark ? 95 : 55),
                    blurRadius: 28,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(34),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    height: 64,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF161820).withAlpha(205)
                          : const Color(0xFF181A22).withAlpha(225),
                      borderRadius: BorderRadius.circular(34),
                      border: Border.all(
                        color: Colors.white.withAlpha(28),
                        width: 1.1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildNavPill(0, 'Home', Icons.home_rounded, Icons.home_outlined),
                        _buildNavPill(1, 'Expenses', Icons.receipt_long_rounded, Icons.receipt_long_outlined),
                        _buildNavPill(2, 'Reports', Icons.bar_chart_rounded, Icons.bar_chart_outlined),
                        _buildNavPill(3, 'Calendar', Icons.calendar_month_rounded, Icons.calendar_month_outlined),
                        _buildNavPill(4, 'Profile', Icons.person_rounded, Icons.person_outline_rounded),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            heroTag: 'main_fab',
            elevation: 6,
            backgroundColor: Colors.transparent,
            shape: const CircleBorder(),
            onPressed: () => ExpenseFormDialog.show(context),
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [
                    AppColors.cyanAccent,
                    AppColors.primary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.cyanAccent.withAlpha(90),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavPill(int index, String label, IconData activeIcon, IconData inactiveIcon) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 14 : 10,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF1F3F5) : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withAlpha(25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              size: 20,
              color: isSelected ? AppColors.charcoal : Colors.white.withAlpha(165),
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.charcoal,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  fontStyle: FontStyle.italic,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarTile(int index, String label, IconData icon, IconData activeIcon, bool isDark) {
    final isSelected = _currentIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: InkWell(
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withAlpha(isDark ? 45 : 25)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.primary.withAlpha(80) : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                size: 20,
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? (isDark ? AppColors.primaryLight : AppColors.primaryDark)
                      : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
