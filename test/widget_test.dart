import 'package:flutter_test/flutter_test.dart';
import 'package:imrexpense/models/expense.dart';
import 'package:imrexpense/models/filter_options.dart';
import 'package:imrexpense/utils/formatters.dart';

void main() {
  group('Expense Tracker Core Tests', () {
    test('Historical Date is preserved without timezone shift', () {
      final exp = Expense(
        id: 'test-1',
        amount: 1200.0,
        title: 'Independence Day Petrol',
        categoryId: 'fuel',
        dateString: '2025-08-15',
        paymentMethod: 'UPI',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(exp.dateString, equals('2025-08-15'));
      expect(exp.date.year, equals(2025));
      expect(exp.date.month, equals(8));
      expect(exp.date.day, equals(15));
    });

    test('Rolling 1 Year filter calculates exactly 365 days rolling window', () {
      final refDate = DateTime(2026, 10, 7);
      final filter = ExpenseFilter(quickFilter: QuickFilterType.oneYear);
      final range = filter.getDateRange(refDate);

      expect(range.start, isNotNull);
      expect(range.end, isNotNull);

      // In rolling 1 year (365 days), start should be 2025-10-08
      expect(range.start!.year, equals(2025));
      expect(range.start!.month, equals(10));
      expect(range.end!.year, equals(2026));
      expect(range.end!.month, equals(10));
      expect(range.end!.day, equals(7));
    });

    test('Rolling 3 Years filter calculates 1095 days rolling window', () {
      final refDate = DateTime(2026, 10, 7);
      final filter = ExpenseFilter(quickFilter: QuickFilterType.threeYears);
      final range = filter.getDateRange(refDate);

      expect(range.start, isNotNull);
      expect(range.end, isNotNull);
      expect(range.start!.year, equals(2023));
    });

    test('Currency Formatter handles Indian Rupee symbol and compact values', () {
      expect(CurrencyFormatter.format(500, symbol: '₹'), contains('500'));
      expect(CurrencyFormatter.format(184520, symbol: '₹', compact: true), equals('₹1.8 L'));
      expect(CurrencyFormatter.format(25000, symbol: '₹', compact: true), equals('₹25.0k'));
    });
  });
}
