import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/category_data.dart';
import '../models/transaction_model.dart';
import '../services/firestore_service.dart';

class ExpenseController extends ChangeNotifier {
  static const String _budgetKey = 'mvc_monthly_budget';
  static const String _expensesKey = 'mvc_expenses_list';
  static const String _categoryBudgetsKey = 'mvc_category_budgets';
  static const String _categoryNeedWantKey = 'mvc_category_need_want';

  String _selectedAccount = 'Cash';
  double _monthlyBudget = 0.0;
  List<ExpenseItem> _transactions = [];
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<List<ExpenseItem>>? _firestoreSubscription;
  final FirestoreService _firestoreService = FirestoreService();
  bool _isFirestoreSyncing = false;

  // Category Target Budgets (Particular amounts allocated by the user for each category)
  Map<String, double> _categoryBudgets = {};

  Future<void>? _initFuture;
  Future<void> get initialized => _initFuture ?? Future.value();

  ExpenseController() {
    _initFuture = _initStorageAndAuth();
  }

  Future<void> _initStorageAndAuth() async {
    // 1. Immediately load cached local data for instant responsive UI
    await loadFromStorage();

    // 2. Setup Firebase Auth listener and Cloud Firestore synchronization
    try {
      if (Firebase.apps.isNotEmpty) {
        _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) async {
          await loadFromStorage();
          if (user != null) {
            await _setupFirestore(user.uid);
          } else {
            await _firestoreSubscription?.cancel();
            _firestoreSubscription = null;
          }
        });
      }
    } catch (e) {
      debugPrint('Auth listener setup error: $e');
    }
  }

  /// Setup Cloud Firestore real-time synchronization and load settings
  Future<void> _setupFirestore(String userId) async {
    if (userId.isEmpty) return;

    _isFirestoreSyncing = true;
    notifyListeners();

    try {
      // Fetch Firestore budget settings if any exist
      final firestoreSettings = await _firestoreService.getUserSettings(userId);
      if (firestoreSettings != null) {
        if (firestoreSettings['monthlyBudget'] != null) {
          _monthlyBudget = (firestoreSettings['monthlyBudget'] as num).toDouble();
        }
        if (firestoreSettings['categoryBudgets'] != null) {
          final Map<String, dynamic> rawBudgets = Map<String, dynamic>.from(firestoreSettings['categoryBudgets'] as Map);
          _categoryBudgets = rawBudgets.map((k, v) => MapEntry(k, (v as num).toDouble()));
        }
        if (firestoreSettings['categoryNeedWant'] != null) {
          final Map<String, dynamic> rawNeedWant = Map<String, dynamic>.from(firestoreSettings['categoryNeedWant'] as Map);
          CategoryData.loadCustomCategoryNeedWant(rawNeedWant.map((k, v) => MapEntry(k, v.toString())));
        }
      } else {
        // First time cloud sync for this user: upload local budget settings to Firestore
        await _firestoreService.saveUserSettings(
          userId,
          monthlyBudget: _monthlyBudget,
          categoryBudgets: _categoryBudgets,
          categoryNeedWant: CategoryData.customCategoryNeedWantMap,
        );
      }

      // If user had local transactions before logging in and cloud is empty, upload them
      if (_transactions.isNotEmpty) {
        await _firestoreService.syncLocalTransactionsIfEmpty(userId, _transactions);
      }

      // Subscribe to real-time changes in Cloud Firestore
      await _firestoreSubscription?.cancel();
      _firestoreSubscription = _firestoreService.streamTransactions(userId).listen((cloudItems) {
        if (cloudItems.isNotEmpty || _transactions.isEmpty) {
          _transactions = cloudItems;
          _applyCategoryClassifications();
          notifyListeners();
          _saveLocalCacheOnly();
        }
      }, onError: (err) {
        debugPrint('Firestore stream error: $err');
      });
    } catch (e) {
      debugPrint('Error setting up Firestore: $e');
    } finally {
      _isFirestoreSyncing = false;
      notifyListeners();
    }
  }

  void _applyCategoryClassifications() {
    if (CategoryData.customCategoryNeedWantMap.isEmpty) return;
    for (int i = 0; i < _transactions.length; i++) {
      final catLower = _transactions[i].category.toLowerCase();
      if (CategoryData.customCategoryNeedWantMap.containsKey(catLower)) {
        final customTag = CategoryData.customCategoryNeedWantMap[catLower]!;
        if (_transactions[i].needWant != customTag) {
          _transactions[i] = _transactions[i].copyWith(needWant: customTag);
        }
      }
    }
  }

  /// Manually force a Cloud Firestore sync
  Future<void> syncWithFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _setupFirestore(user.uid);
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _firestoreSubscription?.cancel();
    super.dispose();
  }

  // Getters
  bool get isFirestoreSyncing => _isFirestoreSyncing;
  String get selectedAccount => _selectedAccount;
  double get monthlyBudget => _monthlyBudget;
  List<ExpenseItem> get allTransactions => List.unmodifiable(_transactions);
  List<ExpenseItem> get expenses => _transactions.where((e) => e.type == 'expense').toList();
  List<ExpenseItem> get incomes => _transactions.where((e) => e.type == 'income').toList();
  ExpenseItem? get lastEnteredTransaction => _transactions.isNotEmpty ? _transactions.first : null;
  List<ExpenseItem> get recentTransactions => _transactions.take(5).toList();

  void selectAccount(String account) {
    _selectedAccount = account;
    notifyListeners();
  }

  // Transactions list
  List<ExpenseItem> getTransactionsForAccount(String account) {
    return _transactions;
  }

  List<ExpenseItem> getExpensesForAccount(String account) {
    return _transactions.where((e) => e.type == 'expense').toList();
  }

  double getAccountTotalExpense([String? account]) => totalDebit;
  double getAccountNeedExpense([String? account]) => currentNeedExpense;
  double getAccountWantExpense([String? account]) => currentWantExpense;

  double get totalDebit => expenses.fold(0.0, (sum, e) => sum + e.amount);

  // Total Credit is strictly the sum of all recorded Income / Credit entries
  double get totalCredit => incomes.fold(0.0, (sum, e) => sum + e.amount);

  // Net Saved Amount: Total Credit minus Total Debit
  double get netSavedAmount => totalCredit - totalDebit;

  double get currentBalance => netSavedAmount;
  double get totalSpent => totalDebit;
  double get remainingAmount => totalCredit > 0 ? (totalCredit - totalDebit) : (_monthlyBudget - totalDebit);

  double get thisMonthExpense => getAccountThisMonthExpense(_selectedAccount);
  double get thisMonthIncome => totalCredit;
  double get thisMonthBalance => totalCredit - thisMonthExpense;

  double get thisWeekIncome => totalCredit;
  double get yearToDateIncome => totalCredit * 12;

  double get todayExpense => getAccountTodayExpense(_selectedAccount);
  double get thisWeekExpense => getAccountThisWeekExpense(_selectedAccount);
  double get yearToDateExpense => getAccountYearToDateExpense(_selectedAccount);

  // -------------------------------------------------------------
  // Need (Compulsory) vs Want (Not Necessary) Breakdown
  // -------------------------------------------------------------
  double get currentNeedExpense => expenses.where((e) => e.isNeed).fold(0.0, (sum, e) => sum + e.amount);
  double get currentWantExpense => expenses.where((e) => e.isWant).fold(0.0, (sum, e) => sum + e.amount);

  double get needPercentage {
    if (totalSpent <= 0) return 0;
    return (currentNeedExpense / totalSpent);
  }

  double get wantPercentage {
    if (totalSpent <= 0) return 0;
    return (currentWantExpense / totalSpent);
  }

  double get spentPercentage {
    if (totalCredit <= 0) return 0;
    return (totalDebit / totalCredit);
  }

  // -------------------------------------------------------------
  // Category Budget / Target Amount Management
  // -------------------------------------------------------------
  Map<String, double> get categoryBudgetsMap => Map.unmodifiable(_categoryBudgets);

  double getCategoryBudget(String category) {
    if (_categoryBudgets.containsKey(category)) {
      return _categoryBudgets[category]!;
    }
    for (final entry in _categoryBudgets.entries) {
      if (entry.key.toLowerCase() == category.toLowerCase()) {
        return entry.value;
      }
    }
    return 0.0;
  }

  Future<void> setCategoryBudget(String category, double budget) async {
    _categoryBudgets.removeWhere((k, _) => k.toLowerCase() == category.toLowerCase());
    if (budget > 0) {
      _categoryBudgets[category] = budget;
    }
    notifyListeners();
    await _saveToStorage();
    final uid = _currentUserId;
    if (uid != null) {
      await _firestoreService.saveUserSettings(uid, categoryBudgets: _categoryBudgets);
    }
  }

  Future<void> clearCategoryBudget(String category) async {
    _categoryBudgets.removeWhere((k, _) => k.toLowerCase() == category.toLowerCase());
    notifyListeners();
    await _saveToStorage();
    final uid = _currentUserId;
    if (uid != null) {
      await _firestoreService.saveUserSettings(uid, categoryBudgets: _categoryBudgets);
    }
  }

  Future<void> clearAllBudgets() async {
    _monthlyBudget = 0.0;
    _categoryBudgets.clear();
    notifyListeners();
    await _saveToStorage();
    final uid = _currentUserId;
    if (uid != null) {
      await _firestoreService.saveUserSettings(uid, monthlyBudget: 0.0, categoryBudgets: {});
    }
  }

  Future<void> setCategoryClassification(String category, String needWant) async {
    CategoryData.setCategoryNeedWant(category, needWant);

    // Update existing transactions for this category to reflect the user's classification
    for (int i = 0; i < _transactions.length; i++) {
      if (_transactions[i].category.toLowerCase() == category.toLowerCase()) {
        _transactions[i] = _transactions[i].copyWith(needWant: needWant);
      }
    }

    notifyListeners();
    await _saveToStorage();
    final uid = _currentUserId;
    if (uid != null) {
      await _firestoreService.saveUserSettings(
        uid,
        categoryNeedWant: CategoryData.customCategoryNeedWantMap,
      );
      // Sync updated transactions to Firestore
      for (final tx in _transactions) {
        if (tx.category.toLowerCase() == category.toLowerCase()) {
          await _firestoreService.saveTransaction(uid, tx);
        }
      }
    }
  }

  String getCategoryClassification(String category) {
    return CategoryData.getCategoryNeedWant(category);
  }

  double get totalCategoryBudgetsSum {
    return _categoryBudgets.values.fold(0.0, (sum, v) => sum + v);
  }

  int get allocatedCategoriesCount {
    int count = 0;
    for (final cat in CategoryData.allExpenseCategories) {
      if (getCategoryBudget(cat.name) > 0) {
        count++;
      }
    }
    return count;
  }

  int get unallocatedCategoriesCount {
    int count = 0;
    for (final cat in CategoryData.allExpenseCategories) {
      if (getCategoryBudget(cat.name) <= 0) {
        count++;
      }
    }
    return count;
  }

  bool isCategoryBudgetLocated(String category) {
    return getCategoryBudget(category) > 0;
  }

  Future<void> autoDistributeBudgetEvenly(double totalBudget, {List<String>? targetCategories}) async {
    final cats = targetCategories ?? CategoryData.allExpenseCategories.map((c) => c.name).toList();
    if (cats.isEmpty || totalBudget <= 0) return;
    final perCat = (totalBudget / cats.length).roundToDouble();
    _categoryBudgets.clear();
    for (final cat in cats) {
      _categoryBudgets[cat] = perCat;
    }
    _monthlyBudget = totalBudget;
    notifyListeners();
    await _saveToStorage();
  }

  bool get hasActiveBudget => totalAllocatedBudget > 0 || _monthlyBudget > 0;

  List<ExpenseItem> getCategoryTransactions(String category, {String? type}) {
    return _transactions.where((tx) {
      final matches = tx.category.toLowerCase() == category.toLowerCase();
      if (!matches) return false;
      if (type != null) {
        return tx.type.toLowerCase() == type.toLowerCase();
      }
      return true;
    }).toList();
  }

  double getCategoryTotalAmount(String category, {String? account, String? type}) {
    final txs = _transactions;
    double total = 0.0;
    for (final tx in txs) {
      if (tx.category.toLowerCase() == category.toLowerCase()) {
        if (type == null || tx.type.toLowerCase() == type.toLowerCase()) {
          total += tx.amount;
        }
      }
    }
    return total;
  }

  double getCategorySaved(String category) {
    final budget = getCategoryBudget(category);
    final spent = getCategoryTotalAmount(category);
    if (budget <= 0) return 0.0;
    return budget - spent;
  }

  double getCategoryBudgetUsageRatio(String category) {
    final budget = getCategoryBudget(category);
    if (budget <= 0) return 0.0;
    final spent = getCategoryTotalAmount(category);
    return (spent / budget).clamp(0.0, 2.0);
  }

  bool isCategoryOverBudget(String category) {
    final budget = getCategoryBudget(category);
    if (budget <= 0) return false;
    final spent = getCategoryTotalAmount(category);
    return spent > budget;
  }

  double get totalAllocatedBudget {
    if (_monthlyBudget > 0) return _monthlyBudget;
    return totalCategoryBudgetsSum;
  }

  double get totalBudgetSavings {
    double savings = 0.0;
    _categoryBudgets.forEach((cat, budget) {
      final spent = getCategoryTotalAmount(cat);
      if (budget > spent) {
        savings += (budget - spent);
      }
    });
    return savings;
  }

  int get overbudgetCategoryCount {
    int count = 0;
    _categoryBudgets.forEach((cat, budget) {
      final spent = getCategoryTotalAmount(cat);
      if (budget > 0 && spent > budget) {
        count++;
      }
    });
    return count;
  }

  bool get isOverallBudgetEnough {
    if (totalAllocatedBudget <= 0) return true;
    return totalDebit <= totalAllocatedBudget;
  }

  bool _dailyReminderEnabled = true;
  String _dailyReminderTime = '20:00'; // 8:00 PM
  static const String _dailyReminderKey = 'mvc_daily_reminder';
  static const String _dailyReminderTimeKey = 'mvc_daily_reminder_time';

  bool get dailyReminderEnabled => _dailyReminderEnabled;
  String get dailyReminderTime => _dailyReminderTime;

  Future<void> setDailyReminder(bool enabled, [String? time]) async {
    _dailyReminderEnabled = enabled;
    if (time != null) _dailyReminderTime = time;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dailyReminderKey, _dailyReminderEnabled);
    await prefs.setString(_dailyReminderTimeKey, _dailyReminderTime);
  }

  // -------------------------------------------------------------
  // Custom Categories & Budgeting
  // -------------------------------------------------------------
  Future<void> createCustomCategory({
    required String name,
    required IconData icon,
    required Color color,
    required String needWant,
    required double budget,
    bool isExpense = true,
  }) async {
    final cat = SimpleCategory(
      name.trim(),
      icon,
      color,
      defaultNeedWant: needWant,
      isExpense: isExpense,
    );
    CategoryData.addCustomCategory(cat);
    CategoryData.setCategoryNeedWant(name.trim(), needWant);
    if (budget > 0) {
      _categoryBudgets[name.trim()] = budget;
    }
    notifyListeners();
    await _saveToStorage();
    final uid = _currentUserId;
    if (uid != null) {
      await _firestoreService.saveUserSettings(
        uid,
        categoryBudgets: _categoryBudgets,
        categoryNeedWant: CategoryData.customCategoryNeedWantMap,
      );
    }
  }

  // -------------------------------------------------------------
  // Statement Export (CSV & Formatted Text Report)
  // -------------------------------------------------------------
  String generateStatementCsv({DateTime? startDate, DateTime? endDate}) {
    final filtered = _getFilteredTransactions(startDate, endDate);
    final buffer = StringBuffer();
    buffer.writeln('Date,Type,Title,Category,Account,Purpose,Amount (₹)');

    for (final tx in filtered) {
      final dateStr = '${tx.date.year}-${tx.date.month.toString().padLeft(2, '0')}-${tx.date.day.toString().padLeft(2, '0')}';
      final safeTitle = tx.title.replaceAll(',', ' ');
      final safeCategory = tx.category.replaceAll(',', ' ');
      buffer.writeln('$dateStr,${tx.type.toUpperCase()},$safeTitle,$safeCategory,${tx.account},${tx.needWant.toUpperCase()},${tx.amount.toStringAsFixed(2)}');
    }
    return buffer.toString();
  }

  String generateFormattedTextStatement({DateTime? startDate, DateTime? endDate}) {
    final filtered = _getFilteredTransactions(startDate, endDate);
    final totalIncome = filtered.where((t) => t.type == 'income').fold(0.0, (s, e) => s + e.amount);
    final totalExpense = filtered.where((t) => t.type == 'expense').fold(0.0, (s, e) => s + e.amount);
    final netSavings = totalIncome - totalExpense;

    final buffer = StringBuffer();
    buffer.writeln('========================================');
    buffer.writeln('          CASH MANAGER STATEMENT        ');
    buffer.writeln('========================================');
    if (startDate != null && endDate != null) {
      buffer.writeln('Period: ${startDate.day}/${startDate.month}/${startDate.year} - ${endDate.day}/${endDate.month}/${endDate.year}');
    } else {
      buffer.writeln('Period: Complete Financial History');
    }
    buffer.writeln('Generated: ${DateTime.now().toString().split('.')[0]}');
    buffer.writeln('----------------------------------------');
    buffer.writeln('Total Inflow (Income)  : ₹${totalIncome.toStringAsFixed(2)}');
    buffer.writeln('Total Outflow (Expense): ₹${totalExpense.toStringAsFixed(2)}');
    buffer.writeln('Net Saved Balance      : ₹${netSavings.toStringAsFixed(2)}');
    buffer.writeln('----------------------------------------');
    buffer.writeln('TRANSACTIONS (${filtered.length}):');
    buffer.writeln('----------------------------------------');

    for (final tx in filtered) {
      final dateStr = '${tx.date.day.toString().padLeft(2, '0')}/${tx.date.month.toString().padLeft(2, '0')}/${tx.date.year}';
      final sign = tx.type == 'income' ? '+' : '-';
      buffer.writeln('$dateStr | ${tx.type.toUpperCase().padRight(7)} | $sign₹${tx.amount.toStringAsFixed(2)} | ${tx.title} (${tx.category})');
    }
    buffer.writeln('========================================');
    buffer.writeln('         End of Statement Report        ');
    buffer.writeln('========================================');
    return buffer.toString();
  }

  List<ExpenseItem> _getFilteredTransactions(DateTime? start, DateTime? end) {
    if (start == null && end == null) return _transactions;
    return _transactions.where((tx) {
      if (start != null && tx.date.isBefore(DateTime(start.year, start.month, start.day))) {
        return false;
      }
      if (end != null && tx.date.isAfter(DateTime(end.year, end.month, end.day, 23, 59, 59))) {
        return false;
      }
      return true;
    }).toList();
  }

  double get remainingTargetBudget => (totalAllocatedBudget - totalDebit);
  bool get isBudgetSufficient => totalAllocatedBudget > 0 ? (totalDebit <= totalAllocatedBudget) : true;

  String get budgetSufficiencySummary {
    if (totalAllocatedBudget <= 0) {
      return 'No target budget set yet. Tap "Budget Planner" to allocate monthly expense limit.';
    }
    if (totalDebit <= totalAllocatedBudget) {
      final left = totalAllocatedBudget - totalDebit;
      return 'Target budget of ₹${totalAllocatedBudget.toStringAsFixed(0)} is sufficient for expenses! ₹${left.toStringAsFixed(0)} remaining from target.';
    } else {
      final over = totalDebit - totalAllocatedBudget;
      return 'Alert: Total debit expenses (₹${totalDebit.toStringAsFixed(0)}) exceeded target budget by ₹${over.toStringAsFixed(0)}!';
    }
  }

  ExpenseItem? getLatestTransactionForCategory(String category, {String? account}) {
    for (final tx in _transactions) {
      if (tx.category.toLowerCase() == category.toLowerCase()) {
        return tx;
      }
    }
    return null;
  }

  // Breakdown by period
  double getAccountTodayExpense(String account) {
    final now = DateTime.now();
    return expenses
        .where((e) => e.date.year == now.year && e.date.month == now.month && e.date.day == now.day)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  double getAccountThisWeekExpense(String account) {
    final now = DateTime.now();
    final startOfWeek = DateTime(now.year, now.month, now.day - (now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));
    return expenses
        .where((e) => e.date.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) && e.date.isBefore(endOfWeek))
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  double getAccountThisMonthExpense(String account) {
    final now = DateTime.now();
    return expenses
        .where((e) => e.date.year == now.year && e.date.month == now.month)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  double getAccountYearToDateExpense(String account) {
    final now = DateTime.now();
    return expenses
        .where((e) => e.date.year == now.year)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  List<ExpenseItem> get todayExpensesList {
    final now = DateTime.now();
    return expenses
        .where((e) => e.date.year == now.year && e.date.month == now.month && e.date.day == now.day)
        .toList();
  }

  List<ExpenseItem> get thisWeekExpensesList {
    final now = DateTime.now();
    final startOfWeek = DateTime(now.year, now.month, now.day - (now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));
    return expenses
        .where((e) => e.date.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) && e.date.isBefore(endOfWeek))
        .toList();
  }

  List<ExpenseItem> get thisMonthExpensesList {
    final now = DateTime.now();
    return expenses
        .where((e) => e.date.year == now.year && e.date.month == now.month)
        .toList();
  }

  List<ExpenseItem> get yearToDateExpensesList {
    final now = DateTime.now();
    return expenses
        .where((e) => e.date.year == now.year)
        .toList();
  }


  // -------------------------------------------------------------
  // Actions (MVC) & Cloud Firestore Persistence
  // -------------------------------------------------------------
  String? get _currentUserId {
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseAuth.instance.currentUser?.uid;
      }
    } catch (_) {}
    return null;
  }

  Future<void> addExpense({
    required String title,
    required double amount,
    required String category,
    String? account,
    String? needWant,
    required DateTime date,
  }) async {
    final resolvedNeedWant = (needWant != null && needWant.isNotEmpty)
        ? needWant
        : CategoryData.getCategoryNeedWant(category);
    final item = ExpenseItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title.trim().isEmpty ? category : title.trim(),
      amount: amount,
      category: category,
      account: 'Cash',
      type: 'expense',
      needWant: resolvedNeedWant,
      date: date,
    );
    _transactions.insert(0, item);
    notifyListeners();
    await _saveToStorage();

    final uid = _currentUserId;
    if (uid != null) {
      await _firestoreService.saveTransaction(uid, item);
    }
  }

  Future<void> addIncome({
    required String title,
    required double amount,
    String? category,
    String? account,
    required DateTime date,
  }) async {
    final cat = (category != null && category.trim().isNotEmpty) ? category.trim() : 'Salary';
    final resolvedTitle = title.trim().isEmpty ? cat : title.trim();
    final item = ExpenseItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: resolvedTitle,
      amount: amount,
      category: cat,
      account: 'Cash',
      type: 'income',
      date: date,
    );
    _transactions.insert(0, item);
    notifyListeners();
    await _saveToStorage();

    final uid = _currentUserId;
    if (uid != null) {
      await _firestoreService.saveTransaction(uid, item);
    }
  }

  Future<void> transferFunds({
    required String fromAccount,
    required String toAccount,
    required double amount,
    String? note,
    required DateTime date,
  }) async {
    final outItem = ExpenseItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: note?.isNotEmpty == true
          ? 'Transfer to $toAccount: $note'
          : 'Transfer to $toAccount',
      amount: amount,
      category: 'Transfer',
      account: fromAccount,
      type: 'expense',
      date: date,
    );
    final inItem = ExpenseItem(
      id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
      title: note?.isNotEmpty == true
          ? 'Transfer from $fromAccount: $note'
          : 'Transfer from $fromAccount',
      amount: amount,
      category: 'Transfer',
      account: toAccount,
      type: 'income',
      date: date,
    );

    _transactions.insert(0, outItem);
    _transactions.insert(0, inItem);
    notifyListeners();
    await _saveToStorage();

    final uid = _currentUserId;
    if (uid != null) {
      await _firestoreService.saveTransaction(uid, outItem);
      await _firestoreService.saveTransaction(uid, inItem);
    }
  }

  double getAccountIncome([String? account]) => totalCredit > 0 ? totalCredit : _monthlyBudget;

  Future<void> updateMonthlyBudget(double newBudget) async {
    if (newBudget <= 0) {
      _monthlyBudget = 0.0;
    } else {
      _monthlyBudget = newBudget;
    }
    notifyListeners();
    await _saveToStorage();

    final uid = _currentUserId;
    if (uid != null) {
      await _firestoreService.saveUserSettings(uid, monthlyBudget: _monthlyBudget);
    }
  }

  Future<void> updateIncome(double income, {String? account}) async {
    await updateMonthlyBudget(income);
  }

  Future<void> updateExpense({
    required String id,
    required String title,
    required double amount,
    required String category,
    String? account,
    String? needWant,
    required DateTime date,
  }) async {
    final index = _transactions.indexWhere((e) => e.id == id);
    if (index != -1) {
      final oldItem = _transactions[index];
      final updatedItem = ExpenseItem(
        id: id,
        title: title.trim().isEmpty ? category : title.trim(),
        amount: amount,
        category: category,
        account: 'Cash',
        type: oldItem.type,
        needWant: needWant ?? oldItem.needWant,
        date: date,
      );
      _transactions[index] = updatedItem;
      notifyListeners();
      await _saveToStorage();

      final uid = _currentUserId;
      if (uid != null) {
        await _firestoreService.saveTransaction(uid, updatedItem);
      }
    }
  }

  Future<void> deleteExpense(String id) async {
    _transactions.removeWhere((e) => e.id == id);
    notifyListeners();
    await _saveToStorage();

    final uid = _currentUserId;
    if (uid != null) {
      await _firestoreService.deleteTransaction(uid, id);
    }
  }

  Future<void> deleteTransactionsForCategory(String category, {String? type}) async {
    final toDelete = _transactions.where((e) {
      final matches = e.category.toLowerCase() == category.toLowerCase();
      if (!matches) return false;
      if (type != null) {
        return e.type.toLowerCase() == type.toLowerCase();
      }
      return true;
    }).toList();

    _transactions.removeWhere((e) => toDelete.contains(e));
    notifyListeners();
    await _saveToStorage();

    final uid = _currentUserId;
    if (uid != null) {
      for (final item in toDelete) {
        await _firestoreService.deleteTransaction(uid, item.id);
      }
    }
  }

  Future<void> resetCategoryIncome(String category) async {
    await deleteTransactionsForCategory(category, type: 'income');
  }

  Future<void> clearAllExpenses() async {
    _transactions.clear();
    notifyListeners();
    await _saveToStorage();

    final uid = _currentUserId;
    if (uid != null) {
      await _firestoreService.clearAllTransactions(uid);
    }
  }

  // -------------------------------------------------------------
  // Storage (Local Persistence & Cache)
  // -------------------------------------------------------------
  Future<void> _saveLocalCacheOnly() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _transactions.map((e) => e.toJson()).toList();
      final uExpensesKey = _userKey(_expensesKey);
      await prefs.setString(uExpensesKey, jsonEncode(list));
      await prefs.setString(_expensesKey, jsonEncode(list));
    } catch (e) {
      debugPrint('Error saving local cache: $e');
    }
  }
  String _userKey(String baseKey) {
    try {
      if (Firebase.apps.isNotEmpty) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null && user.uid.isNotEmpty) {
          return '${baseKey}_${user.uid}';
        }
      }
    } catch (_) {}
    return baseKey;
  }

  Future<void> loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uBudgetKey = _userKey(_budgetKey);
      final uCatBudgetKey = _userKey(_categoryBudgetsKey);
      final uNeedWantKey = _userKey(_categoryNeedWantKey);
      final uExpensesKey = _userKey(_expensesKey);

      final savedBudget = prefs.getDouble(uBudgetKey) ?? prefs.getDouble(_budgetKey);
      if (savedBudget != null) {
        _monthlyBudget = savedBudget;
      }

      final savedCatBudgets = prefs.getString(uCatBudgetKey) ?? prefs.getString(_categoryBudgetsKey);
      if (savedCatBudgets != null && savedCatBudgets.isNotEmpty) {
        try {
          final Map<String, dynamic> decoded = jsonDecode(savedCatBudgets);
          _categoryBudgets = decoded.map(
            (k, v) => MapEntry(k, (v as num).toDouble()),
          );
        } catch (_) {
          _categoryBudgets = {};
        }
      }

      final savedNeedWant = prefs.getString(uNeedWantKey) ?? prefs.getString(_categoryNeedWantKey);
      if (savedNeedWant != null && savedNeedWant.isNotEmpty) {
        try {
          final Map<String, dynamic> decoded = jsonDecode(savedNeedWant);
          final map = decoded.map((k, v) => MapEntry(k, v.toString()));
          CategoryData.loadCustomCategoryNeedWant(map);
        } catch (_) {}
      }

      final savedJson = prefs.getString(uExpensesKey) ?? prefs.getString(_expensesKey);
      if (savedJson != null && savedJson.isNotEmpty) {
        try {
          final List<dynamic> decoded = jsonDecode(savedJson);
          final loaded = decoded
              .map((e) => ExpenseItem.fromJson(e as Map<String, dynamic>))
              .toList();
          _transactions = loaded;

          // Apply custom category classifications to loaded transactions if any exist
          if (CategoryData.customCategoryNeedWantMap.isNotEmpty) {
            for (int i = 0; i < _transactions.length; i++) {
              final catLower = _transactions[i].category.toLowerCase();
              if (CategoryData.customCategoryNeedWantMap.containsKey(catLower)) {
                final customTag = CategoryData.customCategoryNeedWantMap[catLower]!;
                if (_transactions[i].needWant != customTag) {
                  _transactions[i] = _transactions[i].copyWith(needWant: customTag);
                }
              }
            }
          }
        } catch (e) {
          debugPrint('Error loading saved transactions: $e');
        }
      }
    } catch (e) {
      debugPrint('Error loading storage: $e');
    } finally {
      notifyListeners();
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _transactions.map((e) => e.toJson()).toList();
      final uExpensesKey = _userKey(_expensesKey);
      final uCatBudgetKey = _userKey(_categoryBudgetsKey);
      final uNeedWantKey = _userKey(_categoryNeedWantKey);
      final uBudgetKey = _userKey(_budgetKey);

      await prefs.setString(uExpensesKey, jsonEncode(list));
      await prefs.setString(_expensesKey, jsonEncode(list));

      await prefs.setString(uCatBudgetKey, jsonEncode(_categoryBudgets));
      await prefs.setString(_categoryBudgetsKey, jsonEncode(_categoryBudgets));

      await prefs.setString(uNeedWantKey, jsonEncode(CategoryData.customCategoryNeedWantMap));
      await prefs.setString(_categoryNeedWantKey, jsonEncode(CategoryData.customCategoryNeedWantMap));

      await prefs.setDouble(uBudgetKey, _monthlyBudget);
      await prefs.setDouble(_budgetKey, _monthlyBudget);
    } catch (e) {
      debugPrint('Error saving to storage: $e');
    }
  }
}
