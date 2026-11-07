class ExpenseItem {
  final String id;
  final String title;
  final double amount;
  final String category;
  final String account; // 'Personal', 'Cash', 'Checking', 'Savings'
  final String type; // 'expense', 'income', 'transfer'
  final String needWant; // 'need' (compulsory) or 'want' (not necessary)
  final DateTime date;

  const ExpenseItem({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    this.account = 'Cash',
    this.type = 'expense',
    this.needWant = 'need',
    required this.date,
  });

  bool get isNeed => needWant.toLowerCase() == 'need';
  bool get isWant => needWant.toLowerCase() == 'want';
  String get needWantLabel => isNeed ? 'Need (Compulsory)' : 'Want (Not Necessary)';

  ExpenseItem copyWith({
    String? id,
    String? title,
    double? amount,
    String? category,
    String? account,
    String? type,
    String? needWant,
    DateTime? date,
  }) {
    return ExpenseItem(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      account: account ?? this.account,
      type: type ?? this.type,
      needWant: needWant ?? this.needWant,
      date: date ?? this.date,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'category': category,
        'account': account,
        'type': type,
        'needWant': needWant,
        'date': date.toIso8601String(),
      };

  factory ExpenseItem.fromJson(Map<String, dynamic> json) => ExpenseItem(
        id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: json['title'] as String? ?? 'Expense',
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
        category: json['category'] as String? ?? 'General',
        account: json['account'] as String? ?? 'Cash',
        type: json['type'] as String? ?? 'expense',
        needWant: json['needWant'] as String? ?? 'need',
        date: json['date'] != null ? DateTime.parse(json['date'] as String) : DateTime.now(),
      );
}

// Backwards compatibility alias
typedef TransactionModel = ExpenseItem;
