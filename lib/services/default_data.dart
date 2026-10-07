import 'package:flutter/material.dart';
import '../models/category.dart';

class DefaultData {
  static List<Category> get defaultCategories {
    final now = DateTime.now();
    return [
      Category(
        id: 'food',
        name: 'Food',
        iconCodePoint: Icons.restaurant.codePoint,
        colorValue: const Color(0xFFF97316).toARGB32(), // Warm orange
        createdAt: now,
        isDefault: true,
      ),
      Category(
        id: 'groceries',
        name: 'Groceries',
        iconCodePoint: Icons.shopping_cart.codePoint,
        colorValue: const Color(0xFF10B981).toARGB32(), // Emerald
        createdAt: now,
        isDefault: true,
      ),
      Category(
        id: 'fuel',
        name: 'Fuel',
        iconCodePoint: Icons.local_gas_station.codePoint,
        colorValue: const Color(0xFFEF4444).toARGB32(), // Red
        createdAt: now,
        isDefault: true,
      ),
      Category(
        id: 'transport',
        name: 'Transport',
        iconCodePoint: Icons.directions_car.codePoint,
        colorValue: const Color(0xFF3B82F6).toARGB32(), // Blue
        createdAt: now,
        isDefault: true,
      ),
      Category(
        id: 'shopping',
        name: 'Shopping',
        iconCodePoint: Icons.shopping_bag.codePoint,
        colorValue: const Color(0xFFEC4899).toARGB32(), // Pink
        createdAt: now,
        isDefault: true,
      ),
      Category(
        id: 'bills',
        name: 'Bills',
        iconCodePoint: Icons.lightbulb.codePoint,
        colorValue: const Color(0xFFEAB308).toARGB32(), // Amber/Yellow
        createdAt: now,
        isDefault: true,
      ),
      Category(
        id: 'rent',
        name: 'Rent',
        iconCodePoint: Icons.home.codePoint,
        colorValue: const Color(0xFF8B5CF6).toARGB32(), // Purple
        createdAt: now,
        isDefault: true,
      ),
      Category(
        id: 'entertainment',
        name: 'Entertainment',
        iconCodePoint: Icons.sports_esports.codePoint,
        colorValue: const Color(0xFF06B6D4).toARGB32(), // Cyan
        createdAt: now,
        isDefault: true,
      ),
      Category(
        id: 'health',
        name: 'Health',
        iconCodePoint: Icons.medical_services.codePoint,
        colorValue: const Color(0xFF14B8A6).toARGB32(), // Teal
        createdAt: now,
        isDefault: true,
      ),
      Category(
        id: 'education',
        name: 'Education',
        iconCodePoint: Icons.school.codePoint,
        colorValue: const Color(0xFF6366F1).toARGB32(), // Indigo
        createdAt: now,
        isDefault: true,
      ),
      Category(
        id: 'travel',
        name: 'Travel',
        iconCodePoint: Icons.flight.codePoint,
        colorValue: const Color(0xFF0284C7).toARGB32(), // Sky
        createdAt: now,
        isDefault: true,
      ),
      Category(
        id: 'subscriptions',
        name: 'Subscriptions',
        iconCodePoint: Icons.subscriptions.codePoint,
        colorValue: const Color(0xFFA855F7).toARGB32(), // Violet
        createdAt: now,
        isDefault: true,
      ),
      Category(
        id: 'other',
        name: 'Other',
        iconCodePoint: Icons.category.codePoint,
        colorValue: const Color(0xFF64748B).toARGB32(), // Slate
        createdAt: now,
        isDefault: true,
      ),
    ];
  }

  static const List<String> paymentMethods = [
    'UPI',
    'Credit Card',
    'Debit Card',
    'Cash',
    'Bank Transfer',
    'Other',
  ];
}
