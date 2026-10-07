// ignore_for_file: non_const_argument_for_const_parameter
import 'package:flutter/material.dart';

class Category {
  final String id;
  final String name;
  final int iconCodePoint;
  final String? iconFontFamily;
  final String? iconFontPackage;
  final int colorValue;
  final DateTime createdAt;
  final bool isDefault;

  Category({
    required this.id,
    required this.name,
    required this.iconCodePoint,
    this.iconFontFamily,
    this.iconFontPackage,
    required this.colorValue,
    required this.createdAt,
    this.isDefault = false,
  });

  static final Map<int, IconData> _iconMap = {
    Icons.restaurant.codePoint: Icons.restaurant,
    Icons.shopping_cart.codePoint: Icons.shopping_cart,
    Icons.local_gas_station.codePoint: Icons.local_gas_station,
    Icons.directions_car.codePoint: Icons.directions_car,
    Icons.shopping_bag.codePoint: Icons.shopping_bag,
    Icons.lightbulb.codePoint: Icons.lightbulb,
    Icons.home.codePoint: Icons.home,
    Icons.movie.codePoint: Icons.movie,
    Icons.medical_services.codePoint: Icons.medical_services,
    Icons.school.codePoint: Icons.school,
    Icons.flight.codePoint: Icons.flight,
    Icons.savings.codePoint: Icons.savings,
    Icons.work.codePoint: Icons.work,
    Icons.coffee.codePoint: Icons.coffee,
    Icons.fitness_center.codePoint: Icons.fitness_center,
    Icons.pets.codePoint: Icons.pets,
    Icons.subscriptions.codePoint: Icons.subscriptions,
    Icons.celebration.codePoint: Icons.celebration,
    Icons.phone_android.codePoint: Icons.phone_android,
    Icons.local_offer.codePoint: Icons.local_offer,
    Icons.receipt_long.codePoint: Icons.receipt_long,
    Icons.attach_money.codePoint: Icons.attach_money,
    Icons.credit_card.codePoint: Icons.credit_card,
    Icons.account_balance.codePoint: Icons.account_balance,
    Icons.directions_bus.codePoint: Icons.directions_bus,
    Icons.fastfood.codePoint: Icons.fastfood,
    Icons.local_hospital.codePoint: Icons.local_hospital,
    Icons.sports_esports.codePoint: Icons.sports_esports,
    Icons.train.codePoint: Icons.train,
    Icons.two_wheeler.codePoint: Icons.two_wheeler,
    Icons.shopping_basket.codePoint: Icons.shopping_basket,
    Icons.kitchen.codePoint: Icons.kitchen,
    Icons.wifi.codePoint: Icons.wifi,
    Icons.phone.codePoint: Icons.phone,
    Icons.local_pharmacy.codePoint: Icons.local_pharmacy,
    Icons.hotel.codePoint: Icons.hotel,
    Icons.pool.codePoint: Icons.pool,
    Icons.music_note.codePoint: Icons.music_note,
    Icons.book.codePoint: Icons.book,
    Icons.laptop.codePoint: Icons.laptop,
    Icons.build.codePoint: Icons.build,
    Icons.child_care.codePoint: Icons.child_care,
    Icons.favorite.codePoint: Icons.favorite,
    Icons.star.codePoint: Icons.star,
    Icons.category.codePoint: Icons.category,
  };

  IconData get iconData => _iconMap[iconCodePoint] ?? Icons.category;

  Color get color => Color(colorValue);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'iconCodePoint': iconCodePoint,
        'iconFontFamily': iconFontFamily,
        'iconFontPackage': iconFontPackage,
        'colorValue': colorValue,
        'createdAt': createdAt.toIso8601String(),
        'isDefault': isDefault,
      };

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        iconCodePoint: (json['iconCodePoint'] as num?)?.toInt() ?? Icons.category.codePoint,
        iconFontFamily: json['iconFontFamily'] as String?,
        iconFontPackage: json['iconFontPackage'] as String?,
        colorValue: (json['colorValue'] as num?)?.toInt() ?? 0xFF10B981,
        createdAt: json['createdAt'] != null
            ? (DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now())
            : DateTime.now(),
        isDefault: json['isDefault'] as bool? ?? false,
      );

  Category copyWith({
    String? id,
    String? name,
    int? iconCodePoint,
    String? iconFontFamily,
    String? iconFontPackage,
    int? colorValue,
    DateTime? createdAt,
    bool? isDefault,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      iconFontFamily: iconFontFamily ?? this.iconFontFamily,
      iconFontPackage: iconFontPackage ?? this.iconFontPackage,
      colorValue: colorValue ?? this.colorValue,
      createdAt: createdAt ?? this.createdAt,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
