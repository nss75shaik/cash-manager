import 'package:flutter_test/flutter_test.dart';
import 'package:expense/models/transaction_model.dart';
import 'package:expense/services/export_service.dart';

void main() {
  group('ExportService Tests', () {
    final sampleTransactions = [
      ExpenseItem(
        id: '1',
        title: 'Salary Deposit',
        amount: 50000.0,
        category: 'Salary',
        account: 'Cash',
        type: 'income',
        needWant: 'need',
        date: DateTime(2026, 11, 1),
      ),
      ExpenseItem(
        id: '2',
        title: 'Monthly Grocery & Milk',
        amount: 4500.0,
        category: 'Food',
        account: 'Cash',
        type: 'expense',
        needWant: 'need',
        date: DateTime(2026, 11, 2),
      ),
      ExpenseItem(
        id: '3',
        title: 'Movie Tickets & Dinner',
        amount: 1200.0,
        category: 'Entertainment',
        account: 'Cash',
        type: 'expense',
        needWant: 'want',
        date: DateTime(2026, 11, 5),
      ),
    ];

    test('Filter transactions by date range', () {
      final filtered = ExportService.filterTransactions(
        sampleTransactions,
        startDate: DateTime(2026, 11, 2),
        endDate: DateTime(2026, 11, 4),
      );

      expect(filtered.length, 1);
      expect(filtered.first.id, '2');
    });

    test('Generate Excel bytes successfully', () async {
      final exportService = ExportService();
      final bytes = await exportService.generateExcelBytes(
        transactions: sampleTransactions,
        startDate: DateTime(2026, 11, 1),
        endDate: DateTime(2026, 11, 30),
      );

      expect(bytes, isNotNull);
      expect(bytes.isNotEmpty, isTrue);
    });

    test('Generate PDF bytes successfully', () async {
      final exportService = ExportService();
      final bytes = await exportService.generatePdfBytes(
        transactions: sampleTransactions,
        startDate: DateTime(2026, 11, 1),
        endDate: DateTime(2026, 11, 30),
      );

      expect(bytes, isNotNull);
      expect(bytes.isNotEmpty, isTrue);
    });
  });
}
