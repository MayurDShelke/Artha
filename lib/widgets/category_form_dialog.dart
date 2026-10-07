import 'package:flutter/material.dart';
import '../models/category.dart';
import '../state/expense_scope.dart';
import '../theme/app_theme.dart';

class CategoryFormDialog extends StatefulWidget {
  final Category? initialCategory;

  const CategoryFormDialog({super.key, this.initialCategory});

  @override
  State<CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<CategoryFormDialog> {
  final _nameController = TextEditingController();
  late int _selectedIconCode;
  late int _selectedColorValue;
  final _formKey = GlobalKey<FormState>();

  static const List<IconData> availableIcons = [
    Icons.restaurant,
    Icons.shopping_cart,
    Icons.local_gas_station,
    Icons.directions_car,
    Icons.shopping_bag,
    Icons.lightbulb,
    Icons.home,
    Icons.sports_esports,
    Icons.medical_services,
    Icons.school,
    Icons.flight,
    Icons.subscriptions,
    Icons.coffee,
    Icons.pets,
    Icons.fitness_center,
    Icons.movie,
    Icons.work,
    Icons.savings,
    Icons.phone_android,
    Icons.celebration,
  ];

  static const List<Color> availableColors = [
    Color(0xFF10B981), // Emerald
    Color(0xFFF97316), // Orange
    Color(0xFF3B82F6), // Blue
    Color(0xFFEF4444), // Red
    Color(0xFFEC4899), // Pink
    Color(0xFF8B5CF6), // Purple
    Color(0xFF06B6D4), // Cyan
    Color(0xFFEAB308), // Yellow
    Color(0xFF14B8A6), // Teal
    Color(0xFF6366F1), // Indigo
    Color(0xFFA855F7), // Violet
    Color(0xFF64748B), // Slate
  ];

  @override
  void initState() {
    super.initState();
    final c = widget.initialCategory;
    if (c != null) {
      _nameController.text = c.name;
      _selectedIconCode = c.iconCodePoint;
      _selectedColorValue = c.colorValue;
    } else {
      _selectedIconCode = Icons.local_offer.codePoint;
      _selectedColorValue = const Color(0xFF10B981).toARGB32();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ExpenseScope.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEdit = widget.initialCategory != null;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        isEdit ? 'Edit Category' : 'New Category',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 360,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Category Name',
                    hintText: 'e.g., Gym, Freelance, Pet Care',
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Enter a name' : null,
                ),
                const SizedBox(height: 18),
                Text(
                  'Choose Color',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: availableColors.map((color) {
                    final isSelected = color.toARGB32() == _selectedColorValue;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedColorValue = color.toARGB32();
                        });
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.transparent,
                            width: 2.5,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: color.withAlpha(120),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, size: 16, color: Colors.white)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),
                Text(
                  'Choose Icon',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: availableIcons.map((icon) {
                    final isSelected = icon.codePoint == _selectedIconCode;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedIconCode = icon.codePoint;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Color(_selectedColorValue).withAlpha(isDark ? 80 : 50)
                              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? Color(_selectedColorValue) : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          icon,
                          size: 20,
                          color: isSelected
                              ? Color(_selectedColorValue)
                              : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (!_formKey.currentState!.validate()) return;
            final name = _nameController.text.trim();
            if (isEdit) {
              final updated = widget.initialCategory!.copyWith(
                name: name,
                iconCodePoint: _selectedIconCode,
                colorValue: _selectedColorValue,
              );
              await state.updateCategory(updated);
            } else {
              await state.addCategory(
                name: name,
                iconCodePoint: _selectedIconCode,
                colorValue: _selectedColorValue,
              );
            }
            if (context.mounted) Navigator.of(context).pop();
          },
          child: Text(isEdit ? 'Save' : 'Create'),
        ),
      ],
    );
  }
}
