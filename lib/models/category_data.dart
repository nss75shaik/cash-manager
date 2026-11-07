import 'package:flutter/material.dart';

class SimpleCategory {
  final String name;
  final IconData icon;
  final Color color;
  final String defaultNeedWant; // 'need' (compulsory) or 'want' (not necessary)
  final bool isExpense;

  const SimpleCategory(
    this.name,
    this.icon,
    this.color, {
    this.defaultNeedWant = 'need',
    this.isExpense = true,
  });
}

class CategoryData {
  // 1. All 19 Expense Categories
  static const List<SimpleCategory> expenseCategories = [
    SimpleCategory('Baby', Icons.child_care, Color(0xFF5D4037), defaultNeedWant: 'need'),
    SimpleCategory('Beauty', Icons.local_florist, Color(0xFFC2185B), defaultNeedWant: 'want'),
    SimpleCategory('Bills', Icons.receipt_long, Color(0xFF263238), defaultNeedWant: 'need'),
    SimpleCategory('Car', Icons.directions_car, Color(0xFF6A1B9A), defaultNeedWant: 'need'),
    SimpleCategory('Clothing', Icons.checkroom, Color(0xFFEF6C00), defaultNeedWant: 'want'),
    SimpleCategory('Education', Icons.school, Color(0xFF1565C0), defaultNeedWant: 'need'),
    SimpleCategory('Electronics', Icons.devices, Color(0xFF00897B), defaultNeedWant: 'want'),
    SimpleCategory('Entertainment', Icons.movie, Color(0xFF3949AB), defaultNeedWant: 'want'),
    SimpleCategory('Food', Icons.restaurant, Color(0xFFD32F2F), defaultNeedWant: 'need'),
    SimpleCategory('Health', Icons.favorite, Color(0xFFE64A19), defaultNeedWant: 'need'),
    SimpleCategory('Home', Icons.home, Color(0xFF880E4F), defaultNeedWant: 'need'),
    SimpleCategory('Insurance', Icons.verified_user, Color(0xFFF57C00), defaultNeedWant: 'need'),
    SimpleCategory('Shopping', Icons.shopping_cart, Color(0xFF1976D2), defaultNeedWant: 'want'),
    SimpleCategory('Social', Icons.groups, Color(0xFF2E7D32), defaultNeedWant: 'want'),
    SimpleCategory('Sport', Icons.sports_tennis, Color(0xFF558B2F), defaultNeedWant: 'want'),
    SimpleCategory('Tax', Icons.content_cut, Color(0xFFD84315), defaultNeedWant: 'need'),
    SimpleCategory('Telephone', Icons.phone_android, Color(0xFF9E9D24), defaultNeedWant: 'need'),
    SimpleCategory('Transportation', Icons.directions_bus, Color(0xFF0277BD), defaultNeedWant: 'need'),
    SimpleCategory('Other', Icons.more_horiz, Color(0xFF607D8B), defaultNeedWant: 'need'),
  ];

  // 2. All 9 Income Categories
  static const List<SimpleCategory> incomeCategories = [
    SimpleCategory('Salary', Icons.account_balance_wallet, Color(0xFFAD1457), isExpense: false),
    SimpleCategory('Awards', Icons.emoji_events, Color(0xFF1565C0), isExpense: false),
    SimpleCategory('Coupons', Icons.discount, Color(0xFFD32F2F), isExpense: false),
    SimpleCategory('Grants', Icons.volunteer_activism, Color(0xFF00897B), isExpense: false),
    SimpleCategory('Lottery', Icons.confirmation_number, Color(0xFFC62828), isExpense: false),
    SimpleCategory('Refunds', Icons.currency_exchange, Color(0xFF2E7D32), isExpense: false),
    SimpleCategory('Rental', Icons.real_estate_agent, Color(0xFF6A1B9A), isExpense: false),
    SimpleCategory('Sale', Icons.sell, Color(0xFF388E3C), isExpense: false),
    SimpleCategory('Other Income', Icons.monetization_on, Color(0xFF455A64), isExpense: false),
  ];

  // Custom categories list
  static final List<SimpleCategory> _customCategories = [];

  static List<SimpleCategory> get allExpenseCategories => [
    ...expenseCategories.map((c) => getCategory(c.name)),
    ..._customCategories.where((c) => c.isExpense).map((c) => getCategory(c.name)),
  ];

  static List<SimpleCategory> get allIncomeCategories => [
    ...incomeCategories,
    ..._customCategories.where((c) => !c.isExpense),
  ];

  static List<SimpleCategory> get categories => allExpenseCategories;

  static void addCustomCategory(SimpleCategory cat) {
    _customCategories.removeWhere((c) => c.name.toLowerCase() == cat.name.toLowerCase());
    _customCategories.add(cat);
  }

  static void removeCustomCategory(String name) {
    _customCategories.removeWhere((c) => c.name.toLowerCase() == name.toLowerCase());
  }

  static List<SimpleCategory> get customCategories => List.unmodifiable(_customCategories);

