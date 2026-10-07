import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/category.dart';
import '../models/expense.dart';
import '../models/filter_options.dart';
import '../services/default_data.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';

class ExpenseState extends ChangeNotifier {
  final StorageService _storageService;
  final FirestoreService _firestoreService = FirestoreService();
  final Uuid _uuid = const Uuid();

  List<Expense> _expenses = [];
  List<Category> _categories = [];
  String _currencySymbol = '₹';
  ThemeMode _themeMode = ThemeMode.system;
  bool _isLoading = true;
  bool _isSyncing = false;
  String? _userId;
  DateTime? _lastSyncTime;
  StreamSubscription<List<Expense>>? _cloudExpensesSub;

  ExpenseFilter _filter = ExpenseFilter(quickFilter: QuickFilterType.twelveMonths);

  ExpenseState(this._storageService);

  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  String? get userId => _userId;
  DateTime? get lastSyncTime => _lastSyncTime;
  List<Expense> get expenses => _expenses;
  List<Category> get categories => _categories;
  String get currencySymbol => _currencySymbol;
  ThemeMode get themeMode => _themeMode;
  ExpenseFilter get filter => _filter;

  Map<String, Category> get categoryMap {
    return {for (var c in _categories) c.id: c};
  }

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    _categories = await _storageService.loadCategories();
    _expenses = await _storageService.loadExpenses();
    _currencySymbol = _storageService.loadCurrencySymbol();

