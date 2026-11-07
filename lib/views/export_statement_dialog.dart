import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';

import '../controllers/expense_controller.dart';
import '../services/export_service.dart';

class ExportStatementDialog extends StatefulWidget {
  final ExpenseController controller;

  const ExportStatementDialog({
    super.key,
    required this.controller,
  });

  @override
  State<ExportStatementDialog> createState() => _ExportStatementDialogState();
}

class _ExportStatementDialogState extends State<ExportStatementDialog> {
  String _selectedPeriod = 'this_month'; // 'this_month', 'all_time', 'custom'
  DateTime? _customStart;
  DateTime? _customEnd;
  bool _isExporting = false;
  String _exportStatus = '';

  DateTime? get _startDate {
    final now = DateTime.now();
    if (_selectedPeriod == 'this_month') {
      return DateTime(now.year, now.month, 1);
    }
    if (_selectedPeriod == 'custom') {
      return _customStart;
    }
    return null;
  }

  DateTime? get _endDate {
    final now = DateTime.now();
    if (_selectedPeriod == 'this_month') {
      return DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    }
    if (_selectedPeriod == 'custom') {
      return _customEnd;
    }
    return null;
  }

  Future<void> _handleDownloadExcel() async {
    setState(() {
      _isExporting = true;
      _exportStatus = 'Generating Excel (.xlsx) spreadsheet...';
    });

    try {
      final filePath = await ExportService().downloadExcel(
        transactions: widget.controller.allTransactions,
        startDate: _startDate,
        endDate: _endDate,
      );

      if (!mounted) return;

      final msg = filePath != null
          ? 'Excel file saved successfully to Downloads / Documents!'
          : 'Excel file exported!';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: const Color(0xFF16A34A),
          action: filePath != null
              ? SnackBarAction(
                  label: 'OPEN',
                  textColor: Colors.white,
                  onPressed: () => OpenFilex.open(filePath),
                )
              : null,
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to export Excel: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
          _exportStatus = '';
        });
      }
    }
  }

  Future<void> _handleDownloadPdf() async {
    setState(() {
      _isExporting = true;
      _exportStatus = 'Generating official PDF statement...';
    });

    try {
      final filePath = await ExportService().downloadPdf(
        transactions: widget.controller.allTransactions,
        startDate: _startDate,
        endDate: _endDate,
      );

      if (!mounted) return;

      final msg = filePath != null
          ? 'PDF statement saved successfully to device!'
          : 'PDF statement generated!';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: const Color(0xFFDC2626),
          action: filePath != null
              ? SnackBarAction(
                  label: 'OPEN',
                  textColor: Colors.white,
                  onPressed: () => OpenFilex.open(filePath),
                )
              : null,
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to export PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
          _exportStatus = '';
        });
      }
    }
  }

  Future<void> _handlePreviewPdf() async {
    try {
      await ExportService().previewOrPrintPdf(
        transactions: widget.controller.allTransactions,
        startDate: _startDate,
        endDate: _endDate,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open print/preview: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = ExportService.filterTransactions(
      widget.controller.allTransactions,
      startDate: _startDate,
      endDate: _endDate,
    );
    final totalInflow = filtered.where((t) => t.type == 'income').fold(0.0, (s, e) => s + e.amount);
    final totalOutflow = filtered.where((t) => t.type == 'expense').fold(0.0, (s, e) => s + e.amount);
    final netSavings = totalInflow - totalOutflow;

    final statementText = widget.controller.generateFormattedTextStatement(
      startDate: _startDate,
      endDate: _endDate,
    );
    final csvText = widget.controller.generateStatementCsv(
      startDate: _startDate,
      endDate: _endDate,
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 550, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF0284C7)),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Export Statement',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Download Excel (.xlsx) & PDF (.pdf) Reports',
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Period Selector Chips
              const Text(
                'Select Statement Period',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155)),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ChoiceChip(
                      label: const Text('This Month'),
                      selected: _selectedPeriod == 'this_month',
                      onSelected: (val) {
                        if (val) setState(() => _selectedPeriod = 'this_month');
                      },
                      selectedColor: const Color(0xFF0284C7),
                      labelStyle: TextStyle(
                        color: _selectedPeriod == 'this_month' ? Colors.white : const Color(0xFF334155),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('All Time'),
                      selected: _selectedPeriod == 'all_time',
                      onSelected: (val) {
                        if (val) setState(() => _selectedPeriod = 'all_time');
                      },
                      selectedColor: const Color(0xFF0284C7),
                      labelStyle: TextStyle(
                        color: _selectedPeriod == 'all_time' ? Colors.white : const Color(0xFF334155),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Custom Range'),
                      selected: _selectedPeriod == 'custom',
                      onSelected: (val) async {
                        if (val) {
                          final range = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (range != null) {
                            setState(() {
                              _selectedPeriod = 'custom';
                              _customStart = range.start;
                              _customEnd = range.end;
                            });
                          }
                        }
                      },
                      selectedColor: const Color(0xFF0284C7),
                      labelStyle: TextStyle(
                        color: _selectedPeriod == 'custom' ? Colors.white : const Color(0xFF334155),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (_selectedPeriod == 'custom' && _customStart != null && _customEnd != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Range: ${DateFormat('dd MMM yyyy').format(_customStart!)} - ${DateFormat('dd MMM yyyy').format(_customEnd!)}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF0284C7), fontWeight: FontWeight.bold),
                ),
              ],
              const SizedBox(height: 12),

              // Overview Banner (Inflow, Outflow, Net, Count)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Inflow', style: TextStyle(fontSize: 11, color: Color(0xFF16A34A), fontWeight: FontWeight.bold)),
                          Text('₹${totalInflow.toStringAsFixed(0)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Outflow', style: TextStyle(fontSize: 11, color: Color(0xFFDC2626), fontWeight: FontWeight.bold)),
                          Text('₹${totalOutflow.toStringAsFixed(0)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Net Balance', style: TextStyle(fontSize: 11, color: Color(0xFF0284C7), fontWeight: FontWeight.bold)),
                          Text('₹${netSavings.toStringAsFixed(0)}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: netSavings >= 0 ? const Color(0xFF0284C7) : const Color(0xFFEA580C))),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${filtered.length} txs',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Preview Section
              const Text(
                'Statement Preview',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155)),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      statementText,
                      style: const TextStyle(
                        color: Color(0xFF38BDF8),
                        fontFamily: 'monospace',
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ),

              if (_isExporting) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _exportStatus,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF0284C7), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 14),

              // PRIMARY DOWNLOAD BUTTONS (EXCEL & PDF)
              Row(
                children: [
                  // Download Excel (.xlsx)
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                      ),
                      onPressed: _isExporting ? null : _handleDownloadExcel,
                      icon: const Icon(Icons.table_view_rounded, size: 18),
                      label: const Text(
                        'Download Excel',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Download PDF (.pdf)
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                      ),
                      onPressed: _isExporting ? null : _handleDownloadPdf,
                      icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                      label: const Text(
                        'Download PDF',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // SECONDARY ACTIONS (Preview/Print PDF & Copy CSV)
              Row(
                children: [
                  // Print / Preview PDF
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        side: const BorderSide(color: Color(0xFF0284C7)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _isExporting ? null : _handlePreviewPdf,
                      icon: const Icon(Icons.print_rounded, size: 16, color: Color(0xFF0284C7)),
                      label: const Text(
                        'Preview / Print',
                        style: TextStyle(color: Color(0xFF0284C7), fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Copy CSV Data
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        side: const BorderSide(color: Color(0xFF64748B)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: csvText));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('CSV data copied to clipboard! (Ready for Excel/Sheets)'),
                            backgroundColor: Color(0xFF16A34A),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 16, color: Color(0xFF64748B)),
                      label: const Text(
                        'Copy CSV',
                        style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
