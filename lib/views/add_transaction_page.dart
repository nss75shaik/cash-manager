import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../controllers/expense_controller.dart';
import '../models/category_data.dart';
import '../models/transaction_model.dart';
import '../theme/app_theme.dart';

class AddTransactionPage extends StatefulWidget {
  final ExpenseController controller;
  final String? initialAccount;
  final String? initialType; // 'expense' or 'income'
  final String? initialCategory;
  final ExpenseItem? existingItem;

  const AddTransactionPage({
    super.key,
    required this.controller,
    this.initialAccount,
    this.initialType,
    this.initialCategory,
    this.existingItem,
  });

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final _amountController = TextEditingController();
  final _titleController = TextEditingController();
  final _amountFocusNode = FocusNode();
  final _sideSearchController = TextEditingController();

  late String _selectedAccount;
  late String _selectedType;
  late String _selectedCategory;
  late String _selectedNeedWant; // 'need' (compulsory) or 'want' (not necessary)
  late DateTime _selectedDate;
  bool _showRecordedEntries = false;
  String _sideFilter = 'all'; // 'all', 'added', 'to_add', 'credit'

  @override
  void initState() {
    super.initState();
    final item = widget.existingItem;
    if (item != null) {
      _amountController.text = item.amount.toStringAsFixed(0);
      _titleController.text = item.title;
      _selectedAccount = 'Cash';
      _selectedType = item.type;
      _selectedCategory = item.category;
      _selectedNeedWant = item.needWant;
      _selectedDate = item.date;
    } else {
      _selectedAccount = 'Cash';
      _selectedType = widget.initialType ?? 'expense';
      _selectedCategory = widget.initialCategory ?? (_selectedType == 'expense' ? 'Food' : 'Salary');
      _selectedNeedWant = CategoryData.getCategory(_selectedCategory).defaultNeedWant;
      _selectedDate = DateTime.now();
      _amountController.text = '';
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    _amountFocusNode.dispose();
    _sideSearchController.dispose();
    super.dispose();
  }

  void _addQuickAmount(double delta) {
    final cur = double.tryParse(_amountController.text) ?? 0;
    setState(() {
      _amountController.text = (cur + delta).toStringAsFixed(0);
    });
  }

  void _onTypeChanged(String newType) {
    setState(() {
      _selectedType = newType;
      if (newType == 'expense') {
        _selectedCategory = 'Food';
        _selectedNeedWant = 'need';
      } else {
        _selectedCategory = 'Salary';
        _selectedNeedWant = 'need';
      }
    });
  }

  void _onCategorySelected(String categoryName) {
    setState(() {
      _selectedCategory = categoryName;
      _selectedNeedWant = CategoryData.getCategory(categoryName).defaultNeedWant;
      final txs = widget.controller.getCategoryTransactions(categoryName, type: _selectedType);
      if (txs.isNotEmpty) {
        _showRecordedEntries = true;
      }
    });
  }

  void _selectCategoryFromSide(BuildContext ctx, String categoryName, {bool closeDrawer = false}) {
    setState(() {
      _selectedCategory = categoryName;
      _selectedNeedWant = CategoryData.getCategory(categoryName).defaultNeedWant;
      final txs = widget.controller.getCategoryTransactions(categoryName, type: _selectedType);
      if (txs.isNotEmpty) {
        _showRecordedEntries = true;
      }
    });
    if (closeDrawer) {
      Navigator.of(ctx).pop();
    }
    _amountFocusNode.requestFocus();
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Selected category: $categoryName'),
          backgroundColor: const Color(0xFF0284C7),
          duration: const Duration(milliseconds: 1200),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showCategoryBreakdownSheet(BuildContext context, String categoryName, String type) {
    final isExpense = type == 'expense';
    final cat = CategoryData.getCategory(categoryName);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) {
          final currentTxs = widget.controller.getCategoryTransactions(categoryName, type: type);
          final currentTotal = widget.controller.getCategoryTotalAmount(categoryName, type: type);

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: cat.color,
                        child: Icon(cat.icon, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cat.name,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                            ),
                            Text(
                              isExpense
                                  ? 'Total Debits: ₹${currentTotal.toStringAsFixed(2)} (${currentTxs.length} record${currentTxs.length == 1 ? '' : 's'})'
                                  : 'Total Credit: +₹${currentTotal.toStringAsFixed(2)} (${currentTxs.length} record${currentTxs.length == 1 ? '' : 's'})',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isExpense ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (currentTxs.isNotEmpty)
                        TextButton.icon(
                          style: TextButton.styleFrom(foregroundColor: const Color(0xFFDC2626)),
                          icon: const Icon(Icons.delete_sweep, size: 18),
                          label: const Text('Delete All', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (dCtx) => AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                title: Text('Reset ${cat.name} ${isExpense ? 'Debits' : 'Credits'}'),
                                content: Text('Delete all ${currentTxs.length} recorded ${isExpense ? 'debits' : 'credits'} for "${cat.name}"?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(dCtx, false), child: const Text('Cancel')),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
                                    onPressed: () => Navigator.pop(dCtx, true),
                                    child: const Text('Clear All', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await widget.controller.deleteTransactionsForCategory(cat.name, type: type);
                              setModalState(() {});
                              setState(() {});
                            }
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 10),

                  // Button to add another debit in this category
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isExpense ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.add_circle_outline, size: 18),
                      label: Text(
                        isExpense ? '+ RECORD ANOTHER ${cat.name.toUpperCase()} DEBIT' : '+ RECORD ANOTHER ${cat.name.toUpperCase()} CREDIT',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        setState(() {
                          _selectedType = type;
                          _selectedCategory = cat.name;
                          _selectedNeedWant = cat.defaultNeedWant;
                          _showRecordedEntries = true;
                        });
                        _amountFocusNode.requestFocus();
                      },
                    ),
                  ),

                  const SizedBox(height: 14),

                  if (currentTxs.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'No ${isExpense ? 'debit' : 'credit'} transactions recorded for ${cat.name} yet',
                          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                        ),
                      ),
                    )
                  else ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Each Amount Added (${currentTxs.length} entries):',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569)),
                        ),
                        const Text(
                          'Includes description & date',
                          style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.55),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: currentTxs.length,
                        itemBuilder: (lCtx, idx) {
                          final item = currentTxs[idx];
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: (isExpense ? const Color(0xFFDC2626) : const Color(0xFF16A34A)).withValues(alpha: 0.12),
                                  child: Icon(
                                    isExpense ? Icons.arrow_upward : Icons.arrow_downward,
                                    size: 16,
                                    color: isExpense ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item.title,
                                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)),
                                            ),
                                          ),
                                          if (isExpense)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                              decoration: BoxDecoration(
                                                color: item.isNeed ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                item.isNeed ? 'NEED' : 'WANT',
                                                style: TextStyle(
                                                  fontSize: 8.5,
                                                  fontWeight: FontWeight.w900,
                                                  color: item.isNeed ? const Color(0xFF15803D) : const Color(0xFFB45309),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Row(
                                        children: [
                                          const Icon(Icons.access_time, size: 12, color: Color(0xFF64748B)),
                                          const SizedBox(width: 3),
                                          Text(
                                            DateFormat('dd MMM yyyy, hh:mm a').format(item.date),
                                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                          ),
                                          const Text(' • ', style: TextStyle(color: Color(0xFFCBD5E1))),
                                          Text(
                                            item.account,
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${isExpense ? '-' : '+'}₹${item.amount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: isExpense ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF0284C7)),
                                  tooltip: 'Edit this debit',
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    setState(() {
                                      _selectedType = item.type;
                                      _selectedCategory = item.category;
                                      _selectedAccount = item.account;
                                      _selectedNeedWant = item.needWant;
                                      _selectedDate = item.date;
                                      _titleController.text = item.title;
                                      _amountController.text = item.amount.toStringAsFixed(item.amount.truncateToDouble() == item.amount ? 0 : 2);
                                      _showRecordedEntries = true;
                                    });
                                    _amountFocusNode.requestFocus();
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFDC2626)),
                                  tooltip: 'Delete this record',
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (delCtx) => AlertDialog(
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        title: const Text('Delete Record'),
                                        content: Text('Delete "${item.title}" of ₹${item.amount.toStringAsFixed(2)}?'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(delCtx, false), child: const Text('Cancel')),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
                                            onPressed: () => Navigator.pop(delCtx, true),
                                            child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await widget.controller.deleteExpense(item.id);
                                      setModalState(() {});
                                      setState(() {});
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            backgroundColor: const Color(0xFFDC2626),
                                            content: Text('Deleted ₹${item.amount.toStringAsFixed(0)} from ${cat.name}'),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDeleteExistingItem() async {
    if (widget.existingItem == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626)),
            SizedBox(width: 8),
            Text('Delete Transaction'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${widget.existingItem!.title}" of ₹${widget.existingItem!.amount.toStringAsFixed(2)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await widget.controller.deleteExpense(widget.existingItem!.id);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFDC2626),
          content: Text('Deleted "${widget.existingItem!.title}" successfully!'),
        ),
      );
    }
  }

  Future<void> _deleteCategoryTransaction(ExpenseItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Entry'),
        content: Text(
          'Delete "${item.title}" (${item.type == 'expense' ? '-' : '+'}₹${item.amount.toStringAsFixed(2)}) from $_selectedCategory?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await widget.controller.deleteExpense(item.id);
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFDC2626),
          content: Text('Deleted ₹${item.amount.toStringAsFixed(0)} from $_selectedCategory'),
        ),
      );
    }
  }

  Future<void> _clearAllCategoryCredits() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.delete_forever, color: Color(0xFFDC2626)),
            const SizedBox(width: 8),
            Text('Reset $_selectedCategory Records'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete all recorded ${_selectedType == 'expense' ? 'expenses' : 'credits'} for "$_selectedCategory"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear All', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await widget.controller.deleteTransactionsForCategory(_selectedCategory, type: _selectedType);
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFDC2626),
          content: Text('All ${_selectedType == 'expense' ? 'expenses' : 'credits'} for $_selectedCategory cleared!'),
        ),
      );
    }
  }

  void _save() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount greater than 0')),
      );
      return;
    }

    final title = _titleController.text.trim().isNotEmpty
        ? _titleController.text.trim()
        : _selectedCategory;

    if (widget.existingItem != null) {
      await widget.controller.updateExpense(
        id: widget.existingItem!.id,
        title: title,
        amount: amount,
        category: _selectedCategory,
        account: _selectedAccount,
        needWant: _selectedNeedWant,
        date: _selectedDate,
      );
    } else {
      if (_selectedType == 'expense') {
        await widget.controller.addExpense(
          title: title,
          amount: amount,
          category: _selectedCategory,
          account: _selectedAccount,
          needWant: _selectedNeedWant,
          date: _selectedDate,
        );
      } else {
        await widget.controller.addIncome(
          title: title,
          amount: amount,
          category: _selectedCategory,
          account: _selectedAccount,
          date: _selectedDate,
        );
      }
    }

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: _selectedType == 'expense'
            ? AppTheme.debitRed
            : AppTheme.creditGreen,
        content: Text(
          '₹${amount.toStringAsFixed(0)} ${_selectedType == 'expense' ? 'Debit' : 'Credit'} recorded successfully!',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isExpense = _selectedType == 'expense';
    final isEditing = widget.existingItem != null;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 780;

    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final categoryTxs = widget.controller.getCategoryTransactions(_selectedCategory, type: _selectedType);
        final addedCount = CategoryData.allExpenseCategories.where((c) {
          return widget.controller.getCategoryTotalAmount(c.name, type: 'expense') > 0;
        }).length;
        final toAddCount = CategoryData.allExpenseCategories.length - addedCount;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0284C7),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              isEditing
                  ? 'Edit Transaction'
                  : (widget.initialCategory != null
                      ? 'Record $_selectedCategory'
                      : (_selectedType == 'expense' ? 'Record - DEBIT' : 'Record + CREDIT')),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            actions: [
              if (!isWide)
                Builder(
                  builder: (btnCtx) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.white.withValues(alpha: 0.18),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: const Icon(Icons.checklist_rtl_rounded, size: 16),
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Added & To Add', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$addedCount',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      onPressed: () {
                        Scaffold.of(btnCtx).openEndDrawer();
                      },
                    ),
                  ),
                ),
              if (isEditing)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.white),
                  tooltip: 'Delete Transaction',
                  onPressed: _confirmDeleteExistingItem,
                ),
            ],
          ),
          endDrawer: isWide
              ? null
              : Drawer(
                  width: (screenWidth * 0.90).clamp(320.0, 460.0),
                  child: SafeArea(
                    child: _buildLedgerSidePanel(context, isEmbedded: false),
                  ),
                ),
          body: SafeArea(
            child: isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: _buildForm(context, isExpense, isEditing, categoryTxs, addedCount, toAddCount),
                      ),
                      Container(
                        width: 370,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          border: Border(left: BorderSide(color: Color(0xFFE2E8F0))),
                        ),
                        child: _buildLedgerSidePanel(context, isEmbedded: true),
                      ),
                    ],
                  )
                : _buildForm(context, isExpense, isEditing, categoryTxs, addedCount, toAddCount),
          ),
        );
      },
    );
  }

  // -------------------------------------------------------------
  // PRIMARY INPUT FORM
  // -------------------------------------------------------------
  Widget _buildForm(
    BuildContext context,
    bool isExpense,
    bool isEditing,
    List<ExpenseItem> categoryTxs,
    int addedCount,
    int toAddCount,
  ) {
    final controller = widget.controller;
    final totalCredit = controller.totalCredit;
    final totalDebit = controller.totalDebit;
    final netBalance = controller.currentBalance;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: [
        // 1. TYPE SELECTOR (Debit vs Credit)
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _onTypeChanged('expense'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isExpense ? const Color(0xFFDC2626) : Colors.transparent,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '- DEBIT (Expense)',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: isExpense ? Colors.white : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () => _onTypeChanged('income'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: !isExpense ? const Color(0xFF16A34A) : Colors.transparent,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '+ CREDIT (Income)',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: !isExpense ? Colors.white : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // 2. INLINE FINANCIAL OVERVIEW & STATUS STRIP (What is already added vs to add)
        Builder(
          builder: (stripCtx) => Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFCBD5E1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.checklist_rtl_rounded, size: 16, color: Color(0xFF0284C7)),
                        SizedBox(width: 6),
                        Text(
                          'Ledger Summary',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: () {
                        Scaffold.of(stripCtx).openEndDrawer();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: const [
                            Text(
                              'Open Side Ledger',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward, size: 11, color: Color(0xFF0284C7)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    // Salary / Credit
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('CREDIT (Salary)', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF166534))),
                            const SizedBox(height: 2),
                            Text(
                              '+₹${totalCredit > 0 ? totalCredit.toStringAsFixed(0) : controller.monthlyBudget.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF16A34A)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Debits Added
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('DEBITS ADDED', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF991B1B))),
                            const SizedBox(height: 2),
                            Text(
                              '-₹${totalDebit.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFFDC2626)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Net Balance
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F9FF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFBAE6FD)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('BALANCE LEFT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF0369A1))),
                            const SizedBox(height: 2),
                            Text(
                              '₹${netBalance.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0284C7)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (isExpense) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '$addedCount ADDED',
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF15803D)),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '$toAddCount TO ADD',
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFFB45309)),
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        'Tap any category to record',
                        style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // 3. CATEGORY SELECTOR (Visually shows which are added with amount and which are to add)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isExpense ? 'Select Expense Category' : 'Select Income Category',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
            ),
            Row(
              children: [
                Text(
                  _selectedCategory,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    color: isExpense ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                  ),
                ),
                const SizedBox(width: 6),
                CircleAvatar(
                  radius: 8,
                  backgroundColor: CategoryData.getCategory(_selectedCategory).color,
                  child: Icon(CategoryData.getCategory(_selectedCategory).icon, color: Colors.white, size: 10),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: (isExpense ? CategoryData.allExpenseCategories : CategoryData.allIncomeCategories).map((cat) {
            final isSelected = _selectedCategory == cat.name;
            final spent = isExpense
                ? widget.controller.getCategoryTotalAmount(cat.name, type: 'expense')
                : widget.controller.getCategoryTotalAmount(cat.name, type: 'income');
            final hasAdded = spent > 0;
            final targetBudget = isExpense ? widget.controller.getCategoryBudget(cat.name) : 0.0;

            return ChoiceChip(
              avatar: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    cat.icon,
                    size: 16,
                    color: isSelected ? Colors.white : cat.color,
                  ),
                  if (hasAdded && !isSelected)
                    Positioned(
                      right: -3,
                      top: -3,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF16A34A),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              label: Text(
                hasAdded
                    ? '${cat.name} (₹${spent.toStringAsFixed(0)})'
                    : (targetBudget > 0 ? '${cat.name} (T: ₹${targetBudget.toStringAsFixed(0)})' : cat.name),
              ),
              selected: isSelected,
              onSelected: (val) {
                if (val) _onCategorySelected(cat.name);
              },
              selectedColor: const Color(0xFF0284C7),
              backgroundColor: hasAdded ? const Color(0xFFF0FDF4) : Colors.white,
              side: BorderSide(
                color: isSelected
                    ? const Color(0xFF0284C7)
                    : (hasAdded ? const Color(0xFF86EFAC) : const Color(0xFFCBD5E1)),
                width: hasAdded ? 1.2 : 1,
              ),
              labelStyle: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (hasAdded ? const Color(0xFF15803D) : const Color(0xFF1E293B)),
                fontWeight: isSelected || hasAdded ? FontWeight.bold : FontWeight.w500,
                fontSize: 12,
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 12),

        // 4. CATEGORY STATUS & BUDGET INDICATOR
        Builder(
          builder: (ctx) {
            final alreadyRecorded = widget.controller.getCategoryTotalAmount(_selectedCategory, type: _selectedType);
            final targetBudget = widget.controller.getCategoryBudget(_selectedCategory);
            final isOver = targetBudget > 0 && alreadyRecorded > targetBudget;
            final saved = targetBudget > 0 ? (targetBudget - alreadyRecorded) : 0.0;

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isOver
                    ? const Color(0xFFFEF2F2)
                    : (targetBudget > 0 ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC)),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isOver
                      ? const Color(0xFFFECACA)
                      : (targetBudget > 0 ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0)),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isOver
                                ? Icons.warning_amber_rounded
                                : (alreadyRecorded > 0 ? Icons.check_circle_outline : Icons.info_outline),
                            size: 18,
                            color: isOver
                                ? const Color(0xFFDC2626)
                                : (alreadyRecorded > 0 ? const Color(0xFF16A34A) : const Color(0xFF0284C7)),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            alreadyRecorded > 0
                                ? (isExpense
                                    ? 'Spent in $_selectedCategory: ₹${alreadyRecorded.toStringAsFixed(2)}'
                                    : 'Added in $_selectedCategory: ₹${alreadyRecorded.toStringAsFixed(2)}')
                                : 'No debit added for $_selectedCategory yet',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isOver
                                  ? const Color(0xFFDC2626)
                                  : (alreadyRecorded > 0 ? const Color(0xFF16A34A) : const Color(0xFF0284C7)),
                            ),
                          ),
                        ],
                      ),
                      if (targetBudget > 0 && isExpense)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isOver ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isOver
                                ? 'OVER BY ₹${(alreadyRecorded - targetBudget).toStringAsFixed(0)}'
                                : 'SAVED ₹${saved.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: isOver ? const Color(0xFFDC2626) : const Color(0xFF15803D),
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (targetBudget > 0 && isExpense) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Planned Target: ₹${targetBudget.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                    ),
                  ],
                  if (categoryTxs.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${categoryTxs.length} previous record${categoryTxs.length > 1 ? 's' : ''}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                        ),
                        InkWell(
                          onTap: () => setState(() => _showRecordedEntries = !_showRecordedEntries),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            child: Row(
                              children: [
                                Text(
                                  _showRecordedEntries ? 'Hide Entries' : 'View / Delete Entries',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isExpense ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                                  ),
                                ),
                                Icon(
                                  _showRecordedEntries ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                  size: 16,
                                  color: isExpense ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          },
        ),

        // RECORDED CATEGORY ENTRIES LIST (EXPANDABLE)
        if (_showRecordedEntries && categoryTxs.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recorded in "$_selectedCategory"',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFDC2626),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(Icons.delete_sweep, size: 16),
                      label: const Text('Delete All', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      onPressed: _clearAllCategoryCredits,
                    ),
                  ],
                ),
                const Divider(height: 12, color: Color(0xFFE2E8F0)),
                ...categoryTxs.map((tx) {
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: (isExpense ? const Color(0xFFDC2626) : const Color(0xFF16A34A)).withValues(alpha: 0.12),
                          child: Icon(
                            isExpense ? Icons.arrow_upward : Icons.arrow_downward,
                            size: 14,
                            color: isExpense ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      tx.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                                    ),
                                  ),
                                  if (isExpense)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: tx.isNeed ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      child: Text(
                                        tx.isNeed ? 'NEED' : 'WANT',
                                        style: TextStyle(
                                          fontSize: 8,
                                          fontWeight: FontWeight.w900,
                                          color: tx.isNeed ? const Color(0xFF15803D) : const Color(0xFFB45309),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(Icons.access_time, size: 10, color: Color(0xFF64748B)),
                                  const SizedBox(width: 3),
                                  Text(
                                    DateFormat('dd MMM yyyy, hh:mm a').format(tx.date),
                                    style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                                  ),
                                  const Text(' • ', style: TextStyle(color: Color(0xFFCBD5E1))),
                                  Text(
                                    tx.account,
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${isExpense ? '-' : '+'}₹${tx.amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            color: isExpense ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF0284C7)),
                          tooltip: 'Edit this entry',
                          onPressed: () {
                            setState(() {
                              _titleController.text = tx.title;
                              _amountController.text = tx.amount.toStringAsFixed(tx.amount.truncateToDouble() == tx.amount ? 0 : 2);
                              _selectedAccount = tx.account;
                              _selectedNeedWant = tx.needWant;
                              _selectedDate = tx.date;
                            });
                            _amountFocusNode.requestFocus();
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 17, color: Color(0xFFDC2626)),
                          tooltip: 'Delete this record',
                          onPressed: () => _deleteCategoryTransaction(tx),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],

        const SizedBox(height: 16),

        // 5. AMOUNT FIELD
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'AMOUNT (₹)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isExpense ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                    ),
                  ),
                  if (_amountController.text.isNotEmpty)
                    InkWell(
                      onTap: () => setState(() => _amountController.clear()),
                      child: const Row(
                        children: [
                          Icon(Icons.clear, size: 14, color: Color(0xFF64748B)),
                          SizedBox(width: 2),
                          Text('Clear', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '₹',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: isExpense ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      focusNode: _amountFocusNode,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setState(() {}),
                      autofocus: true,
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
                      decoration: const InputDecoration(
                        hintText: '0',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Quick add chips
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [1, 5, 10, 50, 100, 200, 500, 1000, 2000, 10000].map((amt) {
                  return InkWell(
                    onTap: () => _addQuickAmount(amt.toDouble()),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '+₹$amt',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0284C7),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 6. PURPOSE CLASSIFICATION (NEED vs WANT)
        if (isExpense) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Expense Purpose', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _selectedNeedWant == 'need' ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _selectedNeedWant == 'need' ? 'COMPULSORY' : 'NOT NECESSARY',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: _selectedNeedWant == 'need' ? const Color(0xFF15803D) : const Color(0xFFB45309),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // NEED BUTTON (Compulsory)
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _selectedNeedWant = 'need'),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _selectedNeedWant == 'need' ? const Color(0xFF059669) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedNeedWant == 'need' ? const Color(0xFF059669) : const Color(0xFFCBD5E1),
                        width: _selectedNeedWant == 'need' ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 18,
                              color: _selectedNeedWant == 'need' ? Colors.white : const Color(0xFF059669),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'NEED',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: _selectedNeedWant == 'need' ? Colors.white : const Color(0xFF059669),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Compulsory / Essential\n(Food, Bills, Home, Health)',
                          style: TextStyle(
                            fontSize: 10,
                            height: 1.2,
                            fontWeight: FontWeight.w500,
                            color: _selectedNeedWant == 'need' ? Colors.white70 : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // WANT BUTTON (Not Necessary)
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _selectedNeedWant = 'want'),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _selectedNeedWant == 'want' ? const Color(0xFFD97706) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedNeedWant == 'want' ? const Color(0xFFD97706) : const Color(0xFFCBD5E1),
                        width: _selectedNeedWant == 'want' ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.star_outline,
                              size: 18,
                              color: _selectedNeedWant == 'want' ? Colors.white : const Color(0xFFD97706),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'WANT',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: _selectedNeedWant == 'want' ? Colors.white : const Color(0xFFD97706),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Optional / Discretionary\n(Shopping, Entertainment)',
                          style: TextStyle(
                            fontSize: 10,
                            height: 1.2,
                            fontWeight: FontWeight.w500,
                            color: _selectedNeedWant == 'want' ? Colors.white70 : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],

        // 7. ITEM DESCRIPTION
        TextField(
          controller: _titleController,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: isExpense ? 'Item Name / Description (Optional)' : 'Income Description / Note (Optional)',
            hintText: isExpense ? 'e.g. Vegetables, Electricity, Fuel' : 'e.g. Monthly Salary, Bonus, Project',
            prefixIcon: const Icon(Icons.edit_note),
          ),
        ),
        const SizedBox(height: 16),

        // 8. DATE PICKER
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );
            if (picked != null) {
              setState(() => _selectedDate = picked);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 18, color: Color(0xFF0284C7)),
                const SizedBox(width: 10),
                Text(
                  'Date: ${DateFormat('dd MMMM yyyy').format(_selectedDate)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const Spacer(),
                const Text('Change', style: TextStyle(color: Color(0xFF0284C7), fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // 9. SAVE BUTTON
        SizedBox(
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isExpense ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: _save,
            child: Text(
              isEditing ? 'UPDATE TRANSACTION' : (isExpense ? 'SAVE EXPENSE' : 'SAVE INCOME'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ),

        if (isEditing) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFDC2626),
                side: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.delete_outline, color: Color(0xFFDC2626)),
              label: const Text(
                'DELETE THIS TRANSACTION',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
              ),
              onPressed: _confirmDeleteExistingItem,
            ),
          ),
        ],
      ],
    );
  }

  // -------------------------------------------------------------
  // DEDICATED SIDE PANEL: WHAT'S ALREADY ADDED & WHAT TO ADD
  // -------------------------------------------------------------
  Widget _buildLedgerSidePanel(BuildContext context, {required bool isEmbedded}) {
    final controller = widget.controller;
    final totalCredit = controller.totalCredit;
    final totalDebit = controller.totalDebit;
    final netBalance = controller.currentBalance;
    final isExpense = _selectedType == 'expense';

    final allExpenseCategories = CategoryData.allExpenseCategories;
    final addedExpenseCategories = allExpenseCategories.where((c) {
      return controller.getCategoryTotalAmount(c.name, type: 'expense') > 0;
    }).toList()
      ..sort((a, b) => controller.getCategoryTotalAmount(b.name, type: 'expense')
          .compareTo(controller.getCategoryTotalAmount(a.name, type: 'expense')));

    final toAddExpenseCategories = allExpenseCategories.where((c) {
      return controller.getCategoryTotalAmount(c.name, type: 'expense') == 0;
    }).toList()
      ..sort((a, b) {
        final bBudget = controller.getCategoryBudget(b.name);
        final aBudget = controller.getCategoryBudget(a.name);
        if (bBudget > 0 || aBudget > 0) {
          return bBudget.compareTo(aBudget);
        }
        return a.name.compareTo(b.name);
      });

    final incomes = controller.incomes;
    final query = _sideSearchController.text.trim().toLowerCase();

    // Filter by query
    final filteredAdded = addedExpenseCategories.where((c) {
      if (query.isEmpty) return true;
      final txs = controller.getCategoryTransactions(c.name, type: 'expense');
      return c.name.toLowerCase().contains(query) || txs.any((t) => t.title.toLowerCase().contains(query));
    }).toList();

    final filteredToAdd = toAddExpenseCategories.where((c) {
      if (query.isEmpty) return true;
      return c.name.toLowerCase().contains(query);
    }).toList();

    final filteredIncomes = incomes.where((inc) {
      if (query.isEmpty) return true;
      return inc.category.toLowerCase().contains(query) || inc.title.toLowerCase().contains(query);
    }).toList();

    return Container(
      color: const Color(0xFFF8FAFC),
      child: Column(
        children: [
          // Header of the Side Panel
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: const [
                          Icon(Icons.checklist_rtl_rounded, color: Color(0xFF0284C7), size: 20),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Ledger: Added vs To Add',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isEmbedded)
                      IconButton(
                        icon: const Icon(Icons.close, size: 20, color: Color(0xFF64748B)),
                        onPressed: () => Navigator.pop(context),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'Check what is already recorded and select what to add next',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 12),

                // Financial Summary Card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                      // Credit (Salary)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.arrow_downward, color: Color(0xFF4ADE80), size: 11),
                              SizedBox(width: 3),
                              Text('CREDIT (Salary)', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '+₹${totalCredit > 0 ? totalCredit.toStringAsFixed(0) : controller.monthlyBudget.toStringAsFixed(0)}',
                            style: const TextStyle(color: Color(0xFF4ADE80), fontSize: 13, fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                      // Debits Added
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.arrow_upward, color: Color(0xFFF87171), size: 11),
                              SizedBox(width: 3),
                              Text('DEBITS ADDED', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '-₹${totalDebit.toStringAsFixed(0)}',
                            style: const TextStyle(color: Color(0xFFF87171), fontSize: 13, fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                      // Balance
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('NET SAVED', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text(
                            '₹${netBalance.toStringAsFixed(0)}',
                            style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 13, fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

                const SizedBox(height: 10),

                // Search Bar
                SizedBox(
                  height: 36,
                  child: TextField(
                    controller: _sideSearchController,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'Search added or to-add...',
                      hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                      prefixIcon: const Icon(Icons.search, size: 16, color: Color(0xFF64748B)),
                      suffixIcon: _sideSearchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 14),
                              onPressed: () {
                                _sideSearchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: const Color(0xFFF1F5F9),
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Filter Tabs
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('all', 'All (${addedExpenseCategories.length + toAddExpenseCategories.length})'),
                      const SizedBox(width: 6),
                      _buildFilterChip('added', 'Added (${addedExpenseCategories.length})', countColor: const Color(0xFF16A34A)),
                      const SizedBox(width: 6),
                      _buildFilterChip('to_add', 'To Add (${toAddExpenseCategories.length})', countColor: const Color(0xFF0284C7)),
                      const SizedBox(width: 6),
                      _buildFilterChip('credit', 'Salary & Incomes (${incomes.length})', countColor: const Color(0xFF10B981)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Scrollable List of Categories & Incomes
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              children: [
                // 1. INCOMES & SALARY (if filter == 'all' or 'credit')
                if (_sideFilter == 'all' || _sideFilter == 'credit') ...[
                  _buildSectionHeader(
                    title: 'CREDIT / SALARY ADDED',
                    count: filteredIncomes.length,
                    icon: Icons.account_balance_wallet,
                    color: const Color(0xFF16A34A),
                    badgeText: '+₹${totalCredit.toStringAsFixed(0)}',
                  ),
                  if (filteredIncomes.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, size: 16, color: Color(0xFF64748B)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              totalCredit > 0
                                  ? 'No matching incomes'
                                  : 'No salary recorded yet (Planned: ₹${controller.monthlyBudget.toStringAsFixed(0)})',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              _onTypeChanged('income');
                              if (!isEmbedded) Navigator.pop(context);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF16A34A).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                '+ Add Salary',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...filteredIncomes.map((inc) {
                      final catData = CategoryData.getCategory(inc.category);
                      return InkWell(
                        onTap: () => _showCategoryBreakdownSheet(context, inc.category, 'income'),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: catData.color.withValues(alpha: 0.15),
                                child: Icon(catData.icon, size: 14, color: catData.color),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          inc.category,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F5132)),
                                        ),
                                        if (inc.title.isNotEmpty && inc.title.toLowerCase() != inc.category.toLowerCase()) ...[
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              '(${inc.title})',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    Text(
                                      DateFormat('dd MMM yyyy, hh:mm a').format(inc.date),
                                      style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '+₹${inc.amount.toStringAsFixed(0)}',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF16A34A)),
                                  ),
                                  const Text(
                                    'View Credits →',
                                    style: TextStyle(fontSize: 8.5, color: Color(0xFF16A34A), fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 10),
                ],

                // 2. DEBITS ALREADY ADDED (if filter == 'all' or 'added')
                if (_sideFilter == 'all' || _sideFilter == 'added') ...[
                  _buildSectionHeader(
                    title: 'DEBITS ALREADY ADDED',
                    count: filteredAdded.length,
                    icon: Icons.check_circle_outline,
                    color: const Color(0xFFDC2626),
                    badgeText: '-₹${totalDebit.toStringAsFixed(0)}',
                  ),
                  if (filteredAdded.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Center(
                        child: Text(
                          'No debits added yet.',
                          style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ),
                    )
                  else
                    ...filteredAdded.map((cat) {
                      final spent = controller.getCategoryTotalAmount(cat.name, type: 'expense');
                      final budget = controller.getCategoryBudget(cat.name);
                      final isOver = budget > 0 && spent > budget;
                      final txs = controller.getCategoryTransactions(cat.name, type: 'expense');
                      final isSelected = _selectedCategory == cat.name && isExpense;

                      return InkWell(
                        onTap: () {
                          _showCategoryBreakdownSheet(context, cat.name, 'expense');
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFFE2E8F0),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: cat.color,
                                child: Icon(cat.icon, size: 14, color: Colors.white),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          cat.name,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFDCFCE7),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text('ADDED', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Color(0xFF15803D))),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFEFF6FF),
                                              borderRadius: BorderRadius.circular(3),
                                              border: Border.all(color: const Color(0xFFBFDBFE), width: 0.5),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.receipt_long, size: 9, color: Color(0xFF1D4ED8)),
                                                const SizedBox(width: 2),
                                                Text(
                                                  '${txs.length} record${txs.length == 1 ? '' : 's'}',
                                                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF1D4ED8)),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (budget > 0) ...[
                                            const Text(' • ', style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 9)),
                                            Text(
                                              'Target: ₹${budget.toStringAsFixed(0)}',
                                              style: const TextStyle(fontSize: 9, color: Color(0xFF64748B)),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '-₹${spent.toStringAsFixed(0)}',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFFDC2626)),
                                  ),
                                  if (budget > 0)
                                    Text(
                                      isOver ? 'Over ₹${(spent - budget).toStringAsFixed(0)}' : 'Left ₹${(budget - spent).toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: isOver ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                                      ),
                                    ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'View Debits →',
                                    style: TextStyle(fontSize: 8.5, color: Color(0xFF0284C7), fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 10),
                ],

                // 3. CATEGORIES TO ADD / PENDING (if filter == 'all' or 'to_add')
                if (_sideFilter == 'all' || _sideFilter == 'to_add') ...[
                  _buildSectionHeader(
                    title: 'CATEGORIES AGAIN TO ADD',
                    count: filteredToAdd.length,
                    icon: Icons.pending_actions_rounded,
                    color: const Color(0xFF0284C7),
                    badgeText: '${filteredToAdd.length} Pending',
                  ),
                  if (filteredToAdd.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Center(
                        child: Text(
                          'All expense categories have records!',
                          style: TextStyle(fontSize: 11, color: Color(0xFF16A34A), fontWeight: FontWeight.bold),
                        ),
                      ),
                    )
                  else
                    ...filteredToAdd.map((cat) {
                      final budget = controller.getCategoryBudget(cat.name);
                      final isSelected = _selectedCategory == cat.name && isExpense;

                      return InkWell(
                        onTap: () => _selectCategoryFromSide(context, cat.name, closeDrawer: !isEmbedded),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFFE2E8F0),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: cat.color.withValues(alpha: 0.15),
                                child: Icon(cat.icon, size: 14, color: cat.color),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            cat.name,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E293B)),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFEF3C7),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text('TO ADD', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Color(0xFFB45309))),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      budget > 0
                                          ? 'Planned Target: ₹${budget.toStringAsFixed(0)}'
                                          : 'Not yet recorded',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: budget > 0 ? FontWeight.w600 : FontWeight.normal,
                                        color: budget > 0 ? const Color(0xFF0284C7) : const Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.add, size: 12, color: Color(0xFF0284C7)),
                                    SizedBox(width: 2),
                                    Text('Add', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label, {Color? countColor}) {
    final isSelected = _sideFilter == key;
    return InkWell(
      onTap: () => setState(() => _sideFilter = key),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required String badgeText,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color, letterSpacing: 0.3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              badgeText,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
