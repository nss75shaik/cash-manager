enum LoanType {
  lent('I Lent Money (Given)'),
  borrowed('I Borrowed Money (Taken)');

  final String label;
  const LoanType(this.label);
  bool get isLent => this == LoanType.lent;
  bool get isBorrowed => this == LoanType.borrowed;
}

enum LoanStatus {
  active('Active / Pending'),
  settled('Settled / Completed');

  final String label;
  const LoanStatus(this.label);
}

class LoanPayment {
  final String id;
  final double amount;
  final DateTime date;
  final String note;

  const LoanPayment({
    required this.id,
    required this.amount,
    required this.date,
    this.note = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'date': date.toIso8601String(),
        'note': note,
      };

  factory LoanPayment.fromJson(Map<String, dynamic> json) => LoanPayment(
        id: json['id'] as String,
        amount: (json['amount'] as num).toDouble(),
        date: DateTime.parse(json['date'] as String),
        note: json['note'] as String? ?? '',
      );
}

class LoanModel {
  final String id;
  final String personName;
  final String title;
  final double totalAmount;
  final LoanType type;
  final DateTime startDate;
  final DateTime? dueDate;
  final String notes;
  final List<LoanPayment> payments;
  final LoanStatus status;

  const LoanModel({
    required this.id,
    required this.personName,
    required this.title,
    required this.totalAmount,
    required this.type,
    required this.startDate,
    this.dueDate,
    this.notes = '',
    this.payments = const [],
    this.status = LoanStatus.active,
  });

  double get paidAmount {
    return payments.fold(0.0, (sum, p) => sum + p.amount);
  }

  double get remainingAmount {
    final remaining = totalAmount - paidAmount;
    return remaining > 0 ? remaining : 0;
  }

  double get progressPercentage {
    if (totalAmount <= 0) return 1.0;
    final progress = paidAmount / totalAmount;
    return progress.clamp(0.0, 1.0);
  }

  bool get isSettled => remainingAmount <= 0 || status == LoanStatus.settled;

  bool get isOverdue {
    if (isSettled || dueDate == null) return false;
    final today = DateTime.now();
    return dueDate!.isBefore(DateTime(today.year, today.month, today.day));
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'personName': personName,
      'title': title,
      'totalAmount': totalAmount,
      'type': type.name,
      'startDate': startDate.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'notes': notes,
      'payments': payments.map((p) => p.toJson()).toList(),
      'status': status.name,
    };
  }

  factory LoanModel.fromJson(Map<String, dynamic> json) {
    return LoanModel(
      id: json['id'] as String,
      personName: json['personName'] as String? ?? '',
      title: json['title'] as String? ?? '',
      totalAmount: (json['totalAmount'] as num).toDouble(),
      type: LoanType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => LoanType.lent,
      ),
      startDate: DateTime.parse(json['startDate'] as String),
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate'] as String) : null,
      notes: json['notes'] as String? ?? '',
      payments: (json['payments'] as List<dynamic>? ?? [])
          .map((p) => LoanPayment.fromJson(p as Map<String, dynamic>))
          .toList(),
      status: LoanStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => LoanStatus.active,
      ),
    );
  }

  LoanModel copyWith({
    String? id,
    String? personName,
    String? title,
    double? totalAmount,
    LoanType? type,
    DateTime? startDate,
    DateTime? dueDate,
    String? notes,
    List<LoanPayment>? payments,
    LoanStatus? status,
  }) {
    return LoanModel(
      id: id ?? this.id,
      personName: personName ?? this.personName,
      title: title ?? this.title,
      totalAmount: totalAmount ?? this.totalAmount,
      type: type ?? this.type,
      startDate: startDate ?? this.startDate,
      dueDate: dueDate ?? this.dueDate,
      notes: notes ?? this.notes,
      payments: payments ?? this.payments,
      status: status ?? this.status,
    );
  }
}
