import 'package:flutter/material.dart';
import 'expense_state.dart';

class ExpenseScope extends InheritedNotifier<ExpenseState> {
  const ExpenseScope({
    super.key,
    required ExpenseState state,
    required super.child,
  }) : super(notifier: state);

  static ExpenseState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ExpenseScope>();
    assert(scope != null, 'No ExpenseScope found in context');
    return scope!.notifier!;
  }
}
