import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' hide Category;
import '../models/category.dart';
import '../models/expense.dart';
import 'default_data.dart';

/// Service responsible for storing and retrieving all expense data, categories,
/// and user preferences from Firebase Firestore so it can be accessed from any app.
class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  FirebaseFirestore? get _firestore {
    try {
      return FirebaseFirestore.instance;
    } catch (e) {
      debugPrint('Firestore instance unavailable: $e');
      return null;
    }
  }

  // Collection references for a specific user
  CollectionReference<Map<String, dynamic>>? _userExpensesRef(String userId) {
    if (_firestore == null) return null;
    return _firestore!.collection('users').doc(userId).collection('expenses');
  }

  CollectionReference<Map<String, dynamic>>? _userCategoriesRef(String userId) {
    if (_firestore == null) return null;
    return _firestore!.collection('users').doc(userId).collection('categories');
  }

  /// Save or update user profile document in Firestore
  Future<void> saveUserProfile(
    String userId, {
    String? email,
    String? displayName,
    String? currencySymbol,
  }) async {
    if (_firestore == null) return;
    try {
      await _firestore!.collection('users').doc(userId).set({
        'uid': userId,
        if (email != null && email.isNotEmpty) 'email': email,
        if (displayName != null && displayName.isNotEmpty) 'displayName': displayName,
        if (currencySymbol != null && currencySymbol.isNotEmpty)
          'currencySymbol': currencySymbol,
        'lastActiveAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore saveUserProfile error: $e');
    }
  }

  /// Real-time stream of all expenses for a user from Firestore
  Stream<List<Expense>> streamExpenses(String userId) {
    final ref = _userExpensesRef(userId);
    if (ref == null) return const Stream.empty();

    return ref.snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) => Expense.fromJson(doc.data())).toList();
      list.sort((a, b) {
        final comp = b.dateString.compareTo(a.dateString);
        if (comp != 0) return comp;
        return b.createdAt.compareTo(a.createdAt);
      });
      return list;
    });
  }

  /// Fetch all expenses for a user from Firestore
  Future<List<Expense>> fetchExpenses(String userId) async {
    final ref = _userExpensesRef(userId);
    if (ref == null) return [];

    try {
      final snapshot = await ref.get();
      final list = snapshot.docs.map((doc) => Expense.fromJson(doc.data())).toList();
      list.sort((a, b) {
        final comp = b.dateString.compareTo(a.dateString);
        if (comp != 0) return comp;
        return b.createdAt.compareTo(a.createdAt);
      });
      return list;
    } catch (e) {
      debugPrint('Firestore fetchExpenses error: $e');
      return [];
    }
  }

  /// Save or update an expense in Firestore
  Future<void> saveExpense(String userId, Expense expense) async {
    final ref = _userExpensesRef(userId);
    if (ref == null) return;

    try {
      await ref.doc(expense.id).set(expense.toJson(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore saveExpense error: $e');
    }
  }

  /// Batch upload multiple expenses (chunked by 400 to respect Firestore batch limit)
  Future<void> uploadMultipleExpenses(String userId, List<Expense> expenses) async {
    final ref = _userExpensesRef(userId);
    if (ref == null || expenses.isEmpty) return;

    try {
      const chunkSize = 400;
      for (int i = 0; i < expenses.length; i += chunkSize) {
        final chunk = expenses.sublist(
          i,
          i + chunkSize > expenses.length ? expenses.length : i + chunkSize,
        );
        final batch = _firestore!.batch();
        for (final exp in chunk) {
          batch.set(ref.doc(exp.id), exp.toJson(), SetOptions(merge: true));
        }
        await batch.commit();
      }
    } catch (e) {
      debugPrint('Firestore uploadMultipleExpenses error: $e');
    }
  }

  /// Delete an expense from Firestore
  Future<void> deleteExpense(String userId, String expenseId) async {
    final ref = _userExpensesRef(userId);
    if (ref == null) return;

    try {
      await ref.doc(expenseId).delete();
    } catch (e) {
      debugPrint('Firestore deleteExpense error: $e');
    }
  }

  /// Real-time stream of custom categories from Firestore
  Stream<List<Category>> streamCategories(String userId) {
    final ref = _userCategoriesRef(userId);
    if (ref == null) return const Stream.empty();

    return ref.snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) return DefaultData.defaultCategories;
      return snapshot.docs.map((doc) => Category.fromJson(doc.data())).toList();
    });
  }

  /// Fetch custom categories for a user from Firestore
  Future<List<Category>> fetchCategories(String userId) async {
    final ref = _userCategoriesRef(userId);
    if (ref == null) return DefaultData.defaultCategories;

    try {
      final snapshot = await ref.get();
      if (snapshot.docs.isEmpty) {
        return DefaultData.defaultCategories;
      }
      return snapshot.docs.map((doc) => Category.fromJson(doc.data())).toList();
    } catch (e) {
      debugPrint('Firestore fetchCategories error: $e');
      return DefaultData.defaultCategories;
    }
  }

  /// Save a category to Firestore
  Future<void> saveCategory(String userId, Category category) async {
    final ref = _userCategoriesRef(userId);
    if (ref == null) return;

    try {
      await ref.doc(category.id).set(category.toJson(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore saveCategory error: $e');
    }
  }

  /// Delete a category from Firestore
  Future<void> deleteCategory(String userId, String categoryId) async {
    final ref = _userCategoriesRef(userId);
    if (ref == null) return;

    try {
      await ref.doc(categoryId).delete();
    } catch (e) {
      debugPrint('Firestore deleteCategory error: $e');
    }
  }

  /// Delete all cloud data for a user
  Future<void> clearUserData(String userId) async {
    final expRef = _userExpensesRef(userId);
    final catRef = _userCategoriesRef(userId);

    if (expRef != null) {
      try {
        final docs = await expRef.get();
        final batch = _firestore!.batch();
        for (final d in docs.docs) {
          batch.delete(d.reference);
        }
        await batch.commit();
      } catch (e) {
        debugPrint('Firestore clearUserData expenses error: $e');
      }
    }

    if (catRef != null) {
      try {
        final docs = await catRef.get();
        final batch = _firestore!.batch();
        for (final d in docs.docs) {
          batch.delete(d.reference);
        }
        await batch.commit();
      } catch (e) {
        debugPrint('Firestore clearUserData categories error: $e');
      }
    }
  }
}
