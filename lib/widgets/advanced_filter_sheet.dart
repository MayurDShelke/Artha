import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/filter_options.dart';
import '../services/default_data.dart';
import '../state/expense_scope.dart';
import '../theme/app_theme.dart';

class AdvancedFilterSheet extends StatefulWidget {
  final ExpenseFilter? initialFilter;

  const AdvancedFilterSheet({super.key, this.initialFilter});

  @override
  State<AdvancedFilterSheet> createState() => _AdvancedFilterSheetState();
}

class _AdvancedFilterSheetState extends State<AdvancedFilterSheet> {
  late QuickFilterType _selectedQuick;
  late DateTime? _customStart;
  late DateTime? _customEnd;
  late Set<String> _categoryIds;
  late Set<String> _paymentMethods;
  final TextEditingController _minAmountController = TextEditingController();
  final TextEditingController _maxAmountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final f = widget.initialFilter;
    if (f != null) {
      _selectedQuick = f.quickFilter;
      _customStart = f.customStartDate;
      _customEnd = f.customEndDate;
      _categoryIds = Set.from(f.selectedCategoryIds);
      _paymentMethods = Set.from(f.selectedPaymentMethods);
      if (f.minAmount != null) _minAmountController.text = f.minAmount!.toStringAsFixed(0);
      if (f.maxAmount != null) _maxAmountController.text = f.maxAmount!.toStringAsFixed(0);
    } else {
      _selectedQuick = QuickFilterType.twelveMonths;
      _customStart = null;
      _customEnd = null;
      _categoryIds = {};
      _paymentMethods = {};
    }
  }

  @override
  void dispose() {
    _minAmountController.dispose();
    _maxAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ExpenseScope.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filter Expenses',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedQuick = QuickFilterType.twelveMonths;
                      _customStart = null;
                      _customEnd = null;
                      _categoryIds.clear();
                      _paymentMethods.clear();
                      _minAmountController.clear();
                      _maxAmountController.clear();
                    });
                  },
                  child: const Text('Reset All', style: TextStyle(color: AppColors.primary)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Scrollable Filter Sections
          Flexible(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // 1. Time Horizon Presets
                _buildSectionHeader('Date Preset'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: QuickFilterType.values.map((type) {
                    final isSelected = _selectedQuick == type;
                    return ChoiceChip(
                      label: Text(type.title),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedQuick = type;
                        });
                        if (type == QuickFilterType.custom) {
                          _pickDateRange();
                        }
                      },
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                      ),
                      backgroundColor:
                          isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    );
                  }).toList(),
                ),

                if (_selectedQuick == QuickFilterType.custom) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _customStart != null && _customEnd != null
                              ? '${DateFormat('dd MMM yyyy').format(_customStart!)} — ${DateFormat('dd MMM yyyy').format(_customEnd!)}'
                              : 'Select date range',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        TextButton(
                          onPressed: _pickDateRange,
                          child: const Text('Change Dates'),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // 2. Categories
                _buildSectionHeader('Categories'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: state.categories.map((cat) {
                    final isSelected = _categoryIds.contains(cat.id);
                    return FilterChip(
                      avatar: Icon(cat.iconData, size: 16, color: cat.color),
                      label: Text(cat.name),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _categoryIds.add(cat.id);
                          } else {
                            _categoryIds.remove(cat.id);
                          }
                        });
                      },
                      selectedColor: cat.color.withAlpha(isDark ? 80 : 50),
                      checkmarkColor: cat.color,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                      backgroundColor:
                          isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                // 3. Payment Method
                _buildSectionHeader('Payment Method'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: DefaultData.paymentMethods.map((method) {
                    final isSelected = _paymentMethods.contains(method);
                    return FilterChip(
                      label: Text(method),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _paymentMethods.add(method);
                          } else {
                            _paymentMethods.remove(method);
                          }
                        });
                      },
                      selectedColor: AppColors.primary.withAlpha(isDark ? 80 : 50),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                      backgroundColor:
                          isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                // 4. Amount Range
                _buildSectionHeader('Amount Range (${state.currencySymbol})'),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _minAmountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          prefixText: '${state.currencySymbol} ',
                          labelText: 'Min Amount',
                          hintText: '0',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _maxAmountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          prefixText: '${state.currencySymbol} ',
                          labelText: 'Max Amount',
                          hintText: '50000',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          // Apply button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  final minAmt = double.tryParse(_minAmountController.text.trim());
                  final maxAmt = double.tryParse(_maxAmountController.text.trim());

                  final updated = state.filter.copyWith(
                    quickFilter: _selectedQuick,
                    customStartDate: _customStart,
                    customEndDate: _customEnd,
                    selectedCategoryIds: _categoryIds,
                    selectedPaymentMethods: _paymentMethods,
                    minAmount: minAmt,
                    maxAmount: maxAmt,
                  );

                  state.updateFilter(updated);
                  Navigator.of(context).pop();
                },
                child: const Text('Apply Filters', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDateRange: _customStart != null && _customEnd != null
          ? DateTimeRange(start: _customStart!, end: _customEnd!)
          : DateTimeRange(start: now.subtract(const Duration(days: 30)), end: now),
    );
    if (picked != null) {
      setState(() {
        _selectedQuick = QuickFilterType.custom;
        _customStart = picked.start;
        _customEnd = picked.end;
      });
    }
  }
}