    final themeStr = _storageService.loadThemeMode();
    if (themeStr == 'dark') {
      _themeMode = ThemeMode.dark;
    } else if (themeStr == 'light') {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.system;
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Called when user logs in or logs out to sync with Firestore
  void setUserId(String? newUserId, {String? email, String? displayName}) {
    if (_userId != newUserId) {
      final oldUserId = _userId;
      _userId = newUserId;
      _cloudExpensesSub?.cancel();
      _cloudExpensesSub = null;

      if (newUserId != null) {
        _firestoreService.saveUserProfile(
          newUserId,
          email: email,
          displayName: displayName,
          currencySymbol: _currencySymbol,
        );
        syncWithCloud();
        _subscribeToCloud(newUserId);
      } else if (oldUserId != null) {
        // User logged out: clear memory data to preserve clean privacy
        _expenses = [];
        _categories = DefaultData.defaultCategories;
        _storageService.saveExpenses([]);
        _storageService.saveCategories(_categories);
        notifyListeners();
      }
    }
  }

  /// Listen to real-time updates from Firestore so any expenses added/edited
  /// from another app/device instantly appear here
  void _subscribeToCloud(String uid) {
    _cloudExpensesSub?.cancel();
    _cloudExpensesSub = _firestoreService.streamExpenses(uid).listen(
      (cloudList) {
        if (_userId != uid) return;
        // Merge with any unsynced local expenses
        final cloudMap = {for (var e in cloudList) e.id: e};
        for (var e in _expenses) {
          if (!cloudMap.containsKey(e.id)) {
            cloudMap[e.id] = e;
          }
        }
        _expenses = cloudMap.values.toList()
          ..sort((a, b) {
            final comp = b.date.compareTo(a.date);
            if (comp != 0) return comp;
            return b.createdAt.compareTo(a.createdAt);
          });
        _storageService.saveExpenses(_expenses);
        _lastSyncTime = DateTime.now();
        notifyListeners();
      },
      onError: (e) {
        debugPrint('Cloud live stream notice: $e');
      },
    );
  }

  /// Sync local state with Cloud Firestore (manual or on-login sync)
  Future<void> syncWithCloud() async {
    if (_userId == null) return;
    _isSyncing = true;
    notifyListeners();

    try {
      final cloudExpenses = await _firestoreService.fetchExpenses(_userId!);
      final cloudCategories = await _firestoreService.fetchCategories(_userId!);

      // If cloud has records, merge or sync them
      final cloudMap = {for (var e in cloudExpenses) e.id: e};

      // Upload any local expenses that don't exist in cloud
      final toUpload = _expenses.where((e) => !cloudMap.containsKey(e.id)).toList();
      if (toUpload.isNotEmpty) {
        await _firestoreService.uploadMultipleExpenses(_userId!, toUpload);
        for (var e in toUpload) {
          cloudMap[e.id] = e;
        }
      }

      _expenses = cloudMap.values.toList()
        ..sort((a, b) {
          final comp = b.date.compareTo(a.date);
          if (comp != 0) return comp;
          return b.createdAt.compareTo(a.createdAt);
        });
      await _storageService.saveExpenses(_expenses);

      if (cloudCategories.isNotEmpty) {
        _categories = cloudCategories;
        await _storageService.saveCategories(_categories);
      }

      _lastSyncTime = DateTime.now();
    } catch (e) {
      debugPrint('Cloud sync notice: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  // Filter setters
  void updateFilter(ExpenseFilter newFilter) {
    _filter = newFilter;
    notifyListeners();
  }

  void setQuickFilter(QuickFilterType type) {
    _filter = _filter.copyWith(quickFilter: type, clearCustomDates: type != QuickFilterType.custom);
    notifyListeners();
  }

  void setCustomDateRange(DateTime start, DateTime end) {
    _filter = _filter.copyWith(
      quickFilter: QuickFilterType.custom,
      customStartDate: start,
      customEndDate: end,
    );
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _filter = _filter.copyWith(searchQuery: query);
    notifyListeners();
  }

  void resetFilters() {
    _filter = ExpenseFilter(quickFilter: QuickFilterType.twelveMonths);
    notifyListeners();
  }

  // Filtered expenses based on active filter
  List<Expense> get filteredExpenses {
    final now = DateTime.now();
    final range = _filter.getDateRange(now);
    final startDate = range.start;
    final endDate = range.end;

    return _expenses.where((exp) {
      final expDate = exp.date;

      // Date Range check
      if (startDate != null && expDate.isBefore(startDate)) {
        return false;
      }
      if (endDate != null && expDate.isAfter(endDate)) {
        return false;
      }

      // Categories check
      if (_filter.selectedCategoryIds.isNotEmpty &&
          !_filter.selectedCategoryIds.contains(exp.categoryId)) {
        return false;
      }

      // Payment methods check
      if (_filter.selectedPaymentMethods.isNotEmpty &&
          !_filter.selectedPaymentMethods.contains(exp.paymentMethod)) {
        return false;
      }

      // Min/Max amount
      if (_filter.minAmount != null && exp.amount < _filter.minAmount!) {
        return false;
      }
      if (_filter.maxAmount != null && exp.amount > _filter.maxAmount!) {
        return false;
      }

      // Search Query
      if (_filter.searchQuery.trim().isNotEmpty) {
        final query = _filter.searchQuery.trim().toLowerCase();
        final titleMatch = exp.title.toLowerCase().contains(query);
        final notesMatch = exp.notes.toLowerCase().contains(query);
        final locMatch = exp.location.toLowerCase().contains(query);
        final catName = categoryMap[exp.categoryId]?.name.toLowerCase() ?? '';
        final catMatch = catName.contains(query);
        final payMatch = exp.paymentMethod.toLowerCase().contains(query);

        if (!titleMatch && !notesMatch && !locMatch && !catMatch && !payMatch) {
          return false;
        }
      }

      return true;
    }).toList()
      ..sort((a, b) {
        final comp = b.date.compareTo(a.date);
        if (comp != 0) return comp;
        return b.createdAt.compareTo(a.createdAt);
      });
  }

  // All expenses sorted by date desc
  List<Expense> get allExpensesSorted {
    return List<Expense>.from(_expenses)
      ..sort((a, b) {
        final comp = b.date.compareTo(a.date);
        if (comp != 0) return comp;
        return b.createdAt.compareTo(a.createdAt);
      });
  }

  // Statistics for filtered expenses
  double get totalSpent =>
      filteredExpenses.fold(0.0, (sum, item) => sum + item.amount);

  int get totalTransactions => filteredExpenses.length;

  double get highestExpense {
    if (filteredExpenses.isEmpty) return 0.0;
    return filteredExpenses.map((e) => e.amount).reduce(max);
  }

  double get lowestExpense {
    if (filteredExpenses.isEmpty) return 0.0;
    return filteredExpenses.map((e) => e.amount).reduce(min);
  }

  double get averageExpense {
    if (filteredExpenses.isEmpty) return 0.0;
    return totalSpent / filteredExpenses.length;
  }

  // Dashboard Intelligence (Averages over days/months/years in filter range)
  int get daysInFilterRange {
    final now = DateTime.now();
    final range = _filter.getDateRange(now);
    if (range.start == null || range.end == null) {
      if (filteredExpenses.isEmpty) return 1;
      final oldest = filteredExpenses.last.date;
      final newest = filteredExpenses.first.date;
      return max(1, newest.difference(oldest).inDays + 1);
    }
    return max(1, range.end!.difference(range.start!).inDays + 1);
  }

  double get dailyAverage => totalSpent / max(1, daysInFilterRange);
  double get weeklyAverage => dailyAverage * 7;
  double get monthlyAverage => dailyAverage * 30.4375;
  double get yearlyAverage => dailyAverage * 365.25;

  // Home Dashboard quick stats
  double get todaySpending {
    final todayStr = Expense.formatDate(DateTime.now());
    return _expenses
        .where((e) => e.dateString == todayStr)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  double get thisWeekSpending {
    final now = DateTime.now();
    final weekday = now.weekday;
    final monday = DateTime(now.year, now.month, now.day).subtract(Duration(days: weekday - 1));
    final sunday = monday.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
    return _expenses
        .where((e) => !e.date.isBefore(monday) && !e.date.isAfter(sunday))
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  double get lastWeekSpending {
    final now = DateTime.now();
    final weekday = now.weekday;
    final thisMonday = DateTime(now.year, now.month, now.day).subtract(Duration(days: weekday - 1));
    final lastMonday = thisMonday.subtract(const Duration(days: 7));
    final lastSunday = lastMonday.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
    return _expenses
        .where((e) => !e.date.isBefore(lastMonday) && !e.date.isAfter(lastSunday))
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  double get thisMonthSpending {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final nextMonth = now.month == 12 ? DateTime(now.year + 1, 1, 1) : DateTime(now.year, now.month + 1, 1);
    final end = nextMonth.subtract(const Duration(seconds: 1));
    return _expenses
        .where((e) => !e.date.isBefore(start) && !e.date.isAfter(end))
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  double get lastMonthSpending {
    final now = DateTime.now();
    final lastMoYear = now.month == 1 ? now.year - 1 : now.year;
    final lastMo = now.month == 1 ? 12 : now.month - 1;
    final start = DateTime(lastMoYear, lastMo, 1);
    final thisMoStart = DateTime(now.year, now.month, 1);
    final end = thisMoStart.subtract(const Duration(seconds: 1));
    return _expenses
        .where((e) => !e.date.isBefore(start) && !e.date.isAfter(end))
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  double get thisYearSpending {
    final now = DateTime.now();
    final start = DateTime(now.year, 1, 1);
    final end = DateTime(now.year, 12, 31, 23, 59, 59);
    return _expenses
        .where((e) => !e.date.isBefore(start) && !e.date.isAfter(end))
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  double get lastYearSpending {
    final now = DateTime.now();
    final start = DateTime(now.year - 1, 1, 1);
    final end = DateTime(now.year - 1, 12, 31, 23, 59, 59);
    return _expenses
        .where((e) => !e.date.isBefore(start) && !e.date.isAfter(end))
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  // Month vs Last Month percentage comparison
  ({double diff, double percentChange}) get monthComparison {
    final cur = thisMonthSpending;
    final last = lastMonthSpending;
    final diff = cur - last;
    if (last == 0) {
      return (diff: diff, percentChange: cur > 0 ? 100.0 : 0.0);
    }
    final pct = (diff / last) * 100.0;
    return (diff: diff, percentChange: pct);
  }

  // Week vs Last Week percentage comparison
  ({double diff, double percentChange}) get weekComparison {
    final cur = thisWeekSpending;
    final last = lastWeekSpending;
    final diff = cur - last;
    if (last == 0) {
      return (diff: diff, percentChange: cur > 0 ? 100.0 : 0.0);
    }
    final pct = (diff / last) * 100.0;
    return (diff: diff, percentChange: pct);
  }

  // Year vs Last Year percentage comparison
  ({double diff, double percentChange}) get yearComparison {
    final cur = thisYearSpending;
    final last = lastYearSpending;
    final diff = cur - last;
    if (last == 0) {
      return (diff: diff, percentChange: cur > 0 ? 100.0 : 0.0);
    }
    final pct = (diff / last) * 100.0;
    return (diff: diff, percentChange: pct);
  }

  // Category breakdown for current filter
  List<({Category category, double total, double percentage, int count})> get categoryBreakdown {
    final list = filteredExpenses;
    final total = totalSpent;
    final Map<String, ({double amount, int count})> map = {};

    for (final exp in list) {
      final cur = map[exp.categoryId] ?? (amount: 0.0, count: 0);
      map[exp.categoryId] = (amount: cur.amount + exp.amount, count: cur.count + 1);
    }

    final result = <({Category category, double total, double percentage, int count})>[];
    map.forEach((catId, data) {
      final cat = categoryMap[catId] ??
          Category(
            id: catId,
            name: 'Other',
            iconCodePoint: Icons.category.codePoint,
            colorValue: Colors.grey.toARGB32(),
            createdAt: DateTime.now(),
          );
      final pct = total > 0 ? (data.amount / total) * 100 : 0.0;
      result.add((category: cat, total: data.amount, percentage: pct, count: data.count));
    });

    result.sort((a, b) => b.total.compareTo(a.total));
    return result;
  }

  // Multi-Year Overview breakdown
  Map<int, double> get yearlySpendingOverview {
    final Map<int, double> map = {};
    for (final exp in _expenses) {
      final y = exp.date.year;
      map[y] = (map[y] ?? 0.0) + exp.amount;
    }
    return map;
  }

  // Monthly breakdown for a given year
  List<double> getMonthlySpendingForYear(int year) {
    final months = List<double>.filled(12, 0.0);
    for (final exp in _expenses) {
      if (exp.date.year == year) {
        final mIdx = exp.date.month - 1;
        if (mIdx >= 0 && mIdx < 12) {
          months[mIdx] += exp.amount;
        }
      }
    }
    return months;
  }

  // Grouped by date map (for Expenses list and Calendar)
  Map<String, List<Expense>> get groupedByDateExpenses {
    final Map<String, List<Expense>> map = {};
    for (final exp in filteredExpenses) {
      map.putIfAbsent(exp.dateString, () => []).add(exp);
    }
    return map;
  }

  // CRUD Expenses
  Future<void> addExpense({
    required double amount,
    required String title,
    required String categoryId,
    required String dateString,
    required String paymentMethod,
    String notes = '',
    String location = '',
    bool isRecurring = false,
  }) async {
    final now = DateTime.now();
    final expense = Expense(
      id: _uuid.v4(),
      amount: amount,
      title: title,
      categoryId: categoryId,
      dateString: dateString,
      paymentMethod: paymentMethod,
      notes: notes,
      location: location,
      isRecurring: isRecurring,
      createdAt: now,
      updatedAt: now,
    );

    _expenses.insert(0, expense);
    await _storageService.saveExpenses(_expenses);

    // Save to Firestore if user is authenticated
    if (_userId != null) {
      _firestoreService.saveExpense(_userId!, expense);
    }

    notifyListeners();
  }

  Future<void> updateExpense(Expense updated) async {
    final index = _expenses.indexWhere((e) => e.id == updated.id);
    if (index != -1) {
      _expenses[index] = updated.copyWith(updatedAt: DateTime.now());
      await _storageService.saveExpenses(_expenses);

      // Update in Firestore if user is authenticated
      if (_userId != null) {
        _firestoreService.saveExpense(_userId!, _expenses[index]);
      }

      notifyListeners();
    }
  }

  Future<void> deleteExpense(String id) async {
    _expenses.removeWhere((e) => e.id == id);
    await _storageService.saveExpenses(_expenses);

    // Delete from Firestore if user is authenticated
    if (_userId != null) {
      _firestoreService.deleteExpense(_userId!, id);
    }

    notifyListeners();
  }

  // CRUD Categories
  Future<void> addCategory({
    required String name,
    required int iconCodePoint,
    String? iconFontFamily,
    String? iconFontPackage,
    required int colorValue,
  }) async {
    final category = Category(
      id: _uuid.v4(),
      name: name,
      iconCodePoint: iconCodePoint,
      iconFontFamily: iconFontFamily,
      iconFontPackage: iconFontPackage,
      colorValue: colorValue,
      createdAt: DateTime.now(),
      isDefault: false,
    );

    _categories.add(category);
    await _storageService.saveCategories(_categories);

    if (_userId != null) {
      _firestoreService.saveCategory(_userId!, category);
    }

    notifyListeners();
  }

  Future<void> updateCategory(Category category) async {
    final index = _categories.indexWhere((c) => c.id == category.id);
    if (index != -1) {
      _categories[index] = category;
      await _storageService.saveCategories(_categories);

      if (_userId != null) {
        _firestoreService.saveCategory(_userId!, category);
      }

      notifyListeners();
    }
  }

  /// Delete category safely: if reassignToCategoryId is given, reassigns affected expenses
  Future<bool> deleteCategory(String id, {String? reassignToCategoryId}) async {
    final hasExpenses = _expenses.any((e) => e.categoryId == id);
    if (hasExpenses && reassignToCategoryId == null) {
      return false; // Requires reassignment target
    }

    if (hasExpenses && reassignToCategoryId != null) {
      for (int i = 0; i < _expenses.length; i++) {
        if (_expenses[i].categoryId == id) {
          _expenses[i] = _expenses[i].copyWith(categoryId: reassignToCategoryId);
        }
      }
      await _storageService.saveExpenses(_expenses);
    }

    _categories.removeWhere((c) => c.id == id);
    await _storageService.saveCategories(_categories);

    if (_userId != null) {
      _firestoreService.deleteCategory(_userId!, id);
    }

    notifyListeners();
    return true;
  }

  // Settings
  Future<void> setCurrencySymbol(String symbol) async {
    _currencySymbol = symbol;
    await _storageService.saveCurrencySymbol(symbol);
    if (_userId != null) {
      _firestoreService.saveUserProfile(_userId!, currencySymbol: symbol);
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final str = mode == ThemeMode.dark
        ? 'dark'
        : mode == ThemeMode.light
            ? 'light'
            : 'system';
    await _storageService.saveThemeMode(str);
    notifyListeners();
  }

  // Reset & Backup

  Future<void> clearAllData() async {
    if (_userId != null) {
      await _firestoreService.clearUserData(_userId!);
    }
    await _storageService.clearAllData();
    _expenses = [];
    _categories = DefaultData.defaultCategories;
    await _storageService.saveCategories(_categories);
    notifyListeners();
  }

  String exportBackupJson() {
    return _storageService.exportBackupJson(_expenses, _categories);
  }

  Future<bool> importBackupJson(String jsonString) async {
    final res = _storageService.importBackupJson(jsonString);
    if (res != null) {
      _expenses = res.expenses;
      _categories = res.categories;
      await _storageService.saveExpenses(_expenses);
      await _storageService.saveCategories(_categories);
      notifyListeners();
      return true;
    }
    return false;
  }

  String exportCsv() {
    return _storageService.exportToCsv(_filteredOrAllExpenses, categoryMap, _currencySymbol);
  }

  List<Expense> get _filteredOrAllExpenses => filteredExpenses;

  @override
  void dispose() {
    _cloudExpensesSub?.cancel();
    super.dispose();
  }
}
