import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../models/transaction_model.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  FirebaseFirestore? get _firestore {
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseFirestore.instance;
      }
    } catch (e) {
      debugPrint('Firestore instance not available: $e');
    }
    return null;
  }

  // Collection reference for a user's transactions
  CollectionReference<Map<String, dynamic>>? _userTransactionsRef(
    String userId,
  ) {
    final db = _firestore;
    if (db == null || userId.isEmpty) return null;
    return db.collection('users').doc(userId).collection('transactions');
  }

  // Document reference for user's budget settings
  DocumentReference<Map<String, dynamic>>? _userSettingsRef(String userId) {
    final db = _firestore;
    if (db == null || userId.isEmpty) return null;
    return db
        .collection('users')
        .doc(userId)
        .collection('settings')
        .doc('budget_info');
  }

  /// Real-time stream of transactions for the specified user
  Stream<List<ExpenseItem>> streamTransactions(String userId) {
    final ref = _userTransactionsRef(userId);
    if (ref == null) {
      return Stream.value([]);
    }

    return ref
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs.map((doc) {
            final data = doc.data();
            DateTime parsedDate = DateTime.now();
            if (data['date'] is Timestamp) {
              parsedDate = (data['date'] as Timestamp).toDate();
            } else if (data['date'] is String) {
              parsedDate =
                  DateTime.tryParse(data['date'] as String) ?? DateTime.now();
            }

            return ExpenseItem(
              id: (data['id'] as String?)?.isNotEmpty == true
                  ? (data['id'] as String)
                  : doc.id,
              title: data['title'] as String? ?? 'Expense',
              amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
              category: data['category'] as String? ?? 'General',
              account: data['account'] as String? ?? 'Cash',
              type: data['type'] as String? ?? 'expense',
              needWant: data['needWant'] as String? ?? 'need',
              date: parsedDate,
            );
          }).toList();

          // Sort by date descending (newest first)
          items.sort((a, b) => b.date.compareTo(a.date));
          return items;
        })
        .handleError((error) {
          debugPrint('Error streaming transactions from Firestore: $error');
          return <ExpenseItem>[];
        });
  }

  /// One-time fetch of user's transactions
  Future<List<ExpenseItem>> fetchTransactions(String userId) async {
    final ref = _userTransactionsRef(userId);
    if (ref == null) return [];

    try {
      final snapshot = await ref.get();
      final items = snapshot.docs.map((doc) {
        final data = doc.data();
        DateTime parsedDate = DateTime.now();
        if (data['date'] is Timestamp) {
          parsedDate = (data['date'] as Timestamp).toDate();
        } else if (data['date'] is String) {
          parsedDate =
              DateTime.tryParse(data['date'] as String) ?? DateTime.now();
        }

        return ExpenseItem(
          id: (data['id'] as String?)?.isNotEmpty == true
              ? (data['id'] as String)
              : doc.id,
          title: data['title'] as String? ?? 'Expense',
          amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
          category: data['category'] as String? ?? 'General',
          account: data['account'] as String? ?? 'Cash',
          type: data['type'] as String? ?? 'expense',
          needWant: data['needWant'] as String? ?? 'need',
          date: parsedDate,
        );
      }).toList();

      items.sort((a, b) => b.date.compareTo(a.date));
      return items;
    } catch (e) {
      debugPrint('Error fetching transactions from Firestore: $e');
      return [];
    }
  }

  /// Save or create a new transaction in Firestore
  Future<void> saveTransaction(String userId, ExpenseItem item) async {
    final ref = _userTransactionsRef(userId);
    if (ref == null) return;

    try {
      final data = item.toJson();
      data['updatedAt'] = FieldValue.serverTimestamp();
      await ref.doc(item.id).set(data, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving transaction ${item.id} to Firestore: $e');
    }
  }

  /// Delete a transaction from Firestore
  Future<void> deleteTransaction(String userId, String transactionId) async {
    final ref = _userTransactionsRef(userId);
    if (ref == null) return;

    try {
      await ref.doc(transactionId).delete();
    } catch (e) {
      debugPrint(
        'Error deleting transaction $transactionId from Firestore: $e',
      );
    }
  }

  /// Clear all user transactions in Firestore
  Future<void> clearAllTransactions(String userId) async {
    final ref = _userTransactionsRef(userId);
    final db = _firestore;
    if (ref == null || db == null) return;

    try {
      final snapshot = await ref.get();
      final batch = db.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error clearing all transactions from Firestore: $e');
    }
  }

  /// Save user budget settings to Firestore
  Future<void> saveUserSettings(
    String userId, {
    double? monthlyBudget,
    Map<String, double>? categoryBudgets,
    Map<String, String>? categoryNeedWant,
    bool? dailyReminderEnabled,
    String? dailyReminderTime,
  }) async {
    final ref = _userSettingsRef(userId);
    if (ref == null) return;

    try {
      final Map<String, dynamic> data = {
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (monthlyBudget != null) data['monthlyBudget'] = monthlyBudget;
      if (categoryBudgets != null) data['categoryBudgets'] = categoryBudgets;
      if (categoryNeedWant != null) data['categoryNeedWant'] = categoryNeedWant;
      if (dailyReminderEnabled != null)
        data['dailyReminderEnabled'] = dailyReminderEnabled;
      if (dailyReminderTime != null)
        data['dailyReminderTime'] = dailyReminderTime;

      await ref.set(data, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving user settings to Firestore: $e');
    }
  }

  /// Fetch user budget settings from Firestore
  Future<Map<String, dynamic>?> getUserSettings(String userId) async {
    final ref = _userSettingsRef(userId);
    if (ref == null) return null;

    try {
      final doc = await ref.get();
      if (doc.exists) {
        return doc.data();
      }
    } catch (e) {
      debugPrint('Error fetching user settings from Firestore: $e');
    }
    return null;
  }

  /// Sync local transactions to Firestore if Firestore has 0 documents
  Future<void> syncLocalTransactionsIfEmpty(
    String userId,
    List<ExpenseItem> localItems,
  ) async {
    final ref = _userTransactionsRef(userId);
    final db = _firestore;
    if (ref == null || db == null || localItems.isEmpty) return;

    try {
      final snapshot = await ref.limit(1).get();
      if (snapshot.docs.isEmpty) {
        // Firestore is empty for this user, upload existing local transactions
        final batch = db.batch();
        for (final item in localItems) {
          final data = item.toJson();
          data['updatedAt'] = FieldValue.serverTimestamp();
          batch.set(ref.doc(item.id), data);
        }
        await batch.commit();
        debugPrint(
          'Successfully synced ${localItems.length} local items to Firestore.',
        );
      }
    } catch (e) {
      debugPrint('Error syncing local transactions to Firestore: $e');
    }
  }
}
