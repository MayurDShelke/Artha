import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../services/default_data.dart';
import '../state/expense_scope.dart';
import '../state/expense_state.dart';
import '../theme/app_theme.dart';
import 'category_form_dialog.dart';

class ExpenseFormDialog extends StatefulWidget {
  final Expense? initialExpense;

  const ExpenseFormDialog({super.key, this.initialExpense});

  static Future<void> show(BuildContext context, {Expense? expense}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ExpenseFormDialog(initialExpense: expense),
    );
  }

  @override
  State<ExpenseFormDialog> createState() => _ExpenseFormDialogState();
}

class _ExpenseFormDialogState extends State<ExpenseFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  final _locationController = TextEditingController();

  late String _selectedCategoryId;
  late DateTime _selectedDate;
  late String _selectedPaymentMethod;
  bool _isRecurring = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final exp = widget.initialExpense;
    if (exp != null) {
      _amountController.text = exp.amount.toStringAsFixed(exp.amount % 1 == 0 ? 0 : 2);
      _titleController.text = exp.title;
      _notesController.text = exp.notes;
      _locationController.text = exp.location;
      _selectedCategoryId = exp.categoryId;
      _selectedDate = exp.date;
      _selectedPaymentMethod = exp.paymentMethod;
      _isRecurring = exp.isRecurring;
    } else {
      _selectedCategoryId = 'food';
      _selectedDate = DateTime.now();
      _selectedPaymentMethod = 'UPI';
      _isRecurring = false;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    _notesController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ExpenseScope.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEdit = widget.initialExpense != null;

    // Ensure selected category is valid
    if (!state.categories.any((c) => c.id == _selectedCategoryId)) {
      if (state.categories.isNotEmpty) {
        _selectedCategoryId = state.categories.first.id;
      }
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
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
            margin: const EdgeInsets.only(top: 12, bottom: 6),
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Top bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEdit ? 'Edit Expense' : 'Add Expense',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Form fields
          Flexible(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // 1. Amount input (Large spending number)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AMOUNT',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              state.currencySymbol,
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: _amountController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                ),
                                decoration: const InputDecoration(
                                  hintText: '0',
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  fillColor: Colors.transparent,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Please enter amount';
                                  }
                                  final num = double.tryParse(val.trim());
                                  if (num == null || num <= 0) {
                                    return 'Please enter a valid positive amount';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // 2. Expense Name / Title
                  TextFormField(
                    controller: _titleController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Expense Name',
                      hintText: 'e.g., Petrol, Lunch, Grocery run',
                      prefixIcon: Icon(Icons.edit_note_rounded),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please enter expense name';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 18),

                  // 3. Category Selection with Custom Category creation
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Category',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('New Category'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () => _openAddCategory(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 92,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: state.categories.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (context, idx) {
                        final cat = state.categories[idx];
                        final isSelected = cat.id == _selectedCategoryId;
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selectedCategoryId = cat.id;
                            });
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: 76,
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? cat.color.withAlpha(isDark ? 55 : 35)
                                  : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? cat.color
                                    : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: cat.color.withAlpha(isSelected ? 220 : 40),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    cat.iconData,
                                    size: 20,
                                    color: isSelected ? Colors.white : cat.color,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  cat.name,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 4. Date Selection (Completely editable, multi-year historical support!)
                  Text(
                    'Date',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Preset buttons
                      _buildDatePresetChip('Today', DateTime.now()),
                      const SizedBox(width: 8),
                      _buildDatePresetChip('Yesterday', DateTime.now().subtract(const Duration(days: 1))),
                      const SizedBox(width: 8),
                      // Custom date selector button (allows going back years!)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickCustomDate,
                          icon: const Icon(Icons.calendar_month_rounded, size: 18),
                          label: Text(
                            DateFormat('dd MMM yyyy').format(_selectedDate),
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: BorderSide(
                              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 5. Payment Method
                  Text(
                    'Payment Method',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: DefaultData.paymentMethods.map((method) {
                      final isSelected = _selectedPaymentMethod == method;
                      return ChoiceChip(
                        label: Text(method),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedPaymentMethod = method;
                            });
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

                  const SizedBox(height: 20),

                  // 6. Optional: Location & Notes
                  TextFormField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      labelText: 'Location (Optional)',
                      hintText: 'e.g., Shell Bunk, Phoenix Mall',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                  ),

                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Notes (Optional)',
                      hintText: 'Any extra details...',
                      prefixIcon: Icon(Icons.notes_rounded),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 7. Recurring toggle
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Recurring Expense', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: Text(
                      'Mark this expense as periodic (rent, bill, subscription)',
                      style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                    ),
                    value: _isRecurring,
                    activeThumbColor: AppColors.primary,
                    onChanged: (val) {
                      setState(() {
                        _isRecurring = val;
                      });
                    },
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          // Action Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : () => _handleSave(state),
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        isEdit ? 'Save Changes' : 'Add Expense',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePresetChip(String label, DateTime targetDate) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _selectedDate.year == targetDate.year &&
        _selectedDate.month == targetDate.month &&
        _selectedDate.day == targetDate.day;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedDate = targetDate;
          });
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
      backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
    );
  }

  Future<void> _pickCustomDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      // Full historical range: going back 20 years to 2010!
      firstDate: DateTime(2010, 1, 1),
      lastDate: DateTime(2035, 12, 31),
      helpText: 'SELECT EXPENSE DATE',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primary,
                  onPrimary: Colors.white,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _openAddCategory(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const CategoryFormDialog(),
    );
  }

  Future<void> _handleSave(ExpenseState state) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final amount = double.parse(_amountController.text.trim());
    final title = _titleController.text.trim();
    final dateStr = Expense.formatDate(_selectedDate);
    final notes = _notesController.text.trim();
    final location = _locationController.text.trim();

    try {
      if (widget.initialExpense != null) {
        final updated = widget.initialExpense!.copyWith(
          amount: amount,
          title: title,
          categoryId: _selectedCategoryId,
          dateString: dateStr,
          paymentMethod: _selectedPaymentMethod,
          notes: notes,
          location: location,
          isRecurring: _isRecurring,
        );
        await state.updateExpense(updated);
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Expense updated successfully'),
              backgroundColor: AppColors.primary,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        await state.addExpense(
          amount: amount,
          title: title,
          categoryId: _selectedCategoryId,
          dateString: dateStr,
          paymentMethod: _selectedPaymentMethod,
          notes: notes,
          location: location,
          isRecurring: _isRecurring,
        );
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Expense added successfully'),
              backgroundColor: AppColors.primary,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving expense: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }
}