  static final Map<String, String> _customCategoryNeedWant = {};

  static Map<String, String> get customCategoryNeedWantMap => Map.unmodifiable(_customCategoryNeedWant);

  static void loadCustomCategoryNeedWant(Map<String, String> map) {
    _customCategoryNeedWant.clear();
    _customCategoryNeedWant.addAll(map);
  }

  static String getCategoryNeedWant(String name) {
    final lower = name.trim().toLowerCase();
    for (final entry in _customCategoryNeedWant.entries) {
      if (entry.key.toLowerCase() == lower) {
        return entry.value;
      }
    }
    for (final c in expenseCategories) {
      if (c.name.toLowerCase() == lower) {
        return c.defaultNeedWant;
      }
    }
    for (final c in _customCategories) {
      if (c.name.toLowerCase() == lower) {
        return c.defaultNeedWant;
      }
    }
    return 'need';
  }

  static void setCategoryNeedWant(String name, String needWant) {
    _customCategoryNeedWant.removeWhere((k, _) => k.toLowerCase() == name.trim().toLowerCase());
    _customCategoryNeedWant[name] = needWant.toLowerCase() == 'want' ? 'want' : 'need';
  }

  static void resetCustomClassifications() {
    _customCategoryNeedWant.clear();
  }

  static SimpleCategory getCategory(String name) {
    final lower = name.trim().toLowerCase();
    final customTag = getCategoryNeedWant(name);
    
    // First search exact match in custom categories
    for (final c in _customCategories) {
      if (c.name.toLowerCase() == lower) {
        return SimpleCategory(
          c.name,
          c.icon,
          c.color,
          defaultNeedWant: customTag,
          isExpense: c.isExpense,
        );
      }
    }

    // Search exact in expense categories
    for (final c in expenseCategories) {
      if (c.name.toLowerCase() == lower) {
        return SimpleCategory(
          c.name,
          c.icon,
          c.color,
          defaultNeedWant: customTag,
          isExpense: c.isExpense,
        );
      }
    }
    // Search exact in income categories
    for (final c in incomeCategories) {
      if (c.name.toLowerCase() == lower) {
        return SimpleCategory(
          c.name,
          c.icon,
          c.color,
          defaultNeedWant: customTag,
          isExpense: c.isExpense,
        );
      }
    }

    // Smart aliases mapping to clean non-overlapping categories
    if (lower.contains('veg') || lower.contains('groc') || lower.contains('food') || lower.contains('dining') || lower.contains('milk') || lower.contains('restaurant')) {
      return getCategory('Food');
    }
    if (lower.contains('elect') || lower.contains('bill') || lower.contains('util') || lower.contains('power') || lower.contains('phone') || lower.contains('tel') || lower.contains('tax') || lower.contains('insurance')) {
      return getCategory('Bills');
    }
    if (lower.contains('rent') || lower.contains('house') || lower.contains('home')) {
      return getCategory('Home');
    }
    if (lower.contains('med') || lower.contains('health') || lower.contains('doctor') || lower.contains('hospital') || lower.contains('pharmacy')) {
      return getCategory('Health');
    }
    if (lower.contains('car') || lower.contains('fuel') || lower.contains('petrol') || lower.contains('diesel') || lower.contains('bus') || lower.contains('train') || lower.contains('transit') || lower.contains('transport')) {
      return getCategory('Transportation');
    }
    if (lower.contains('cloth') || lower.contains('wear') || lower.contains('dress') || lower.contains('shop') || lower.contains('store') || lower.contains('device') || lower.contains('electron') || lower.contains('baby')) {
      return getCategory('Shopping');
    }
    if (lower.contains('movie') || lower.contains('entertain') || lower.contains('sport') || lower.contains('game') || lower.contains('social')) {
      return getCategory('Entertainment');
    }
    if (lower.contains('school') || lower.contains('educat') || lower.contains('book') || lower.contains('course') || lower.contains('tuition')) {
      return getCategory('Education');
    }
    if (lower.contains('beauty') || lower.contains('salon') || lower.contains('spa') || lower.contains('groom')) {
      return getCategory('Beauty');
    }
    if (lower.contains('salary') || lower.contains('wage') || lower.contains('paycheck')) {
      return getCategory('Salary');
    }
    if (lower.contains('sale') || lower.contains('business') || lower.contains('freelance') || lower.contains('profit')) {
      return getCategory('Business / Sale');
    }
    if (lower.contains('award') || lower.contains('grant') || lower.contains('lottery') || lower.contains('bonus') || lower.contains('prize')) {
      return getCategory('Grants & Awards');
    }
    if (lower.contains('refund') || lower.contains('coupon') || lower.contains('cashback') || lower.contains('discount')) {
      return getCategory('Refunds & Cashback');
    }
    if (lower.contains('income')) {
      return getCategory('Other Income');
    }

    return SimpleCategory('Other', Icons.more_horiz, const Color(0xFF607D8B), defaultNeedWant: customTag);
  }
}
