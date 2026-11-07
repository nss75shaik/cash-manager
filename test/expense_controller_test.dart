import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:expense/controllers/expense_controller.dart';
import 'package:expense/models/category_data.dart';
import 'package:expense/models/transaction_model.dart';

void main() {
  final sampleItems = [
    ExpenseItem(
      id: '1',
      title: 'Vegetables & Groceries',
      amount: 850.0,
      category: 'Food',
      account: 'Cash',
      type: 'expense',
      needWant: 'need',
      date: DateTime(2026, 11, 1),
    ),
    ExpenseItem(
      id: '2',
      title: 'Supermarket Supplies',
      amount: 1450.0,
      category: 'Food',
      account: 'Cash',
      type: 'expense',
      needWant: 'need',
      date: DateTime(2026, 11, 2),
    ),
    ExpenseItem(
      id: '3',
      title: 'Restaurant Dinner',
      amount: 1200.0,
      category: 'Food',
      account: 'Cash',
      type: 'expense',
      needWant: 'need',
      date: DateTime(2026, 11, 3),
    ),
    ExpenseItem(
      id: '4',
      title: 'House Rent',
      amount: 12000.0,
      category: 'Home',
      account: 'Cash',
      type: 'expense',
      needWant: 'need',
      date: DateTime(2026, 11, 4),
    ),
    ExpenseItem(
      id: '5',
      title: 'Snack & Tea',
      amount: 120.0,
      category: 'Other',
      account: 'Cash',
      type: 'expense',
      needWant: 'want',
      date: DateTime(2026, 11, 5),
    ),
  ];

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'mvc_monthly_budget': 25000.0,
      'mvc_expenses_list': jsonEncode(sampleItems.map((e) => e.toJson()).toList()),
    });
    CategoryData.resetCustomClassifications();
  });

  group('ExpenseController Tests', () {
    test('Initial controller budget and sample expenses deduction test', () async {
      final controller = ExpenseController();
      await controller.initialized;

      // Default budget is 25000
      expect(controller.monthlyBudget, 25000.0);

      // Sample data items: 850 + 1450 + 1200 + 12000 + 120 = 15620
      expect(controller.totalSpent, 15620.0);

      // Remaining budget = 25000 - 15620 = 9380
      expect(controller.remainingAmount, 9380.0);
    });

    test('Fix / Update Monthly Budget', () async {
      final controller = ExpenseController();
      await controller.initialized;

      await controller.updateMonthlyBudget(30000.0);
      expect(controller.monthlyBudget, 30000.0);
      expect(controller.remainingAmount, 30000.0 - controller.totalSpent);
    });

    test('Add Vegetable Expense and deduct from budget', () async {
      final controller = ExpenseController();
      await controller.initialized;
      final initialTotalSpent = controller.totalSpent;
      final initialRemaining = controller.remainingAmount;

      await controller.addExpense(
        title: 'Fresh Tomatoes & Spinach',
        amount: 250.0,
        category: 'Food',
        date: DateTime.now(),
      );

      // Total spent should increase by 250
      expect(controller.totalSpent, initialTotalSpent + 250.0);

      // Remaining should decrease by 250
      expect(controller.remainingAmount, initialRemaining - 250.0);
    });

    test('Add Electricity Bill Expense and deduct from budget', () async {
      final controller = ExpenseController();
      await controller.initialized;
      final initialRemaining = controller.remainingAmount;

      await controller.addExpense(
        title: 'Electricity Bill Payment',
        amount: 1500.0,
        category: 'Bills',
        date: DateTime.now(),
      );

      expect(controller.remainingAmount, initialRemaining - 1500.0);
    });

    test('Delete an expense and restore remaining balance', () async {
      final controller = ExpenseController();
      await controller.initialized;
      final initialSpent = controller.totalSpent;
      final initialRemaining = controller.remainingAmount;

      // Add a test expense to delete
      await controller.addExpense(
        title: 'Temporary Test Expense',
        amount: 500.0,
        category: 'Bills',
        date: DateTime.now(),
      );

      final addedId = controller.expenses.first.id;
      expect(controller.totalSpent, initialSpent + 500.0);

      // Delete the expense
      await controller.deleteExpense(addedId);
      expect(controller.totalSpent, initialSpent);
      expect(controller.remainingAmount, initialRemaining);
    });

    test('Clear all expenses', () async {
      final controller = ExpenseController();
      await controller.initialized;

      await controller.clearAllExpenses();
      expect(controller.expenses.isEmpty, true);
      expect(controller.totalSpent, 0.0);
      expect(controller.remainingAmount, controller.monthlyBudget);
    });

    test('Need vs Want purpose classification test', () async {
      final controller = ExpenseController();
      await controller.initialized;

      // Sample data:
      // Need: 850 + 1450 + 1200 + 12000 = 15500
      // Want: 120
      // Total: 15620
      expect(controller.currentNeedExpense, 15500.0);
      expect(controller.currentWantExpense, 120.0);
      expect(controller.needPercentage, 15500.0 / 15620.0);
      expect(controller.wantPercentage, 120.0 / 15620.0);

      // Add a Want expense
      await controller.addExpense(
        title: 'Movie Ticket & Popcorn',
        amount: 500.0,
        category: 'Entertainment',
        needWant: 'want',
        date: DateTime.now(),
      );

      // Total spent = 16120, need = 15500, want = 620
      expect(controller.totalSpent, 16120.0);
      expect(controller.currentNeedExpense, 15500.0);
      expect(controller.currentWantExpense, 620.0);
      expect(controller.needPercentage, 15500.0 / 16120.0);
      expect(controller.wantPercentage, 620.0 / 16120.0);

      // Add a Need expense
      await controller.addExpense(
        title: 'Medicines',
        amount: 300.0,
        category: 'Health',
        needWant: 'need',
        date: DateTime.now(),
      );

      expect(controller.totalSpent, 16420.0);
      expect(controller.currentNeedExpense, 15800.0);
      expect(controller.currentWantExpense, 620.0);
    });

    test('Category Target Budget allocation and location verification', () async {
      final controller = ExpenseController();
      await controller.initialized;

      // Initially no category budget is located (starts clean without auto-split)
      expect(controller.isCategoryBudgetLocated('Food'), false);
      expect(controller.getCategoryBudget('Food'), 0.0);

      // Allocate particular target budget for Food
      await controller.setCategoryBudget('Food', 4000.0);
      expect(controller.isCategoryBudgetLocated('Food'), true);
      expect(controller.getCategoryBudget('Food'), 4000.0);

      // Set new target budget for Beauty
      await controller.setCategoryBudget('Beauty', 3500.0);
      expect(controller.isCategoryBudgetLocated('Beauty'), true);
      expect(controller.getCategoryBudget('Beauty'), 3500.0);

      // Case-insensitive lookup
      expect(controller.getCategoryBudget('beauty'), 3500.0);

      // Check allocated and unallocated counts
      expect(controller.allocatedCategoriesCount, 2);
      expect(controller.unallocatedCategoriesCount, CategoryData.allExpenseCategories.length - 2);

      // Clear budget for Beauty
      await controller.clearCategoryBudget('Beauty');
      expect(controller.isCategoryBudgetLocated('Beauty'), false);
      expect(controller.getCategoryBudget('Beauty'), 0.0);
    });

    test('Updating budget amount does NOT automatically split into categories and allows user to allocate particular amounts', () async {
      final controller = ExpenseController();
      await controller.initialized;
      await controller.clearAllBudgets();
      expect(controller.categoryBudgetsMap.isEmpty, true);

      // Add a budget amount
      await controller.updateMonthlyBudget(30000.0);
      expect(controller.monthlyBudget, 30000.0);

      // Verify it did NOT auto-split into categories like Car, Food, etc.
      expect(controller.getCategoryBudget('Car'), 0.0);
      expect(controller.getCategoryBudget('Food'), 0.0);
      expect(controller.allocatedCategoriesCount, 0);

      // User allocates particular amounts to each category
      await controller.setCategoryBudget('Car', 3500.0);
      await controller.setCategoryBudget('Food', 5000.0);

      expect(controller.getCategoryBudget('Car'), 3500.0);
      expect(controller.getCategoryBudget('Food'), 5000.0);
      expect(controller.totalCategoryBudgetsSum, 8500.0);
      expect(controller.allocatedCategoriesCount, 2);
    });

    test('User can classify category into Need and Want, updating existing and new transactions', () async {
      final controller = ExpenseController();
      await controller.initialized;

      // Initially Food category is classified as 'need'
      expect(controller.getCategoryClassification('Food'), 'need');
      final initialFoodTxs = controller.getCategoryTransactions('Food');
      expect(initialFoodTxs.length, 3);

      // User reclassifies Food as WANT
      await controller.setCategoryClassification('Food', 'want');

      // CategoryData and controller should now report 'want'
      expect(controller.getCategoryClassification('Food'), 'want');
      expect(CategoryData.getCategoryNeedWant('Food'), 'want');
      expect(CategoryData.getCategory('Food').defaultNeedWant, 'want');

      // Existing transactions for Food should now be updated to 'want'
      final updatedFoodTxs = controller.getCategoryTransactions('Food');
      expect(updatedFoodTxs.every((tx) => tx.needWant == 'want'), true);

      // Current need and want totals should reflect the user's reclassification
      // Need: 12000 (Home). Want: 3500 (Food) + 120 (Other) = 3620
      expect(controller.currentNeedExpense, 12000.0);
      expect(controller.currentWantExpense, 3620.0);

      // Adding new Food expense without explicit needWant should adopt the user's 'want' classification
      await controller.addExpense(
        title: 'Restaurant Dinner',
        amount: 800.0,
        category: 'Food',
        date: DateTime.now(),
      );
      final latestTx = controller.expenses.first;
      expect(latestTx.title, 'Restaurant Dinner');
      expect(latestTx.needWant, 'want');

      // Reclassify back to NEED
      await controller.setCategoryClassification('Food', 'need');
      expect(controller.getCategoryClassification('Food'), 'need');
      final restoredFoodTxs = controller.getCategoryTransactions('Food');
      expect(restoredFoodTxs.every((tx) => tx.needWant == 'need'), true);
    });

    test('Last entered data appears immediately and persists in SharedPreferences', () async {
      final controller = ExpenseController();
      await controller.initialized;

      await controller.addExpense(
        title: 'Special Organic Vegetables',
        amount: 350.0,
        category: 'Food',
        date: DateTime.now(),
      );

      // Verify it appears in lastEnteredTransaction immediately
      expect(controller.lastEnteredTransaction?.title, 'Special Organic Vegetables');
      expect(controller.lastEnteredTransaction?.amount, 350.0);
      expect(controller.recentTransactions.first.title, 'Special Organic Vegetables');

      // Verify persistence in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final savedStr = prefs.getString('mvc_expenses_list');
      expect(savedStr != null, true);
      expect(savedStr!.contains('Special Organic Vegetables'), true);

      // Verify loading into a new controller preserves the last entered data
      final controller2 = ExpenseController();
      await controller2.initialized;
      expect(controller2.lastEnteredTransaction?.title, 'Special Organic Vegetables');
      expect(controller2.lastEnteredTransaction?.amount, 350.0);
    });
  });
}
