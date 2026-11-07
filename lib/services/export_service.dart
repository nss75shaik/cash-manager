import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/transaction_model.dart';
import 'file_saver.dart';

class ExportService {
  static final ExportService _instance = ExportService._internal();
  factory ExportService() => _instance;
  ExportService._internal();

  /// Filters transactions according to the given date range
  static List<ExpenseItem> filterTransactions(
    List<ExpenseItem> transactions, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    if (startDate == null && endDate == null) return transactions;
    return transactions.where((tx) {
      if (startDate != null && tx.date.isBefore(DateTime(startDate.year, startDate.month, startDate.day))) {
        return false;
      }
      if (endDate != null && tx.date.isAfter(DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59))) {
        return false;
      }
      return true;
    }).toList();
  }

  // -------------------------------------------------------------
  // EXCEL GENERATION (.xlsx)
  // -------------------------------------------------------------
  Future<List<int>> generateExcelBytes({
    required List<ExpenseItem> transactions,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final filtered = filterTransactions(transactions, startDate: startDate, endDate: endDate);
    final totalIncome = filtered.where((t) => t.type == 'income').fold(0.0, (s, e) => s + e.amount);
    final totalExpense = filtered.where((t) => t.type == 'expense').fold(0.0, (s, e) => s + e.amount);
    final netSavings = totalIncome - totalExpense;

    final excel = Excel.createExcel();
    final sheetName = 'Expense Statement';
    final sheet = excel[sheetName];
    excel.setDefaultSheet(sheetName);
    excel.delete('Sheet1');

    // Period description
    String periodStr = 'All Time History';
    if (startDate != null && endDate != null) {
      periodStr = '${DateFormat('dd MMM yyyy').format(startDate)} to ${DateFormat('dd MMM yyyy').format(endDate)}';
    } else if (startDate != null) {
      periodStr = 'From ${DateFormat('dd MMM yyyy').format(startDate)}';
    } else if (endDate != null) {
      periodStr = 'Until ${DateFormat('dd MMM yyyy').format(endDate)}';
    }

    // Title & Summary Section
    sheet.appendRow([TextCellValue('CASH MANAGER - FINANCIAL STATEMENT')]);
    sheet.appendRow([TextCellValue('Statement Period:'), TextCellValue(periodStr)]);
    sheet.appendRow([
      TextCellValue('Generated On:'),
      TextCellValue(DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())),
    ]);
    sheet.appendRow([TextCellValue('')]); // Blank row

    // Financial Overview
    sheet.appendRow([TextCellValue('FINANCIAL OVERVIEW')]);
    sheet.appendRow([TextCellValue('Total Inflow (Income):'), DoubleCellValue(totalIncome)]);
    sheet.appendRow([TextCellValue('Total Outflow (Expense):'), DoubleCellValue(totalExpense)]);
    sheet.appendRow([TextCellValue('Net Saved Balance:'), DoubleCellValue(netSavings)]);
    sheet.appendRow([TextCellValue('Total Transactions:'), IntCellValue(filtered.length)]);
    sheet.appendRow([TextCellValue('')]); // Blank row

    // Table Column Headers
    sheet.appendRow([
      TextCellValue('Date'),
      TextCellValue('Type'),
      TextCellValue('Title / Description'),
      TextCellValue('Category'),
      TextCellValue('Classification'),
      TextCellValue('Account'),
      TextCellValue('Amount (INR)'),
    ]);

    // Transaction rows
    for (final tx in filtered) {
      final dateStr = DateFormat('yyyy-MM-dd').format(tx.date);
      final isInc = tx.type.toLowerCase() == 'income';
      final signedAmount = isInc ? tx.amount : -tx.amount;

      sheet.appendRow([
        TextCellValue(dateStr),
        TextCellValue(tx.type.toUpperCase()),
        TextCellValue(tx.title),
        TextCellValue(tx.category),
        TextCellValue(tx.needWant.toUpperCase()),
        TextCellValue(tx.account),
        DoubleCellValue(signedAmount),
      ]);
    }

    final encoded = excel.encode();
    return encoded ?? <int>[];
  }

  /// Generates and downloads the Excel file
  Future<String?> downloadExcel({
    required List<ExpenseItem> transactions,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final bytes = await generateExcelBytes(
      transactions: transactions,
      startDate: startDate,
      endDate: endDate,
    );

    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'CashManager_Statement_$timestamp.xlsx';

    return await saveAndLaunchFile(bytes, fileName);
  }

  // -------------------------------------------------------------
  // PDF GENERATION (.pdf)
  // -------------------------------------------------------------
  Future<Uint8List> generatePdfBytes({
    required List<ExpenseItem> transactions,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final filtered = filterTransactions(transactions, startDate: startDate, endDate: endDate);
    final totalIncome = filtered.where((t) => t.type == 'income').fold(0.0, (s, e) => s + e.amount);
    final totalExpense = filtered.where((t) => t.type == 'expense').fold(0.0, (s, e) => s + e.amount);
    final netSavings = totalIncome - totalExpense;

    final needExpense = filtered.where((t) => t.type == 'expense' && t.isNeed).fold(0.0, (s, e) => s + e.amount);
    final wantExpense = filtered.where((t) => t.type == 'expense' && t.isWant).fold(0.0, (s, e) => s + e.amount);

    String periodStr = 'All Time History';
    if (startDate != null && endDate != null) {
      periodStr = '${DateFormat('dd MMM yyyy').format(startDate)} - ${DateFormat('dd MMM yyyy').format(endDate)}';
    } else if (startDate != null) {
      periodStr = 'From ${DateFormat('dd MMM yyyy').format(startDate)}';
    } else if (endDate != null) {
      periodStr = 'Until ${DateFormat('dd MMM yyyy').format(endDate)}';
    }

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 20),
            padding: const pw.EdgeInsets.only(bottom: 12),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.blueGrey800, width: 2),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'CASH MANAGER',
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue800,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Financial Account Statement',
                      style: const pw.TextStyle(
                        fontSize: 13,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Period: $periodStr',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey800,
                      ),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      'Generated: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(top: 15),
            padding: const pw.EdgeInsets.only(top: 8),
            decoration: const pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 1)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Cash Manager | Secure Cloud Statement',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                ),
                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                ),
              ],
            ),
          );
        },
        build: (pw.Context context) {
          return [
            // Financial KPI Cards
            pw.Row(
              children: [
                _buildKpiCard(
                  title: 'TOTAL INFLOW (CREDIT)',
                  amount: 'Rs. ${totalIncome.toStringAsFixed(2)}',
                  color: PdfColors.green800,
                  bgColor: PdfColors.green50,
                ),
                pw.SizedBox(width: 12),
                _buildKpiCard(
                  title: 'TOTAL OUTFLOW (DEBIT)',
                  amount: 'Rs. ${totalExpense.toStringAsFixed(2)}',
                  color: PdfColors.red800,
                  bgColor: PdfColors.red50,
                ),
                pw.SizedBox(width: 12),
                _buildKpiCard(
                  title: 'NET SAVED BALANCE',
                  amount: 'Rs. ${netSavings.toStringAsFixed(2)}',
                  color: netSavings >= 0 ? PdfColors.blue800 : PdfColors.orange800,
                  bgColor: netSavings >= 0 ? PdfColors.blue50 : PdfColors.orange50,
                ),
              ],
            ),
            pw.SizedBox(height: 14),

            // Budget Purpose Breakdown (Needs vs Wants)
            if (totalExpense > 0) ...[
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    pw.Text(
                      'Compulsory Needs: Rs. ${needExpense.toStringAsFixed(2)} (${(needExpense / totalExpense * 100).toStringAsFixed(1)}%)',
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800),
                    ),
                    pw.Text(
                      'Discretionary Wants: Rs. ${wantExpense.toStringAsFixed(2)} (${(wantExpense / totalExpense * 100).toStringAsFixed(1)}%)',
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),
            ],

            // Transactions Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'TRANSACTION DETAILS (${filtered.length})',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blueGrey900,
                  ),
                ),
                pw.Text(
                  'Currency: INR (Rs.)',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                ),
              ],
            ),
            pw.SizedBox(height: 8),

            // Transactions Table
            if (filtered.isEmpty)
              pw.Container(
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.all(24),
                child: pw.Text(
                  'No transactions recorded for this period.',
                  style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 12),
                ),
              )
            else
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                columnWidths: {
                  0: const pw.FixedColumnWidth(65), // Date
                  1: const pw.FixedColumnWidth(55), // Type
                  2: const pw.FlexColumnWidth(3),   // Description
                  3: const pw.FlexColumnWidth(2),   // Category
                  4: const pw.FixedColumnWidth(50), // Purpose
                  5: const pw.FixedColumnWidth(75), // Amount
                },
                children: [
                  // Table Header Row
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.blue800),
                    children: [
                      _buildHeaderCell('Date'),
                      _buildHeaderCell('Type'),
                      _buildHeaderCell('Description'),
                      _buildHeaderCell('Category'),
                      _buildHeaderCell('Purpose'),
                      _buildHeaderCell('Amount', align: pw.TextAlign.right),
                    ],
                  ),
                  // Table Data Rows
                  ...filtered.asMap().entries.map((entry) {
                    final index = entry.key;
                    final tx = entry.value;
                    final isIncome = tx.type.toLowerCase() == 'income';
                    final rowBg = index % 2 == 0 ? PdfColors.white : PdfColors.grey50;
                    final dateStr = DateFormat('dd/MM/yy').format(tx.date);

                    return pw.TableRow(
                      decoration: pw.BoxDecoration(color: rowBg),
                      children: [
                        _buildDataCell(dateStr),
                        _buildDataCell(
                          tx.type.toUpperCase(),
                          color: isIncome ? PdfColors.green800 : PdfColors.red800,
                          isBold: true,
                        ),
                        _buildDataCell(tx.title),
                        _buildDataCell(tx.category),
                        _buildDataCell(tx.needWant.toUpperCase()),
                        _buildDataCell(
                          '${isIncome ? '+' : '-'}Rs. ${tx.amount.toStringAsFixed(2)}',
                          align: pw.TextAlign.right,
                          color: isIncome ? PdfColors.green800 : PdfColors.red800,
                          isBold: true,
                        ),
                      ],
                    );
                  }),
                ],
              ),
          ];
        },
      ),
    );

    return await pdf.save();
  }

  static pw.Widget _buildHeaderCell(String text, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
      ),
    );
  }

  static pw.Widget _buildDataCell(
    String text, {
    pw.TextAlign align = pw.TextAlign.left,
    PdfColor color = PdfColors.grey900,
    bool isBold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 9,
          color: color,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static pw.Widget _buildKpiCard({
    required String title,
    required String amount,
    required PdfColor color,
    required PdfColor bgColor,
  }) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: pw.BoxDecoration(
          color: bgColor,
          borderRadius: pw.BorderRadius.circular(6),
          border: pw.Border.all(color: color, width: 0.8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: color,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              amount,
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Generates and downloads the PDF file to the device
  Future<String?> downloadPdf({
    required List<ExpenseItem> transactions,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final bytes = await generatePdfBytes(
      transactions: transactions,
      startDate: startDate,
      endDate: endDate,
    );

    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'CashManager_Statement_$timestamp.pdf';

    return await saveAndLaunchFile(bytes, fileName);
  }

  /// Interactive preview or direct print dialog
  Future<void> previewOrPrintPdf({
    required List<ExpenseItem> transactions,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    await Printing.layoutPdf(
      name: 'CashManager_Statement.pdf',
      onLayout: (PdfPageFormat format) async {
        return await generatePdfBytes(
          transactions: transactions,
          startDate: startDate,
          endDate: endDate,
        );
      },
    );
  }

  /// Native share PDF file
  Future<void> sharePdf({
    required List<ExpenseItem> transactions,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final bytes = await generatePdfBytes(
      transactions: transactions,
      startDate: startDate,
      endDate: endDate,
    );
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'CashManager_Statement.pdf',
    );
  }
}
