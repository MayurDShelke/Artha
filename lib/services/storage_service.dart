import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category.dart';
import '../models/expense.dart';
import 'default_data.dart';

class StorageService {
  static const String _keyExpenses = 'imr_expenses_clean_v2';
  static const String _keyCategories = 'imr_categories_v1';
  static const String _keyCurrency = 'imr_currency_symbol';
  static const String _keyThemeMode = 'imr_theme_mode';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    // One-time purge of any old sample/dummy data keys from previous runs
    if (_prefs.containsKey('imr_expenses_v1')) {
      await _prefs.remove('imr_expenses_v1');
    }
    if (_prefs.containsKey('imr_has_initialized_sample_v1')) {
      await _prefs.remove('imr_has_initialized_sample_v1');
    }
  }

  // Categories
  Future<List<Category>> loadCategories() async {
    final raw = _prefs.getString(_keyCategories);
    if (raw == null || raw.isEmpty) {
      final defaults = DefaultData.defaultCategories;
      await saveCategories(defaults);
      return defaults;
    }

    try {
      final List<dynamic> list = jsonDecode(raw);
      return list.map((e) => Category.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return DefaultData.defaultCategories;
    }
  }

  Future<void> saveCategories(List<Category> categories) async {
    final list = categories.map((c) => c.toJson()).toList();
    await _prefs.setString(_keyCategories, jsonEncode(list));
  }

  // Expenses - Clean, strictly user-recorded only
  Future<List<Expense>> loadExpenses() async {
    final raw = _prefs.getString(_keyExpenses);
    if (raw == null || raw.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> list = jsonDecode(raw);
      return list.map((e) => Expense.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveExpenses(List<Expense> expenses) async {
    final list = expenses.map((e) => e.toJson()).toList();
    await _prefs.setString(_keyExpenses, jsonEncode(list));
  }

  // Currency
  String loadCurrencySymbol() {
    return _prefs.getString(_keyCurrency) ?? '₹';
  }

  Future<void> saveCurrencySymbol(String symbol) async {
    await _prefs.setString(_keyCurrency, symbol);
  }

  // Theme Mode
  String loadThemeMode() {
    return _prefs.getString(_keyThemeMode) ?? 'system';
  }

  Future<void> saveThemeMode(String mode) async {
    await _prefs.setString(_keyThemeMode, mode);
  }

  // Reset / Clear Data
  Future<void> clearAllData() async {
    await _prefs.remove(_keyExpenses);
    await _prefs.remove(_keyCategories);
  }

  // Export JSON Backup
  String exportBackupJson(List<Expense> expenses, List<Category> categories) {
    final data = {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'categories': categories.map((c) => c.toJson()).toList(),
      'expenses': expenses.map((e) => e.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  // Import JSON Backup
  ({List<Expense> expenses, List<Category> categories})? importBackupJson(String jsonString) {
    try {
      final map = jsonDecode(jsonString) as Map<String, dynamic>;
      final catList = (map['categories'] as List<dynamic>?)
              ?.map((e) => Category.fromJson(e as Map<String, dynamic>))
              .toList() ??
          DefaultData.defaultCategories;
      final expList = (map['expenses'] as List<dynamic>?)
              ?.map((e) => Expense.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      return (expenses: expList, categories: catList);
    } catch (_) {
      return null;
    }
  }

  // Export CSV
  String exportToCsv(List<Expense> expenses, Map<String, Category> categoryMap, String currencySymbol) {
    final buffer = StringBuffer();
    // CSV Header
    buffer.writeln('Date,Expense Name,Category,Amount ($currencySymbol),Payment Method,Location,Notes');

    for (final exp in expenses) {
      final catName = categoryMap[exp.categoryId]?.name ?? 'Other';
      final cleanTitle = exp.title.replaceAll('"', '""');
      final cleanNotes = exp.notes.replaceAll('"', '""');
      final cleanLoc = exp.location.replaceAll('"', '""');

      buffer.writeln(
        '"${exp.dateString}","$cleanTitle","$catName",${exp.amount.toStringAsFixed(2)},"${exp.paymentMethod}","$cleanLoc","$cleanNotes"',
      );
    }

    return buffer.toString();
  }
}
