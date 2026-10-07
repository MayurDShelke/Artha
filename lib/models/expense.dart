class Expense {
  final String id;
  final double amount;
  final String title;
  final String categoryId;
  /// Normalized date string in 'YYYY-MM-DD' representing the exact calendar date of the expense
  final String dateString;
  final String paymentMethod;
  final String notes;
  final String location;
  final bool isRecurring;
  final DateTime createdAt;
  final DateTime updatedAt;

  Expense({
    required this.id,
    required this.amount,
    required this.title,
    required this.categoryId,
    required this.dateString,
    required this.paymentMethod,
    this.notes = '',
    this.location = '',
    this.isRecurring = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Parse the calendar date safely without timezone issues
  DateTime get date {
    final parts = dateString.split('-');
    if (parts.length == 3) {
      final y = int.tryParse(parts[0]) ?? 2026;
      final m = int.tryParse(parts[1]) ?? 1;
      final d = int.tryParse(parts[2]) ?? 1;
      return DateTime(y, m, d);
    }
    return DateTime.now();
  }

  static String formatDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'title': title,
        'categoryId': categoryId,
        'dateString': dateString,
        'paymentMethod': paymentMethod,
        'notes': notes,
        'location': location,
        'isRecurring': isRecurring,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Expense.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic val) {
      if (val is String) {
        return DateTime.tryParse(val) ?? DateTime.now();
      }
      return DateTime.now();
    }

    return Expense(
      id: json['id']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      title: json['title']?.toString() ?? '',
      categoryId: json['categoryId']?.toString() ?? 'other',
      dateString: json['dateString']?.toString() ?? formatDate(DateTime.now()),
      paymentMethod: json['paymentMethod']?.toString() ?? 'UPI',
      notes: json['notes']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      isRecurring: json['isRecurring'] as bool? ?? false,
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }

  Expense copyWith({
    String? id,
    double? amount,
    String? title,
    String? categoryId,
    String? dateString,
    String? paymentMethod,
    String? notes,
    String? location,
    bool? isRecurring,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Expense(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      title: title ?? this.title,
      categoryId: categoryId ?? this.categoryId,
      dateString: dateString ?? this.dateString,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      location: location ?? this.location,
      isRecurring: isRecurring ?? this.isRecurring,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
