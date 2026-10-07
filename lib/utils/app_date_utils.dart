import 'package:intl/intl.dart';

class AppDateUtils {
  static final DateFormat _fullFormatter = DateFormat('MMMM d, yyyy');
  static final DateFormat _shortFormatter = DateFormat('dd MMM yyyy');
  static final DateFormat _monthYearFormatter = DateFormat('MMMM yyyy');

  /// Formats date for grouped expense headers: "Today", "Yesterday", or "October 7, 2026"
  static String formatGroupHeader(DateTime date, {DateTime? referenceToday}) {
    final now = referenceToday ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final compDate = DateTime(date.year, date.month, date.day);

    final diffDays = today.difference(compDate).inDays;
    if (diffDays == 0) return 'Today';
    if (diffDays == 1) return 'Yesterday';
    if (diffDays == -1) return 'Tomorrow';

    return _fullFormatter.format(date);
  }

  /// Compact date for lists e.g., "Today • Food" or "15 Aug 2025 • Fuel"
  static String formatListDate(DateTime date, {DateTime? referenceToday}) {
    final now = referenceToday ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final compDate = DateTime(date.year, date.month, date.day);

    final diffDays = today.difference(compDate).inDays;
    if (diffDays == 0) return 'Today';
    if (diffDays == 1) return 'Yesterday';
    return _shortFormatter.format(date);
  }

  static String formatMonthYear(DateTime date) {
    return _monthYearFormatter.format(date);
  }

  static String formatFull(DateTime date) {
    return _fullFormatter.format(date);
  }
}
