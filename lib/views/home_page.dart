import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../controllers/expense_controller.dart';
import '../models/category_data.dart';
import '../models/transaction_model.dart';
import '../services/auth_service.dart';
import 'add_transaction_page.dart';
import 'export_statement_dialog.dart';
import 'reminder_dialog.dart';

enum ActiveScreen { summary, calendar, chart, activity, categories, budget }

class HomePage extends StatefulWidget {
  final ExpenseController controller;

  const HomePage({
    super.key,
    required this.controller,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  ActiveScreen _activeScreen = ActiveScreen.summary;
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _selectedCalendarDate = DateTime.now();
  int _touchedChartIndex = -1;
  String _activityFilter = 'all'; // 'all', 'need', 'want'
  int _chartMode = 0; // 0 = category breakdown, 1 = need vs want

  String _budgetFilter = 'all'; // 'all', 'allocated', 'unallocated', 'overbudget'
  String _budgetSearchQuery = '';
  final TextEditingController _budgetSearchController = TextEditingController();

  @override
  void dispose() {
    _budgetSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final controller = widget.controller;

        return PopScope(
          canPop: _activeScreen == ActiveScreen.summary,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) {
              setState(() => _activeScreen = ActiveScreen.summary);
            }
          },
          child: Scaffold(
            backgroundColor: const Color(0xFFF1F5F9),
            // 1. TOP APP BAR
            appBar: _activeScreen == ActiveScreen.summary
                ? AppBar(
                    backgroundColor: const Color(0xFF0284C7),
                    elevation: 0,
                    automaticallyImplyLeading: false,
                    toolbarHeight: 52,
                    centerTitle: true,
                    title: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ClipOval(
                          child: Image.asset(
                            'assets/images/cash_manager_logo.png',
                            height: 28,
                            width: 28,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) => const Icon(
                              Icons.currency_rupee,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Cash Manager',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 19,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    bottom: PreferredSize(
                      preferredSize: const Size.fromHeight(48),
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Builder(
                              builder: (ctx) => IconButton(
                                icon: const Icon(Icons.menu, color: Colors.white, size: 22),
                                tooltip: 'Menu',
                                visualDensity: VisualDensity.compact,
                                onPressed: () => Scaffold.of(ctx).openDrawer(),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 22),
                              tooltip: 'Export Statement',
                              visualDensity: VisualDensity.compact,
                              onPressed: () => showDialog(
                                context: context,
                                builder: (_) => ExportStatementDialog(controller: controller),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.calendar_month_outlined, color: Colors.white, size: 22),
                              tooltip: 'Expense Calendar',
                              visualDensity: VisualDensity.compact,
                              onPressed: () => setState(() => _activeScreen = ActiveScreen.calendar),
                            ),
                            IconButton(
                              icon: const Icon(Icons.notifications_active_outlined, color: Colors.white, size: 22),
                              tooltip: 'Daily Reminders',
                              visualDensity: VisualDensity.compact,
                              onPressed: () => showDialog(
                                context: context,
                                builder: (_) => ReminderDialog(controller: controller),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.search, color: Colors.white, size: 22),
                              tooltip: 'Search',
                              visualDensity: VisualDensity.compact,
                              onPressed: () => _showSearchDialog(context, controller),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : AppBar(
                    backgroundColor: const Color(0xFF0284C7),
                    elevation: 0,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      tooltip: 'Back to Dashboard',
                      onPressed: () => setState(() => _activeScreen = ActiveScreen.summary),
                    ),
                    title: Text(
                      _activeScreen == ActiveScreen.budget
                          ? 'Target Budget Planner'
                          : _activeScreen == ActiveScreen.categories
                              ? 'Categories & Records'
                              : _activeScreen == ActiveScreen.activity
                                  ? 'Credit & Debit Records'
                                  : _activeScreen == ActiveScreen.chart
                                      ? '${controller.selectedAccount} Analysis'
                                      : _activeScreen == ActiveScreen.calendar
                                          ? 'Expense Calendar'
                                          : 'Cash Manager',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
                      overflow: TextOverflow.ellipsis,
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.receipt_long_rounded, color: Colors.white),
                        tooltip: 'Export Statement',
                        onPressed: () => showDialog(
                          context: context,
                          builder: (_) => ExportStatementDialog(controller: controller),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.calendar_month_outlined, color: Colors.white),
                        tooltip: 'Expense Calendar',
                        onPressed: () => setState(() => _activeScreen = ActiveScreen.calendar),
                      ),
                      IconButton(
                        icon: const Icon(Icons.notifications_active_outlined, color: Colors.white),
                        tooltip: 'Daily Reminders',
                        onPressed: () => showDialog(
                          context: context,
                          builder: (_) => ReminderDialog(controller: controller),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.search, color: Colors.white),
                        tooltip: 'Search',
                        onPressed: () => _showSearchDialog(context, controller),
                      ),
                      if (_activeScreen == ActiveScreen.chart)
                        IconButton(
                          icon: const Icon(Icons.add, color: Colors.white, size: 26),
                          tooltip: 'Add Transaction',
                          onPressed: () => _openAddTransaction(context, controller),
                        ),
                    ],
                  ),
          drawer: _buildDrawer(context, controller),
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.0, 0.02),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: KeyedSubtree(
              key: ValueKey<ActiveScreen>(_activeScreen),
              child: _activeScreen == ActiveScreen.summary
                  ? _buildSummaryFrontPage(context, controller)
                  : _activeScreen == ActiveScreen.calendar
                      ? _buildCalendarPage(context, controller)
                      : _activeScreen == ActiveScreen.chart
                          ? _buildChartPage(context, controller)
                          : _activeScreen == ActiveScreen.activity
                              ? _buildActivityPage(context, controller)
                              : _activeScreen == ActiveScreen.budget
                                  ? _buildBudgetPage(context, controller)
                                  : _buildCategoriesPage(context, controller),
            ),
          ),
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
            ),
            child: BottomNavigationBar(
              currentIndex: _activeScreen == ActiveScreen.summary
                  ? 0
                  : _activeScreen == ActiveScreen.activity
                      ? 1
                      : _activeScreen == ActiveScreen.chart
                          ? 2
                          : _activeScreen == ActiveScreen.categories
                              ? 3
                              : 0,
              onTap: (index) {
                if (index == 0) {
                  setState(() => _activeScreen = ActiveScreen.summary);
                } else if (index == 1) {
                  setState(() => _activeScreen = ActiveScreen.activity);
                } else if (index == 2) {
                  setState(() => _activeScreen = ActiveScreen.chart);
                } else if (index == 3) {
                  setState(() => _activeScreen = ActiveScreen.categories);
                }
              },
              type: BottomNavigationBarType.fixed,
              selectedItemColor: const Color(0xFF0284C7),
              unselectedItemColor: const Color(0xFF64748B),
              selectedFontSize: 11,
              unselectedFontSize: 11,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_outlined), activeIcon: Icon(Icons.account_balance_wallet), label: 'Summary'),
                BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), activeIcon: Icon(Icons.receipt_long), label: 'Records'),
                BottomNavigationBarItem(icon: Icon(Icons.pie_chart_outline), activeIcon: Icon(Icons.pie_chart), label: 'Analysis'),
                BottomNavigationBarItem(icon: Icon(Icons.label_outline), activeIcon: Icon(Icons.label), label: 'Categories'),
              ],
            ),
          ),
        ),
      );
    },
    );
  }

  // ===========================================================================
  // FRONT PAGE: SUMMARY (Matching Screenshot 3)
  // ===========================================================================
  Widget _buildSummaryFrontPage(BuildContext context, ExpenseController controller) {
    final totalSpent = controller.totalSpent;
    final needAmt = controller.currentNeedExpense;
    final wantAmt = controller.currentWantExpense;
    final needPct = totalSpent > 0 ? (needAmt / totalSpent * 100) : 0.0;
    final wantPct = totalSpent > 0 ? (wantAmt / totalSpent * 100) : 0.0;

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 10),



          // 1. CREDIT vs DEBIT & NET SAVINGS HERO CARD
          AnimatedFadeSlide(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE0F2FE), Color(0xFFBAE6FD)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF7DD3FC), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Centralised Total Net Savings Header (NET SAVED badge removed)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.savings_rounded, color: Color(0xFF0284C7), size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Total Net Savings (Balance)',
                        style: TextStyle(
                          color: Color(0xFF0369A1),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Centralised Net Savings Amount
                  Text(
                    '₹${controller.currentBalance.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: controller.currentBalance >= 0 ? const Color(0xFF0F172A) : const Color(0xFFDC2626),
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Divider(height: 1, color: const Color(0xFF0284C7).withValues(alpha: 0.18)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      // 1. TOTAL CREDIT DETAILS & "Add credit details"
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFF86EFAC),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.arrow_downward, color: Color(0xFF16A34A), size: 13),
                                  SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      'Total Credit',
                                      style: TextStyle(
                                        color: Color(0xFF16A34A),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.2,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '+₹${controller.totalCredit.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Color(0xFF16A34A),
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () => _openAddTransaction(context, controller, type: 'income'),
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF16A34A).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.25)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.add, size: 13, color: Color(0xFF16A34A)),
                                      SizedBox(width: 4),
                                      Text(
                                        'Add credit details',
                                        style: TextStyle(
                                          color: Color(0xFF16A34A),
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // 2. TOTAL DEBIT DETAILS & "Add debit details"
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFFFECACA),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.arrow_upward, color: Color(0xFFDC2626), size: 13),
                                  SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      'Total Debit',
                                      style: TextStyle(
                                        color: Color(0xFFDC2626),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.2,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '-₹${controller.totalDebit.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Color(0xFFDC2626),
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () => _openAddTransaction(context, controller, type: 'expense'),
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDC2626).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFFDC2626).withValues(alpha: 0.25)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.remove, size: 13, color: Color(0xFFDC2626)),
                                      SizedBox(width: 4),
                                      Text(
                                        'Add debit details',
                                        style: TextStyle(
                                          color: Color(0xFFDC2626),
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // 2. CATEGORY BUDGET ADEQUACY & SAVINGS SUMMARY CARD
          AnimatedFadeSlide(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: controller.totalAllocatedBudget <= 0
                    ? const Color(0xFFE2E8F0)
                    : (controller.isBudgetSufficient
                        ? const Color(0xFFDCFCE7)
                        : const Color(0xFFFEE2E2)),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: controller.totalAllocatedBudget <= 0
                      ? const Color(0xFFCBD5E1)
                      : (controller.isBudgetSufficient
                          ? const Color(0xFF86EFAC)
                          : const Color(0xFFFCA5A5)),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row (Icon, Title on ONE line, Manage Link)
                  Row(
                    children: [
                      Icon(
                        controller.totalAllocatedBudget <= 0
                            ? Icons.info_outline
                            : (controller.isBudgetSufficient
                                ? Icons.check_circle_outline
                                : Icons.warning_amber_rounded),
                        size: 20,
                        color: controller.totalAllocatedBudget <= 0
                            ? const Color(0xFF64748B)
                            : (controller.isBudgetSufficient
                                ? const Color(0xFF16A34A)
                                : const Color(0xFFDC2626)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          controller.totalAllocatedBudget <= 0
                              ? 'No Target Budget Set'
                              : (controller.isBudgetSufficient
                                  ? 'Target Budget is Sufficient!'
                                  : 'Budget Alert: Target Exceeded'),
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: controller.totalAllocatedBudget <= 0
                                ? const Color(0xFF334155)
                                : (controller.isBudgetSufficient
                                    ? const Color(0xFF15803D)
                                    : const Color(0xFF991B1B)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => setState(() => _activeScreen = ActiveScreen.budget),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: controller.totalAllocatedBudget <= 0
                                ? const Color(0xFF0284C7).withValues(alpha: 0.12)
                                : (controller.isBudgetSufficient
                                    ? const Color(0xFF16A34A).withValues(alpha: 0.12)
                                    : const Color(0xFFDC2626).withValues(alpha: 0.12)),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Budget Planner →',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: controller.totalAllocatedBudget <= 0
                                  ? const Color(0xFF0284C7)
                                  : (controller.isBudgetSufficient
                                      ? const Color(0xFF15803D)
                                      : const Color(0xFF991B1B)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    controller.budgetSufficiencySummary,
                    style: TextStyle(
                      fontSize: 12,
                      color: controller.totalAllocatedBudget <= 0
                          ? const Color(0xFF64748B)
                          : (controller.isBudgetSufficient
                              ? const Color(0xFF166534)
                              : const Color(0xFF7F1D1D)),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (controller.totalAllocatedBudget > 0) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: SizedBox(
                        height: 5,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween<double>(
                            begin: 0.0,
                            end: (controller.totalDebit / controller.totalAllocatedBudget).clamp(0.0, 1.0),
                          ),
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOutCubic,
                          builder: (context, fillRatio, _) {
                            return LinearProgressIndicator(
                              value: fillRatio,
                              backgroundColor: Colors.black.withValues(alpha: 0.08),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                controller.isBudgetSufficient
                                    ? const Color(0xFF16A34A)
                                    : const Color(0xFFDC2626),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        controller.totalAllocatedBudget > 0
                            ? 'Planned Target: ₹${controller.totalAllocatedBudget.toStringAsFixed(0)}'
                            : 'Planned Target: Not Set',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      if (controller.totalAllocatedBudget > 0)
                        Text(
                          controller.remainingTargetBudget >= 0
                              ? 'Budget Left: ₹${controller.remainingTargetBudget.toStringAsFixed(0)}'
                              : 'Over: ₹${(-controller.remainingTargetBudget).toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: controller.remainingTargetBudget >= 0
                                ? const Color(0xFF16A34A)
                                : const Color(0xFFDC2626),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),





          const SizedBox(height: 12),

          // PURPOSE BREAKDOWN CARD: NEEDS (Compulsory) vs WANTS (Not Necessary)
          AnimatedFadeSlide(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.pie_chart_outline, size: 18, color: Color(0xFF0284C7)),
                          SizedBox(width: 6),
                          Text(
                            'Purpose Split (Need vs Want)',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF1E293B)),
                          ),
                        ],
                      ),
                      InkWell(
                        onTap: () => setState(() => _activeScreen = ActiveScreen.chart),
                        child: const Text('Details →', style: TextStyle(color: Color(0xFF0284C7), fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Need box
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFBBF7D0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.check_circle, size: 14, color: Color(0xFF16A34A)),
                                  SizedBox(width: 4),
                                  Text('NEED (Compulsory)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF15803D))),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text('₹${needAmt.toStringAsFixed(2)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF15803D))),
                              Text('${needPct.toStringAsFixed(0)}% of expenses', style: const TextStyle(fontSize: 10, color: Color(0xFF16A34A), fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Want box
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.star, size: 14, color: Color(0xFFD97706)),
                                  SizedBox(width: 4),
                                  Text('WANT (Optional)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFFB45309))),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text('₹${wantAmt.toStringAsFixed(2)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFFB45309))),
                              Text('${wantPct.toStringAsFixed(0)}% of expenses', style: const TextStyle(fontSize: 10, color: Color(0xFFD97706), fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (totalSpent > 0) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: SizedBox(
                        height: 8,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0.0, end: needPct.clamp(0.0, 100.0)),
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOutCubic,
                          builder: (context, animNeedPct, _) {
                            final animWantPct = (100.0 - animNeedPct).clamp(0.0, 100.0);
                            return Row(
                              children: [
                                if (animNeedPct > 0)
                                  Expanded(
                                    flex: (animNeedPct * 10).toInt().clamp(1, 1000),
                                    child: Container(color: const Color(0xFF16A34A)),
                                  ),
                                if (animWantPct > 0)
                                  Expanded(
                                    flex: (animWantPct * 10).toInt().clamp(1, 1000),
                                    child: Container(color: const Color(0xFFD97706)),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // EXPENSES BREAKDOWN TABLE WITH INTERACTIVE DETAILS
          AnimatedFadeSlide(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFCBD5E1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(9)),
                      border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Row(
                          children: [
                            Icon(Icons.calendar_month, size: 16, color: Color(0xFF0284C7)),
                            SizedBox(width: 6),
                            Text(
                              'EXPENSES BREAKDOWN BY PERIOD',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF334155),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Tap for Details →',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0284C7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildDataRow(
                    'Today Expense',
                    controller.todayExpense,
                    isGreen: false,
                    subtitle: DateFormat('dd MMM yyyy').format(DateTime.now()),
                    onTap: () => _showPeriodExpensesDetailSheet(
                      context,
                      controller,
                      'Today\'s Expenses Details',
                      DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now()),
                      controller.todayExpensesList,
                      controller.todayExpense,
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  _buildDataRow(
                    'This Week Expense',
                    controller.thisWeekExpense,
                    isGreen: false,
                    subtitle: () {
                      final now = DateTime.now();
                      final startOfWeek = DateTime(now.year, now.month, now.day - (now.weekday - 1));
                      final endOfWeek = startOfWeek.add(const Duration(days: 6));
                      return '${DateFormat('dd MMM').format(startOfWeek)} - ${DateFormat('dd MMM').format(endOfWeek)}';
                    }(),
                    onTap: () {
                      final now = DateTime.now();
                      final startOfWeek = DateTime(now.year, now.month, now.day - (now.weekday - 1));
                      final endOfWeek = startOfWeek.add(const Duration(days: 6));
                      _showPeriodExpensesDetailSheet(
                        context,
                        controller,
                        'Weekly Expenses Details',
                        '${DateFormat('dd MMM yyyy').format(startOfWeek)} - ${DateFormat('dd MMM yyyy').format(endOfWeek)}',
                        controller.thisWeekExpensesList,
                        controller.thisWeekExpense,
                      );
                    },
                  ),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  _buildDataRow(
                    'This Month Expense',
                    controller.thisMonthExpense,
                    isGreen: false,
                    subtitle: DateFormat('MMMM yyyy').format(DateTime.now()),
                    onTap: () => _showPeriodExpensesDetailSheet(
                      context,
                      controller,
                      'Monthly Expenses Details',
                      DateFormat('MMMM yyyy').format(DateTime.now()),
                      controller.thisMonthExpensesList,
                      controller.thisMonthExpense,
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  _buildDataRow(
                    'Year To Date Expense',
                    controller.yearToDateExpense,
                    isGreen: false,
                    subtitle: 'Calendar Year ${DateTime.now().year}',
                    onTap: () => _showPeriodExpensesDetailSheet(
                      context,
                      controller,
                      'Year To Date Expenses Details',
                      'Calendar Year ${DateTime.now().year}',
                      controller.yearToDateExpensesList,
                      controller.yearToDateExpense,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 50),
        ],
      ),
    );
  }

  // ===========================================================================
  // CALENDAR VIEW (Matching Screenshot 2)
  // ===========================================================================
  Widget _buildCalendarPage(BuildContext context, ExpenseController controller) {
    final year = _currentMonth.year;
    final month = _currentMonth.month;
    final firstDayOfMonth = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final startingWeekday = firstDayOfMonth.weekday % 7;

    final accountExpenses = controller.getExpensesForAccount(controller.selectedAccount);
    final monthExpenses = accountExpenses.where((e) => e.date.year == year && e.date.month == month).toList();
    final Map<int, List<ExpenseItem>> dayExpensesMap = {};
    for (final e in monthExpenses) {
      dayExpensesMap[e.date.day] = (dayExpensesMap[e.date.day] ?? [])..add(e);
    }

    return Column(
      children: [
        // Navigation Header
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 48),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: Color(0xFFDC2626), size: 28),
                    onPressed: () => setState(() => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1)),
                  ),
                  Text(
                    DateFormat('MMMM yyyy').format(_currentMonth),
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: Color(0xFFDC2626), size: 28),
                    onPressed: () => setState(() => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1)),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.add_circle, color: Color(0xFF0284C7), size: 26),
                tooltip: 'Add Expense',
                onPressed: () => _openAddTransaction(context, controller),
              ),
            ],
          ),
        ),

        // Weekday labels
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: const ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'].map((d) {
              return Expanded(
                child: Center(
                  child: Text(
                    d,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: d == 'SUN' ? const Color(0xFFDC2626) : const Color(0xFF64748B),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const Divider(height: 1, color: Color(0xFFE2E8F0)),

        // Calendar Grid
        Expanded(
          child: Container(
            color: Colors.white,
            child: GridView.builder(
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 0.85,
              ),
              itemCount: 42,
              itemBuilder: (ctx, index) {
                final dayNumber = index - startingWeekday + 1;
                if (dayNumber < 1 || dayNumber > daysInMonth) {
                  return Container(
                    decoration: BoxDecoration(border: Border.all(color: const Color(0xFFF8FAFC), width: 0.5)),
                  );
                }

                final expensesOnDay = dayExpensesMap[dayNumber] ?? [];
                final dayTotal = expensesOnDay.fold(0.0, (sum, e) => sum + e.amount);
                final isSelected = _selectedCalendarDate.year == year && _selectedCalendarDate.month == month && _selectedCalendarDate.day == dayNumber;

                return InkWell(
                  onTap: () {
                    final date = DateTime(year, month, dayNumber);
                    setState(() => _selectedCalendarDate = date);
                    if (expensesOnDay.isNotEmpty) {
                      _showDayExpensesSheet(context, controller, date, expensesOnDay);
                    } else {
                      _openAddTransaction(context, controller, initialDate: date);
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFFEF2F2) : Colors.white,
                      border: Border.all(
                        color: isSelected ? const Color(0xFFDC2626) : const Color(0xFFE2E8F0),
                        width: isSelected ? 1.5 : 0.5,
                      ),
                    ),
                    padding: const EdgeInsets.all(2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$dayNumber',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: isSelected ? const Color(0xFFDC2626) : const Color(0xFF1E293B),
                          ),
                        ),
                        const Spacer(),
                        if (dayTotal > 0)
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              dayTotal.toStringAsFixed(0),
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFFDC2626)),
                            ),
                          ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            (controller.getAccountIncome(controller.selectedAccount) - dayTotal).toStringAsFixed(0),
                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF16A34A)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // CATEGORY & CHART VIEW
  // ===========================================================================
  Widget _buildChartPage(BuildContext context, ExpenseController controller) {
    final accountExpenses = controller.expenses;
    final totalExpense = controller.totalSpent;
    final needExpense = controller.currentNeedExpense;
    final wantExpense = controller.currentWantExpense;

    final Map<String, double> categoryMap = {};
    for (final e in accountExpenses) {
      categoryMap[e.category] = (categoryMap[e.category] ?? 0.0) + e.amount;
    }

    final categoryEntries = categoryMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chart Mode Toggle (Category vs Need/Want)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _chartMode = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _chartMode == 0 ? const Color(0xFF0284C7) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Category Breakdown',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _chartMode == 0 ? Colors.white : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _chartMode = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _chartMode == 1 ? const Color(0xFF0284C7) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Need vs Want Split',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _chartMode == 1 ? Colors.white : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // 1. NEED VS WANT CHART MODE
          if (_chartMode == 1) ...[
            if (totalExpense > 0)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: SizedBox(
                        height: 180,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            PieChart(
                              PieChartData(
                                borderData: FlBorderData(show: false),
                                sectionsSpace: 3,
                                centerSpaceRadius: 42,
                                sections: [
                                  if (needExpense > 0)
                                    PieChartSectionData(
                                      color: const Color(0xFF16A34A),
                                      value: needExpense,
                                      title: '${(needExpense / totalExpense * 100).toStringAsFixed(0)}%',
                                      radius: 40,
                                      titleStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  if (wantExpense > 0)
                                    PieChartSectionData(
                                      color: const Color(0xFFD97706),
                                      value: wantExpense,
                                      title: '${(wantExpense / totalExpense * 100).toStringAsFixed(0)}%',
                                      radius: 40,
                                      titleStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                ],
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('TOTAL', style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                                Text(
                                  totalExpense.toStringAsFixed(0),
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildChartLegendItem('Need (Compulsory)', needExpense, const Color(0xFF16A34A), totalExpense),
                          const SizedBox(height: 10),
                          _buildChartLegendItem('Want (Optional)', wantExpense, const Color(0xFFD97706), totalExpense),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 14),

            // Detailed Need vs Want Lists
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(
                children: [
                  // Needs Box
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 18),
                                SizedBox(width: 6),
                                Text('COMPULSORY (NEEDS)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF15803D))),
                              ],
                            ),
                            Text('₹${needExpense.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF15803D), fontSize: 15)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...accountExpenses.where((e) => e.isNeed).take(5).map((e) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 3),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('• ${e.title}', style: const TextStyle(fontSize: 12, color: Color(0xFF334155), fontWeight: FontWeight.w500)),
                                  Text('₹${e.amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF15803D))),
                                ],
                              ),
                            )),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Wants Box
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.star, color: Color(0xFFD97706), size: 18),
                                SizedBox(width: 6),
                                Text('NOT NECESSARY (WANTS)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFFB45309))),
                              ],
                            ),
                            Text('₹${wantExpense.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFB45309), fontSize: 15)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...accountExpenses.where((e) => e.isWant).take(5).map((e) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 3),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('• ${e.title}', style: const TextStyle(fontSize: 12, color: Color(0xFF334155), fontWeight: FontWeight.w500)),
                                  Text('₹${e.amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFB45309))),
                                ],
                              ),
                            )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // 2. CATEGORY CHART MODE
            if (categoryEntries.isNotEmpty && totalExpense > 0)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: SizedBox(
                        height: 180,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            PieChart(
                              PieChartData(
                                pieTouchData: PieTouchData(
                                  touchCallback: (event, pieTouchResponse) {
                                    setState(() {
                                      if (!event.isInterestedForInteractions ||
                                          pieTouchResponse == null ||
                                          pieTouchResponse.touchedSection == null) {
                                        _touchedChartIndex = -1;
                                        return;
                                      }
                                      _touchedChartIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                                    });
                                  },
                                ),
                                borderData: FlBorderData(show: false),
                                sectionsSpace: 2,
                                centerSpaceRadius: 40,
                                sections: categoryEntries.asMap().entries.map((item) {
                                  final idx = item.key;
                                  final e = item.value;
                                  final isTouched = idx == _touchedChartIndex;
                                  final cat = CategoryData.getCategory(e.key);
                                  final percentage = (e.value / totalExpense * 100);

                                  return PieChartSectionData(
                                    color: cat.color,
                                    value: e.value,
                                    title: isTouched
                                        ? '${percentage.toStringAsFixed(1)}%'
                                        : (percentage > 12 ? '${percentage.toStringAsFixed(0)}%' : ''),
                                    radius: isTouched ? 46 : 38,
                                    titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                                  );
                                }).toList(),
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('TOTAL', style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                                Text(
                                  totalExpense.toStringAsFixed(2),
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: categoryEntries.map((e) {
                          final cat = CategoryData.getCategory(e.key);
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              children: [
                                Container(width: 10, height: 10, decoration: BoxDecoration(color: cat.color, borderRadius: BorderRadius.circular(2))),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    e.key,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 12),

            // Categories List
            Container(
              color: Colors.white,
              child: Column(
                children: categoryEntries.map((entry) {
                  final percentage = totalExpense > 0 ? (entry.value / totalExpense * 100) : 0.0;
                  final cat = CategoryData.getCategory(entry.key);

                  return ListTile(
                    leading: Container(
                      width: 6,
                      height: 24,
                      decoration: BoxDecoration(color: cat.color, borderRadius: BorderRadius.circular(3)),
                    ),
                    title: Text(entry.key, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    trailing: Text(
                      '${entry.value.toStringAsFixed(2)} | ${percentage.toStringAsFixed(2)}%',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFFDC2626)),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildChartLegendItem(String label, double amount, Color color, double total) {
    final pct = total > 0 ? (amount / total * 100) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Text('₹${amount.toStringAsFixed(0)} (${pct.toStringAsFixed(0)}%)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color)),
        ),
      ],
    );
  }

  // ===========================================================================
  // ACTIVITY VIEW
  // ===========================================================================
  Widget _buildActivityPage(BuildContext context, ExpenseController controller) {
    final allTransactions = controller.getTransactionsForAccount(controller.selectedAccount);
    final debitTransactions = allTransactions.where((e) => e.type == 'expense').toList();
    final creditTransactions = allTransactions.where((e) => e.type == 'income').toList();
    final needCount = debitTransactions.where((e) => e.isNeed).length;
    final wantCount = debitTransactions.where((e) => e.isWant).length;
    final debitTotal = debitTransactions.fold(0.0, (sum, e) => sum + e.amount);
    final creditTotal = creditTransactions.fold(0.0, (sum, e) => sum + e.amount);

    List<ExpenseItem> displayedDebits = debitTransactions;
    if (_activityFilter == 'need') {
      displayedDebits = debitTransactions.where((e) => e.isNeed).toList();
    } else if (_activityFilter == 'want') {
      displayedDebits = debitTransactions.where((e) => e.isWant).toList();
    } else if (_activityFilter == 'credit') {
      displayedDebits = [];
    }

    List<ExpenseItem> displayedCredits = creditTransactions;
    if (_activityFilter == 'need' || _activityFilter == 'want' || _activityFilter == 'debit') {
      displayedCredits = [];
    }

    final showDebits = _activityFilter != 'credit';
    final showCredits = _activityFilter != 'debit' && _activityFilter != 'need' && _activityFilter != 'want';

    return Column(
      children: [
        // 2. Summary Totals Bar (Debits, Credits, Balance)
        Container(
          margin: const EdgeInsets.fromLTRB(14, 8, 14, 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('TOTAL DEBITS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFFDC2626))),
                    const SizedBox(height: 2),
                    Text(
                      '-₹${debitTotal.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFFDC2626)),
                    ),
                    Text('${debitTransactions.length} records', style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B))),
                  ],
                ),
              ),
              Container(width: 1, height: 32, color: const Color(0xFFE2E8F0)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('TOTAL CREDITS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF16A34A))),
                    const SizedBox(height: 2),
                    Text(
                      '+₹${creditTotal.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF16A34A)),
                    ),
                    Text('${creditTransactions.length} records', style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B))),
                  ],
                ),
              ),
              Container(width: 1, height: 32, color: const Color(0xFFE2E8F0)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('NET BALANCE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF0F5132))),
                    const SizedBox(height: 2),
                    Text(
                      '₹${(creditTotal - debitTotal).toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: (creditTotal - debitTotal) >= 0 ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                      ),
                    ),
                    Text((creditTotal - debitTotal) >= 0 ? 'Surplus' : 'Deficit', style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B))),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 3. Filter Chips
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildActivityFilterChip('all', 'All (${allTransactions.length})'),
                const SizedBox(width: 6),
                _buildActivityFilterChip('debit', 'Debits (${debitTransactions.length})', activeColor: const Color(0xFFDC2626)),
                const SizedBox(width: 6),
                _buildActivityFilterChip('credit', 'Credits (${creditTransactions.length})', activeColor: const Color(0xFF16A34A)),
                const SizedBox(width: 6),
                _buildActivityFilterChip('need', 'Need Only ($needCount)', activeColor: const Color(0xFF15803D)),
                const SizedBox(width: 6),
                _buildActivityFilterChip('want', 'Want Only ($wantCount)', activeColor: const Color(0xFFD97706)),
              ],
            ),
          ),
        ),

        const Divider(height: 1, color: Color(0xFFE2E8F0)),

        // 4. Scrollable Column-wise Lists
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 90),
            children: [
              // =======================================================
              // 1. DEBIT RECORDS (HEADING & COLUMN-WISE LAYOUT)
              // =======================================================
              if (showDebits) ...[
                // HEADING BANNER FOR DEBIT RECORDS
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Color(0xFFDC2626),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.arrow_upward, size: 12, color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'DEBIT RECORDS',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF991B1B),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                '${displayedDebits.length} entries • Column-wise breakdown',
                                style: const TextStyle(fontSize: 9.5, color: Color(0xFF7F1D1D)),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            '-₹${displayedDebits.fold(0.0, (sum, e) => sum + e.amount).toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFDC2626),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.add_circle, color: Color(0xFFDC2626), size: 20),
                            tooltip: 'Add Debit',
                            onPressed: () => _openAddTransaction(context, controller, type: 'expense'),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 6),

                // COLUMN HEADERS FOR DEBIT
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: const Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: Text(
                          'DEBIT DETAILS',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF334155), letterSpacing: 0.4),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Center(
                          child: Text(
                            'NEED & WANT',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF334155), letterSpacing: 0.4),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          'AMOUNT',
                          textAlign: TextAlign.right,
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF334155), letterSpacing: 0.4),
                        ),
                      ),
                      SizedBox(width: 6),
                      SizedBox(
                        width: 52,
                        child: Center(
                          child: Text(
                            'ACTION',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF334155), letterSpacing: 0.4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 4),

                // DEBITS LIST ITEMS (COLUMN-WISE)
                if (displayedDebits.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          const Text('No debit records found', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                          const SizedBox(height: 6),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFDC2626),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            icon: const Icon(Icons.add, size: 13),
                            label: const Text('+ Add Debit Expense'),
                            onPressed: () => _openAddTransaction(context, controller, type: 'expense'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...displayedDebits.map((item) {
                    final cat = CategoryData.getCategory(item.category);
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          // Column 1: DEBIT DETAILS (Icon, Title, Category, Date/Time)
                          Expanded(
                            flex: 5,
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
                                      Text(
                                        item.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: Color(0xFF0F172A)),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Text(
                                            item.category,
                                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: cat.color),
                                          ),
                                          const Text(' • ', style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 9)),
                                          Expanded(
                                            child: Text(
                                              DateFormat('dd MMM, hh:mm a').format(item.date),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Column 2: NEED AND WANT
                          Expanded(
                            flex: 3,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: item.isNeed ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: item.isNeed ? const Color(0xFF86EFAC) : const Color(0xFFFDE68A),
                                    width: 0.8,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      item.isNeed ? Icons.check_circle : Icons.star,
                                      size: 10,
                                      color: item.isNeed ? const Color(0xFF15803D) : const Color(0xFFB45309),
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      item.isNeed ? 'NEED' : 'WANT',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        color: item.isNeed ? const Color(0xFF15803D) : const Color(0xFFB45309),
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Column 3: AMOUNT
                          Expanded(
                            flex: 3,
                            child: Text(
                              '-₹${item.amount.toStringAsFixed(2)}',
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFDC2626),
                              ),
                            ),
                          ),

                          // Column 4: ACTIONS (Edit / Delete)
                          const SizedBox(width: 6),
                          SizedBox(
                            width: 52,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                InkWell(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => AddTransactionPage(controller: controller, existingItem: item)),
                                  ),
                                  child: const Padding(
                                    padding: EdgeInsets.all(2),
                                    child: Icon(Icons.edit_outlined, size: 16, color: Color(0xFF0284C7)),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                InkWell(
                                  onTap: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (dCtx) => AlertDialog(
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        title: const Text('Delete Debit Record'),
                                        content: Text('Delete "${item.title}" of ₹${item.amount.toStringAsFixed(2)}?'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(dCtx, false), child: const Text('Cancel')),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
                                            onPressed: () => Navigator.pop(dCtx, true),
                                            child: const Text('Delete', style: TextStyle(color: Colors.white)),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await controller.deleteExpense(item.id);
                                      setState(() {});
                                    }
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.all(2),
                                    child: Icon(Icons.delete_outline, size: 16, color: Color(0xFFDC2626)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],

              const SizedBox(height: 18),

              // =======================================================
              // 2. CREDIT RECORDS ("after dbt give creit details")
              // =======================================================
              if (showCredits) ...[
                // HEADING BANNER FOR CREDIT RECORDS
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Color(0xFF16A34A),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.arrow_downward, size: 12, color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'CREDIT RECORDS',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF166534),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                '${displayedCredits.length} entries • Income & Salary details',
                                style: const TextStyle(fontSize: 9.5, color: Color(0xFF15803D)),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            '+₹${displayedCredits.fold(0.0, (sum, e) => sum + e.amount).toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF16A34A),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.add_circle, color: Color(0xFF16A34A), size: 20),
                            tooltip: 'Add Credit',
                            onPressed: () => _openAddTransaction(context, controller, type: 'income'),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 6),

                // COLUMN HEADERS FOR CREDITS
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: const Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: Text(
                          'CREDIT DETAILS',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF334155), letterSpacing: 0.4),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Center(
                          child: Text(
                            'SOURCE / TYPE',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF334155), letterSpacing: 0.4),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          'AMOUNT',
                          textAlign: TextAlign.right,
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF334155), letterSpacing: 0.4),
                        ),
                      ),
                      SizedBox(width: 6),
                      SizedBox(
                        width: 52,
                        child: Center(
                          child: Text(
                            'ACTION',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF334155), letterSpacing: 0.4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 4),

                // CREDITS LIST ITEMS (COLUMN-WISE)
                if (displayedCredits.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          const Text('No credit records found', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                          const SizedBox(height: 6),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF16A34A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            icon: const Icon(Icons.add, size: 13),
                            label: const Text('+ Add Credit / Salary'),
                            onPressed: () => _openAddTransaction(context, controller, type: 'income'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...displayedCredits.map((item) {
                    final cat = CategoryData.getCategory(item.category);
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          // Column 1: CREDIT DETAILS (Icon, Title, Category, Date/Time)
                          Expanded(
                            flex: 5,
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: const Color(0xFF16A34A).withValues(alpha: 0.15),
                                  child: Icon(cat.icon, size: 14, color: const Color(0xFF16A34A)),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: Color(0xFF0F172A)),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Text(
                                            item.category,
                                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF16A34A)),
                                          ),
                                          const Text(' • ', style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 9)),
                                          Expanded(
                                            child: Text(
                                              DateFormat('dd MMM, hh:mm a').format(item.date),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Column 2: SOURCE / TYPE BADGE
                          Expanded(
                            flex: 3,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: const Color(0xFF86EFAC), width: 0.8),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.arrow_downward, size: 9, color: Color(0xFF15803D)),
                                    SizedBox(width: 2),
                                    Text(
                                      'CREDIT',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF15803D),
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Column 3: AMOUNT
                          Expanded(
                            flex: 3,
                            child: Text(
                              '+₹${item.amount.toStringAsFixed(2)}',
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF16A34A),
                              ),
                            ),
                          ),

                          // Column 4: ACTIONS (Edit / Delete)
                          const SizedBox(width: 6),
                          SizedBox(
                            width: 52,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                InkWell(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => AddTransactionPage(controller: controller, existingItem: item)),
                                  ),
                                  child: const Padding(
                                    padding: EdgeInsets.all(2),
                                    child: Icon(Icons.edit_outlined, size: 16, color: Color(0xFF0284C7)),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                InkWell(
                                  onTap: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (dCtx) => AlertDialog(
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        title: const Text('Delete Credit Record'),
                                        content: Text('Delete "${item.title}" of ₹${item.amount.toStringAsFixed(2)}?'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(dCtx, false), child: const Text('Cancel')),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
                                            onPressed: () => Navigator.pop(dCtx, true),
                                            child: const Text('Delete', style: TextStyle(color: Colors.white)),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await controller.deleteExpense(item.id);
                                      setState(() {});
                                    }
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.all(2),
                                    child: Icon(Icons.delete_outline, size: 16, color: Color(0xFFDC2626)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityFilterChip(String key, String label, {Color? activeColor}) {
    final isSelected = _activityFilter == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) setState(() => _activityFilter = key);
      },
      selectedColor: activeColor ?? const Color(0xFF0284C7),
      backgroundColor: const Color(0xFFF1F5F9),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF475569),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
        fontSize: 11,
      ),
    );
  }

  // ===========================================================================
  // DEDICATED MANAGE TARGET BUDGETS VIEW (Separate from Debit Details Addition)
  // ===========================================================================
  Widget _buildBudgetPage(BuildContext context, ExpenseController controller) {
    final allCats = CategoryData.allExpenseCategories;
    final totalPlanned = controller.totalAllocatedBudget;
    final totalSpent = controller.totalDebit;
    final totalCatSum = controller.totalCategoryBudgetsSum;
    final remainingBudget = controller.remainingTargetBudget;
    final allocatedCount = controller.allocatedCategoriesCount;
    final unallocatedCount = controller.unallocatedCategoriesCount;
    final overCount = controller.overbudgetCategoryCount;
    final needCount = allCats.where((c) => c.defaultNeedWant == 'need').length;
    final wantCount = allCats.where((c) => c.defaultNeedWant == 'want').length;

    // Filter categories based on search query and selected filter
    final filteredCats = allCats.where((cat) {
      final nameMatches = cat.name.toLowerCase().contains(_budgetSearchQuery.toLowerCase().trim());
      if (!nameMatches) return false;

      final budget = controller.getCategoryBudget(cat.name);
      final spent = controller.getCategoryTotalAmount(cat.name);

      if (_budgetFilter == 'allocated') {
        return budget > 0;
      } else if (_budgetFilter == 'unallocated') {
        return budget <= 0;
      } else if (_budgetFilter == 'overbudget') {
        return budget > 0 && spent > budget;
      } else if (_budgetFilter == 'need') {
        return cat.defaultNeedWant == 'need';
      } else if (_budgetFilter == 'want') {
        return cat.defaultNeedWant == 'want';
      }
      return true;
    }).toList();

    return Container(
      color: const Color(0xFFF8FAFC), // Modern clean slate background
      child: ListView(
        padding: const EdgeInsets.only(bottom: 90),
        children: [
          // 1. MASTER TARGET BUDGET & SUFFICIENCY STATUS CARD
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: totalPlanned <= 0
                    ? const Color(0xFFE2E8F0)
                    : (controller.isBudgetSufficient ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA)),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (totalPlanned <= 0
                                ? const Color(0xFF64748B)
                                : (controller.isBudgetSufficient ? const Color(0xFF16A34A) : const Color(0xFFDC2626)))
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        totalPlanned <= 0
                            ? Icons.info_outline
                            : (controller.isBudgetSufficient
                                ? Icons.verified_user
                                : Icons.warning_amber_rounded),
                        color: totalPlanned <= 0
                            ? const Color(0xFF64748B)
                            : (controller.isBudgetSufficient ? const Color(0xFF16A34A) : const Color(0xFFDC2626)),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            totalPlanned <= 0
                                ? 'No Target Budget Set'
                                : (controller.isBudgetSufficient
                                    ? 'Target Budget is Sufficient!'
                                    : 'Budget Alert: Target Exceeded'),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: totalPlanned <= 0
                                  ? const Color(0xFF1E293B)
                                  : (controller.isBudgetSufficient ? const Color(0xFF15803D) : const Color(0xFF991B1B)),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            controller.budgetSufficiencySummary,
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 14),

                // METRIC ROW: PLANNED TARGET, CATEGORIES ALLOCATED, BUDGET LEFT
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFDCFCE7)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'PLANNED TARGET',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF166534), letterSpacing: 0.5),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₹${totalPlanned.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF15803D)),
                            ),
                            const SizedBox(height: 2),
                            InkWell(
                              onTap: () => _showBudgetDialog(context, controller),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.edit, size: 11, color: Color(0xFF0284C7)),
                                  SizedBox(width: 2),
                                  Text(
                                    'Edit Total',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFDBEAFE)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'CATEGORIES SET',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF1E40AF), letterSpacing: 0.5),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$allocatedCount of ${allCats.length}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1D4ED8)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Sum: ₹${totalCatSum.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        decoration: BoxDecoration(
                          color: remainingBudget >= 0 ? const Color(0xFFF8FAFC) : const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: remainingBudget >= 0 ? const Color(0xFFE2E8F0) : const Color(0xFFFECACA)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              remainingBudget >= 0 ? 'BUDGET LEFT' : 'OVER TARGET',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: remainingBudget >= 0 ? const Color(0xFF475569) : const Color(0xFF991B1B),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              remainingBudget >= 0
                                  ? '₹${remainingBudget.toStringAsFixed(0)}'
                                  : '₹${(-remainingBudget).toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: remainingBudget >= 0 ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Spent: ₹${totalSpent.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // QUICK ACTION BUTTONS
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0284C7),
                        side: const BorderSide(color: Color(0xFF0284C7)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      icon: const Icon(Icons.calculate_outlined, size: 15),
                      label: const Text('Set Total Planned Target', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      onPressed: () => _showBudgetDialog(context, controller),
                    ),

                    if (controller.hasActiveBudget)
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFDC2626),
                          side: const BorderSide(color: Color(0xFFDC2626)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        icon: const Icon(Icons.delete_outline, size: 15),
                        label: const Text('Reset All Targets', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (dCtx) => AlertDialog(
                              title: const Text('Reset All Category Budgets?'),
                              content: const Text('This will clear all target budgets for all categories to ₹0. Expense debit records will not be deleted.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(dCtx, false), child: const Text('Cancel')),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
                                  onPressed: () => Navigator.pop(dCtx, true),
                                  child: const Text('Clear All', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await controller.clearAllBudgets();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('All category targets have been cleared'),
                                  backgroundColor: Color(0xFFDC2626),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),


          // 3. SEARCH & STATUS FILTER TABS
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _budgetSearchController,
              onChanged: (val) => setState(() => _budgetSearchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search category to set target budget...',
                prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF64748B)),
                suffixIcon: _budgetSearchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _budgetSearchController.clear();
                          setState(() => _budgetSearchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              ),
            ),
          ),

          // FILTER CHIPS ROW: All, Allocated, Not Allocated, Over Budget, Needs, Wants
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                _buildBudgetFilterChip('all', 'All (${allCats.length})', Icons.category_outlined),
                const SizedBox(width: 8),
                _buildBudgetFilterChip('allocated', 'Target Set ($allocatedCount)', Icons.check_circle_outline, activeColor: const Color(0xFF15803D)),
                const SizedBox(width: 8),
                _buildBudgetFilterChip('unallocated', 'No Target Set ($unallocatedCount)', Icons.warning_amber_rounded, activeColor: const Color(0xFFD97706)),
                const SizedBox(width: 8),
                _buildBudgetFilterChip('overbudget', 'Over Budget ($overCount)', Icons.error_outline, activeColor: const Color(0xFFDC2626)),
                const SizedBox(width: 8),
                _buildBudgetFilterChip('need', 'Needs ($needCount)', Icons.task_alt, activeColor: const Color(0xFF15803D)),
                const SizedBox(width: 8),
                _buildBudgetFilterChip('want', 'Wants ($wantCount)', Icons.star_outline, activeColor: const Color(0xFFD97706)),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // 4. CATEGORY TARGET BUDGET LIST
          if (filteredCats.isEmpty)
            Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.search_off, size: 40, color: Color(0xFF94A3B8)),
                  const SizedBox(height: 10),
                  Text(
                    _budgetFilter == 'unallocated'
                        ? 'All categories have target budgets allocated!'
                        : (_budgetFilter == 'allocated'
                            ? 'No categories have target budgets set yet.'
                            : (_budgetFilter == 'need'
                                ? 'No categories classified as Need.'
                                : (_budgetFilter == 'want'
                                    ? 'No categories classified as Want.'
                                    : 'No matching categories found.'))),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filteredCats.length,
              itemBuilder: (ctx, idx) {
                final cat = filteredCats[idx];
                final targetBudget = controller.getCategoryBudget(cat.name);
                final spent = controller.getCategoryTotalAmount(cat.name);
                final isLocated = targetBudget > 0;
                final isOver = isLocated && spent > targetBudget;
                final remaining = targetBudget - spent;
                final ratio = isLocated ? (spent / targetBudget).clamp(0.0, 1.0) : 0.0;
                final isNeed = cat.defaultNeedWant == 'need';
                final recordCount = controller.getCategoryTransactions(cat.name, type: 'expense').length;

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: !isLocated
                          ? const Color(0xFFE2E8F0)
                          : (isOver ? const Color(0xFFFECACA) : const Color(0xFFDCFCE7)),
                      width: isLocated ? 1.2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _showSetCategoryBudgetDialog(context, cat, controller),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: cat.color,
                                child: Icon(cat.icon, color: Colors.white, size: 18),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          cat.name,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                                        ),
                                        const SizedBox(width: 6),
                                        InkWell(
                                          borderRadius: BorderRadius.circular(4),
                                          onTap: () async {
                                            final newType = isNeed ? 'want' : 'need';
                                            await controller.setCategoryClassification(cat.name, newType);
                                            setState(() {});
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('${cat.name} classified as ${newType.toUpperCase()} (Need/Want updated)'),
                                                  duration: const Duration(seconds: 1),
                                                  behavior: SnackBarBehavior.floating,
                                                  backgroundColor: newType == 'need' ? const Color(0xFF15803D) : const Color(0xFFD97706),
                                                ),
                                              );
                                            }
                                          },
                                          child: Tooltip(
                                            message: 'Tap to switch between Need and Want',
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                              decoration: BoxDecoration(
                                                color: isNeed ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(
                                                  color: isNeed ? const Color(0xFF15803D) : const Color(0xFFD97706),
                                                  width: 0.8,
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    isNeed ? Icons.check : Icons.star,
                                                    size: 9,
                                                    color: isNeed ? const Color(0xFF15803D) : const Color(0xFFB45309),
                                                  ),
                                                  const SizedBox(width: 2),
                                                  Text(
                                                    isNeed ? 'NEED' : 'WANT',
                                                    style: TextStyle(
                                                      fontSize: 9,
                                                      fontWeight: FontWeight.w900,
                                                      color: isNeed ? const Color(0xFF15803D) : const Color(0xFFB45309),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'Actual Spent: ₹${spent.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: spent > 0 ? const Color(0xFFDC2626) : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // PROMINENT TARGET BUDGET STATUS BADGE
                              if (isLocated)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isOver ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isOver ? const Color(0xFFFCA5A5) : const Color(0xFF86EFAC),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Target: ₹${targetBudget.toStringAsFixed(0)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w900,
                                          color: isOver ? const Color(0xFFDC2626) : const Color(0xFF15803D),
                                        ),
                                      ),
                                      Text(
                                        isOver
                                            ? 'Over by ₹${(spent - targetBudget).toStringAsFixed(0)}'
                                            : '₹${remaining.toStringAsFixed(0)} left',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: isOver ? const Color(0xFF991B1B) : const Color(0xFF166534),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFFCD34D), width: 0.8),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.help_outline, size: 12, color: Color(0xFFB45309)),
                                      SizedBox(width: 4),
                                      Text(
                                        'No Target Set',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFFB45309)),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),

                          if (isLocated) ...[
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: ratio,
                                minHeight: 5,
                                backgroundColor: const Color(0xFFE2E8F0),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isOver
                                      ? const Color(0xFFDC2626)
                                      : (ratio > 0.8 ? const Color(0xFFF59E0B) : const Color(0xFF16A34A)),
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 10),
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          const SizedBox(height: 8),

                          // ACTION ROW: DIRECT OPTION TO SET / EDIT BUDGET
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Button to directly set/edit category budget
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isLocated ? const Color(0xFF0284C7) : const Color(0xFF0F766E),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                  elevation: 0,
                                ),
                                icon: Icon(isLocated ? Icons.edit_note : Icons.add, size: 16),
                                label: Text(
                                  isLocated ? 'Edit Target Budget' : 'Add Target Budget',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                onPressed: () => _showSetCategoryBudgetDialog(context, cat, controller),
                              ),

                              Row(
                                children: [
                                  if (isLocated)
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFDC2626)),
                                      tooltip: 'Clear ${cat.name} Target Budget',
                                      onPressed: () async {
                                        await controller.clearCategoryBudget(cat.name);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Target budget for ${cat.name} reset to ₹0'),
                                              backgroundColor: const Color(0xFFDC2626),
                                              behavior: SnackBarBehavior.floating,
                                              duration: const Duration(seconds: 2),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  if (recordCount > 0)
                                    TextButton.icon(
                                      style: TextButton.styleFrom(
                                        foregroundColor: const Color(0xFF64748B),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      ),
                                      icon: const Icon(Icons.receipt_long, size: 14),
                                      label: Text('$recordCount debits', style: const TextStyle(fontSize: 11)),
                                      onPressed: () => _showCategoryManageSheet(context, controller, cat),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildBudgetFilterChip(String key, String label, IconData icon, {Color? activeColor}) {
    final isSelected = _budgetFilter == key;
    final color = activeColor ?? const Color(0xFF0284C7);
    return InkWell(
      onTap: () => setState(() => _budgetFilter = key),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFCBD5E1),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? Colors.white : const Color(0xFF64748B)),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }



  // ===========================================================================
  // CATEGORIES VIEW (Matching User Screenshots with Budget & Savings Analysis)
  // ===========================================================================
  Widget _buildCategoriesPage(BuildContext context, ExpenseController controller) {
    return Container(
      color: const Color(0xFFFBFBF6), // Light Ivory/cream background
      child: ListView(
        padding: const EdgeInsets.only(bottom: 90),
        children: [
          // Category Target Budget Planner Banner
          InkWell(
            onTap: () => setState(() => _activeScreen = ActiveScreen.budget),
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.calculate_outlined, color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Category Target Budget Planner',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          'Allocate spending limits for each category to monitor sufficiency',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Budget Planner →',
                      style: TextStyle(color: Color(0xFF0369A1), fontWeight: FontWeight.w800, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 1. TOP HEADER SUMMARY: CREDIT, DEBIT & TOTAL SAVINGS
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: const BoxDecoration(
              color: Color(0xFFFBFBF6),
              border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
            ),
            child: Column(
              children: [
                Text(
                  '[ Cash Wallet Balance: ₹${controller.currentBalance.toStringAsFixed(2)} ]',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F5132),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text(
                          'TOTAL DEBIT',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF991B1B), letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '₹${controller.totalDebit.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFFDC2626)),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        const Text(
                          'TOTAL CREDIT',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF166534), letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '₹${controller.totalCredit.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF16A34A)),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        const Text(
                          'NET SAVED',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0F5132), letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '₹${controller.netSavedAmount.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0D9488)),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Expenditure Adequacy status banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: controller.totalAllocatedBudget <= 0
                        ? const Color(0xFFF1F5F9)
                        : (controller.overbudgetCategoryCount == 0
                            ? const Color(0xFFDCFCE7)
                            : const Color(0xFFFEE2E2)),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: controller.totalAllocatedBudget <= 0
                          ? const Color(0xFFE2E8F0)
                          : (controller.overbudgetCategoryCount == 0
                              ? const Color(0xFF86EFAC)
                              : const Color(0xFFFCA5A5)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        controller.totalAllocatedBudget <= 0
                            ? Icons.info_outline
                            : (controller.overbudgetCategoryCount == 0
                                ? Icons.check_circle
                                : Icons.warning_amber_rounded),
                        size: 16,
                        color: controller.totalAllocatedBudget <= 0
                            ? const Color(0xFF64748B)
                            : (controller.overbudgetCategoryCount == 0
                                ? const Color(0xFF16A34A)
                                : const Color(0xFFDC2626)),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          controller.budgetSufficiencySummary,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: controller.totalAllocatedBudget <= 0
                                ? const Color(0xFF475569)
                                : (controller.overbudgetCategoryCount == 0
                                    ? const Color(0xFF15803D)
                                    : const Color(0xFF991B1B)),
                          ),
                        ),
                      ),
                      if (controller.totalAllocatedBudget > 0 || controller.monthlyBudget > 0) ...[
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () async {
                            await controller.clearAllBudgets();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('All budgets and planned targets cleared!'),
                                  backgroundColor: Color(0xFFDC2626),
                                  behavior: SnackBarBehavior.floating,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDC2626).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFFDC2626).withValues(alpha: 0.3)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.delete_outline, size: 12, color: Color(0xFFDC2626)),
                                SizedBox(width: 2),
                                Text(
                                  'Clear Budgets',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFFDC2626),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. Income categories Section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
            child: Text(
              'Income categories (Credit)',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F5132),
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFCBD5E1), indent: 16, endIndent: 16),

          ...CategoryData.incomeCategories.map((cat) {
            final addedIncome = controller.getCategoryTotalAmount(cat.name, type: 'income');
            final count = controller.getCategoryTransactions(cat.name, type: 'income').length;
            return ListTile(
              leading: CircleAvatar(
                radius: 18,
                backgroundColor: cat.color,
                child: Icon(cat.icon, color: Colors.white, size: 20),
              ),
              title: Text(
                cat.name,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F5132)),
              ),
              subtitle: addedIncome > 0
                  ? Text(
                      'Added: +₹${addedIncome.toStringAsFixed(2)} ($count record${count == 1 ? '' : 's'})',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF16A34A)),
                    )
                  : const Text('₹0.00 (Tap to add credit)', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (addedIncome > 0) ...[
                    Text(
                      '+₹${addedIncome.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF16A34A)),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.manage_history, color: Color(0xFF0284C7), size: 22),
                      tooltip: 'Manage & Delete ${cat.name} Entries',
                      onPressed: () => _showCategoryManageSheet(context, controller, cat),
                    ),
                  ],
                  IconButton(
                    icon: const Icon(
                      Icons.add_circle_outline,
                      color: Color(0xFF0F5132),
                      size: 22,
                    ),
                    tooltip: 'Add ${cat.name} Income',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddTransactionPage(
                            controller: controller,
                            initialType: 'income',
                            initialCategory: cat.name,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              onTap: () {
                if (addedIncome > 0) {
                  _showCategoryManageSheet(context, controller, cat);
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddTransactionPage(
                        controller: controller,
                        initialType: 'income',
                        initialCategory: cat.name,
                      ),
                    ),
                  );
                }
              },
            );
          }),

          const SizedBox(height: 14),

          // 3. Expense categories Section (With Target Amount, Spent & Savings Progress)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'Expense categories (Debit & Target)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F5132),
                  ),
                ),
                Text(
                  'Target / Spent',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFCBD5E1), indent: 16, endIndent: 16),

          ...CategoryData.allExpenseCategories.map((cat) {
            final currentCat = CategoryData.getCategory(cat.name);
            final isNeed = currentCat.defaultNeedWant == 'need';
            final spentExpense = controller.getCategoryTotalAmount(currentCat.name);
            final targetBudget = controller.getCategoryBudget(currentCat.name);
            final isOver = targetBudget > 0 && spentExpense > targetBudget;
            final saved = targetBudget > 0 ? (targetBudget - spentExpense) : 0.0;
            final usageRatio = targetBudget > 0 ? (spentExpense / targetBudget).clamp(0.0, 1.0) : 0.0;
            final currentTxs = controller.getCategoryTransactions(currentCat.name, type: 'expense');
            final recordCount = currentTxs.length;

            return InkWell(
              onTap: () {
                if (recordCount > 0) {
                  _showCategoryManageSheet(context, controller, currentCat);
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddTransactionPage(
                        controller: controller,
                        initialType: 'expense',
                        initialCategory: currentCat.name,
                      ),
                    ),
                  );
                }
              },
              child: Container(
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: currentCat.color,
                            child: Icon(currentCat.icon, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      currentCat.name,
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F5132)),
                                    ),
                                    const SizedBox(width: 6),
                                    InkWell(
                                      onTap: () async {
                                        await controller.setCategoryClassification(currentCat.name, isNeed ? 'want' : 'need');
                                        setState(() {});
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: isNeed ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: isNeed ? const Color(0xFF15803D) : const Color(0xFFB45309), width: 0.5),
                                        ),
                                        child: Text(
                                          isNeed ? 'NEED' : 'WANT',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w900,
                                            color: isNeed ? const Color(0xFF15803D) : const Color(0xFFB45309),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    Text(
                                      'Spent: ₹${spentExpense.toStringAsFixed(0)}',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFDC2626)),
                                    ),
                                    if (recordCount > 0) ...[
                                      const Text(' • ', style: TextStyle(color: Color(0xFF94A3B8))),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEFF6FF),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: const Color(0xFF93C5FD), width: 0.5),
                                        ),
                                        child: Text(
                                          '$recordCount record${recordCount == 1 ? '' : 's'}',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF1D4ED8),
                                          ),
                                        ),
                                      ),
                                    ],
                                    if (targetBudget > 0) ...[
                                      const Text(' • ', style: TextStyle(color: Color(0xFF94A3B8))),
                                      Text(
                                        'Target: ₹${targetBudget.toStringAsFixed(0)}',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Savings / Over Budget Pill
                          if (targetBudget > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(
                                color: isOver ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isOver ? const Color(0xFFFCA5A5) : const Color(0xFF86EFAC),
                                  width: 0.5,
                                ),
                              ),
                              child: Text(
                                isOver
                                    ? 'Over by ₹${(spentExpense - targetBudget).toStringAsFixed(0)}'
                                    : 'Saved ₹${saved.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: isOver ? const Color(0xFFDC2626) : const Color(0xFF15803D),
                                ),
                              ),
                            ),
                          // Action Buttons: View Records, Target Budget, Clear Target, Add Transaction, Configure
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (recordCount > 0)
                                IconButton(
                                  icon: const Icon(Icons.receipt_long_outlined, color: Color(0xFF0284C7), size: 21),
                                  tooltip: 'View all $recordCount debits for ${currentCat.name}',
                                  onPressed: () => _showCategoryManageSheet(context, controller, currentCat),
                                ),
                              IconButton(
                                icon: const Icon(Icons.track_changes, color: Color(0xFF0284C7), size: 20),
                                tooltip: 'Set Target Budget for ${currentCat.name}',
                                onPressed: () => _showSetCategoryBudgetDialog(context, currentCat, controller),
                              ),
                              if (targetBudget > 0)
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Color(0xFFDC2626), size: 20),
                                  tooltip: 'Clear ${currentCat.name} Target Budget',
                                  onPressed: () async {
                                    await controller.clearCategoryBudget(currentCat.name);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          backgroundColor: const Color(0xFFDC2626),
                                          content: Text('Target budget for ${currentCat.name} cleared'),
                                          behavior: SnackBarBehavior.floating,
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              IconButton(
                                icon: const Icon(
                                  Icons.add_circle_outline,
                                  color: Color(0xFF0F5132),
                                  size: 22,
                                ),
                                tooltip: 'Add ${currentCat.name} Expense',
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AddTransactionPage(
                                        controller: controller,
                                        initialType: 'expense',
                                        initialCategory: currentCat.name,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.more_horiz, color: Color(0xFF64748B), size: 20),
                                tooltip: 'Configure Classification',
                                onPressed: () => _showConfigurePurposeSheet(context, currentCat, controller),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (targetBudget > 0) ...[
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: usageRatio,
                            minHeight: 4,
                            backgroundColor: const Color(0xFFE2E8F0),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isOver
                                  ? const Color(0xFFDC2626)
                                  : (usageRatio > 0.8 ? const Color(0xFFF59E0B) : const Color(0xFF16A34A)),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 20),

          // + ADD NEW CATEGORY BUTTON
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0F5132),
                side: const BorderSide(color: Color(0xFF0F5132), width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.add_circle_outline, size: 20),
              label: const Text(
                'ADD NEW CATEGORY',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.5),
              ),
              onPressed: () => _showAddCategoryDialog(context),
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // DIALOG TO SET TARGET BUDGET / PLANNED AMOUNT FOR A CATEGORY
  void _showSetCategoryBudgetDialog(BuildContext context, SimpleCategory cat, ExpenseController controller) {
    final currentBudget = controller.getCategoryBudget(cat.name);
    final spentAmount = controller.getCategoryTotalAmount(cat.name);
    final budgetCtrl = TextEditingController(
      text: currentBudget > 0 ? currentBudget.toStringAsFixed(0) : '',
    );
    String selectedNeedWant = CategoryData.getCategoryNeedWant(cat.name);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          final isNeed = selectedNeedWant == 'need';
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, size: 20, color: Color(0xFF334155)),
                  tooltip: 'Back',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => Navigator.pop(ctx),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 16,
                  backgroundColor: cat.color,
                  child: Icon(cat.icon, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Allocate Budget: ${cat.name}',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Category Allocation • ${isNeed ? "NEED (Compulsory)" : "WANT (Optional)"}',
                        style: TextStyle(
                          fontSize: 10,
                          color: isNeed ? const Color(0xFF15803D) : const Color(0xFFB45309),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline, size: 16, color: Color(0xFF15803D)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Allocate a particular target budget amount for ${cat.name} and classify whether it is a Compulsory Need or an Optional Want. (This does NOT add debit expenses).',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF166534)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // USER CLASSIFICATION: NEED (COMPULSORY) VS WANT (OPTIONAL)
                  const Text(
                    'Category Classification (User Choice):',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Classify whether spending on this category is an essential Need or an optional Want:',
                    style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            setDialogState(() {
                              selectedNeedWant = 'need';
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                            decoration: BoxDecoration(
                              color: isNeed ? const Color(0xFFDCFCE7) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isNeed ? const Color(0xFF15803D) : const Color(0xFFCBD5E1),
                                width: isNeed ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  isNeed ? Icons.check_circle : Icons.radio_button_unchecked,
                                  size: 16,
                                  color: isNeed ? const Color(0xFF15803D) : const Color(0xFF94A3B8),
                                ),
                                const SizedBox(width: 6),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'NEED',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                        color: isNeed ? const Color(0xFF15803D) : const Color(0xFF475569),
                                      ),
                                    ),
                                    Text(
                                      'Compulsory',
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w500,
                                        color: isNeed ? const Color(0xFF166534) : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            setDialogState(() {
                              selectedNeedWant = 'want';
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                            decoration: BoxDecoration(
                              color: !isNeed ? const Color(0xFFFEF3C7) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: !isNeed ? const Color(0xFFD97706) : const Color(0xFFCBD5E1),
                                width: !isNeed ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  !isNeed ? Icons.star : Icons.radio_button_unchecked,
                                  size: 16,
                                  color: !isNeed ? const Color(0xFFD97706) : const Color(0xFF94A3B8),
                                ),
                                const SizedBox(width: 6),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'WANT',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                        color: !isNeed ? const Color(0xFFB45309) : const Color(0xFF475569),
                                      ),
                                    ),
                                    Text(
                                      'Optional',
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w500,
                                        color: !isNeed ? const Color(0xFF92400E) : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Actual Spent: ₹${spentAmount.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: spentAmount > 0 ? const Color(0xFFDC2626) : const Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        currentBudget > 0
                            ? 'Target: ₹${currentBudget.toStringAsFixed(0)}'
                            : 'No Target Set',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: currentBudget > 0 ? const Color(0xFF0284C7) : const Color(0xFFB45309),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: budgetCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    autofocus: true,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    onChanged: (_) => setDialogState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Particular Target for ${cat.name} (₹)',
                      hintText: 'e.g. 3000',
                      prefixIcon: const Icon(Icons.currency_rupee, color: Color(0xFF0F766E)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text('Quick Presets:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (spentAmount > 0)
                        ActionChip(
                          backgroundColor: const Color(0xFFFEF3C7),
                          label: Text(
                            'Match Spent (₹${spentAmount.toStringAsFixed(0)})',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                          ),
                          onPressed: () {
                            budgetCtrl.text = spentAmount.toStringAsFixed(0);
                            setDialogState(() {});
                          },
                        ),
                      ...[500.0, 1000.0, 2000.0, 3000.0, 5000.0, 10000.0].map((amt) {
                        return ActionChip(
                          label: Text('₹${amt.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11)),
                          onPressed: () {
                            budgetCtrl.text = amt.toStringAsFixed(0);
                            setDialogState(() {});
                          },
                        );
                      }),
                    ],
                  ),
                  if (currentBudget > 0) ...[
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () async {
                        await controller.clearCategoryBudget(cat.name);
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: const Color(0xFFDC2626),
                              content: Text('Target budget for ${cat.name} cleared to ₹0'),
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.delete_outline, size: 14, color: Color(0xFFDC2626)),
                            SizedBox(width: 4),
                            Text(
                              'Clear Target (Reset to ₹0)',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFDC2626),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton.icon(
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text('Back'),
                onPressed: () => Navigator.pop(ctx),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () async {
                  final val = double.tryParse(budgetCtrl.text.trim()) ?? 0.0;
                  await controller.setCategoryBudget(cat.name, val);
                  await controller.setCategoryClassification(cat.name, selectedNeedWant);
                  setState(() {});
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xFF0F766E),
                        content: Text(val > 0
                            ? 'Target for ${cat.name} set to ₹${val.toStringAsFixed(0)} • Classified as ${selectedNeedWant.toUpperCase()}'
                            : '${cat.name} classified as ${selectedNeedWant.toUpperCase()} (Target: ₹0)'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                child: const Text('SAVE ALLOCATION', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showConfigurePurposeSheet(BuildContext context, SimpleCategory cat, ExpenseController controller) {
    final currentTag = CategoryData.getCategoryNeedWant(cat.name);
    final isNeed = currentTag == 'need';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, size: 20, color: Color(0xFF334155)),
                  tooltip: 'Back',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => Navigator.pop(ctx),
                ),
                const SizedBox(width: 8),
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
                      Text(cat.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('Configure default classification', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Select default purpose type for this category:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isNeed ? const Color(0xFF15803D) : const Color(0xFFF1F5F9),
                      foregroundColor: isNeed ? Colors.white : const Color(0xFF334155),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: Icon(Icons.check_circle, size: 18, color: isNeed ? Colors.white : const Color(0xFF15803D)),
                    label: const Text('NEED (Compulsory)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    onPressed: () async {
                      await controller.setCategoryClassification(cat.name, 'need');
                      setState(() {});
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: !isNeed ? const Color(0xFFD97706) : const Color(0xFFF1F5F9),
                      foregroundColor: !isNeed ? Colors.white : const Color(0xFF334155),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: Icon(Icons.star, size: 18, color: !isNeed ? Colors.white : const Color(0xFFD97706)),
                    label: const Text('WANT (Optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    onPressed: () async {
                      await controller.setCategoryClassification(cat.name, 'want');
                      setState(() {});
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: Color(0xFF0284C7)),
                  foregroundColor: const Color(0xFF0284C7),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.add),
                label: Text('Add Expense for ${cat.name}'),
                onPressed: () {
                  Navigator.pop(ctx);
                  _openAddTransaction(context, controller, type: 'expense');
                },
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    final catNameCtrl = TextEditingController();
    String categoryType = 'expense';
    String needWant = 'need';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, size: 20, color: Color(0xFF334155)),
                tooltip: 'Back',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => Navigator.pop(ctx),
              ),
              const SizedBox(width: 8),
              const Text('Add New Category', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: catNameCtrl,
                textCapitalization: TextCapitalization.words,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Category Name',
                  hintText: 'e.g. Pet Care, Internet, Gym',
                  prefixIcon: Icon(Icons.label),
                ),
              ),
              const SizedBox(height: 14),
              const Text('Type:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('Expense'),
                    selected: categoryType == 'expense',
                    onSelected: (val) => setDlgState(() => categoryType = 'expense'),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Income'),
                    selected: categoryType == 'income',
                    onSelected: (val) => setDlgState(() => categoryType = 'income'),
                  ),
                ],
              ),
              if (categoryType == 'expense') ...[
                const SizedBox(height: 12),
                const Text('Purpose Classification:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Need (Compulsory)'),
                      selected: needWant == 'need',
                      selectedColor: const Color(0xFF16A34A),
                      labelStyle: TextStyle(color: needWant == 'need' ? Colors.white : Colors.black),
                      onSelected: (val) => setDlgState(() => needWant = 'need'),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Want (Not Necessary)'),
                      selected: needWant == 'want',
                      selectedColor: const Color(0xFFD97706),
                      labelStyle: TextStyle(color: needWant == 'want' ? Colors.white : Colors.black),
                      onSelected: (val) => setDlgState(() => needWant = 'want'),
                    ),
                  ],
                ),
              ],
            ],
          ),
          actions: [
            TextButton.icon(
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Back'),
              onPressed: () => Navigator.pop(ctx),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7), foregroundColor: Colors.white),
              onPressed: () {
                final name = catNameCtrl.text.trim();
                if (name.isNotEmpty) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Category "$name" is ready to use in new transactions!')),
                  );
                }
              },
              child: const Text('Add Category'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryManageSheet(BuildContext context, ExpenseController controller, SimpleCategory cat) {
    final isIncome = !cat.isExpense;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) {
          final currentTxs = controller.getCategoryTransactions(cat.name, type: isIncome ? 'income' : 'expense');
          final currentTotal = controller.getCategoryTotalAmount(cat.name, type: isIncome ? 'income' : 'expense');

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
                      IconButton(
                        icon: const Icon(Icons.arrow_back, size: 20, color: Color(0xFF334155)),
                        tooltip: 'Back',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                      const SizedBox(width: 8),
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
                              isIncome
                                  ? 'Total Credit: +₹${currentTotal.toStringAsFixed(2)} (${currentTxs.length} record${currentTxs.length == 1 ? '' : 's'})'
                                  : 'Total Spent: ₹${currentTotal.toStringAsFixed(2)} (${currentTxs.length} debit${currentTxs.length == 1 ? '' : 's'})',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isIncome ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
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
                                title: Text('Reset ${cat.name} ${isIncome ? 'Credits' : 'Expenses'}'),
                                content: Text('Delete all ${currentTxs.length} recorded ${isIncome ? 'credits' : 'expenses'} for "${cat.name}"?'),
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
                              await controller.deleteTransactionsForCategory(cat.name, type: isIncome ? 'income' : 'expense');
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

                  // Button to Add New Transaction
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isIncome ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.add_circle_outline, size: 18),
                      label: Text(
                        isIncome ? '+ ADD ${cat.name.toUpperCase()} CREDIT' : '+ ADD ${cat.name.toUpperCase()} EXPENSE',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddTransactionPage(
                              controller: controller,
                              initialType: isIncome ? 'income' : 'expense',
                              initialCategory: cat.name,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 14),

                  if (currentTxs.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'No ${isIncome ? 'credit' : 'expense'} transactions recorded for ${cat.name} yet',
                          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                        ),
                      ),
                    )
                  else ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recorded ${cat.name} ${isIncome ? 'Credits' : 'Debits'} (${currentTxs.length}):',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569)),
                        ),
                        Text(
                          'Each amount added',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontStyle: FontStyle.italic),
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
                                  backgroundColor: (isIncome ? const Color(0xFF16A34A) : const Color(0xFFDC2626)).withValues(alpha: 0.12),
                                  child: Icon(
                                    isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                                    size: 16,
                                    color: isIncome ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
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
                                          if (!isIncome)
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
                                  '${isIncome ? '+' : '-'}₹${item.amount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: isIncome ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 16, color: Color(0xFF0284C7)),
                                  tooltip: 'Edit this debit',
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => AddTransactionPage(
                                          controller: controller,
                                          existingItem: item,
                                        ),
                                      ),
                                    );
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
                                      await controller.deleteExpense(item.id);
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

  // Navigation helpers
  void _openAddTransaction(BuildContext context, ExpenseController controller, {String? type, DateTime? initialDate}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddTransactionPage(
          controller: controller,
          initialAccount: controller.selectedAccount,
          initialType: type ?? 'expense',
          existingItem: null,
        ),
      ),
    );
  }

  // Helper row widget for tables with interactive details
  Widget _buildDataRow(
    String label,
    double amount, {
    required bool isGreen,
    VoidCallback? onTap,
    String? subtitle,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                  ),
                ],
              ],
            ),
            Row(
              children: [
                Text(
                  amount < 0 ? '-₹${amount.abs().toStringAsFixed(2)}' : '₹${amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: isGreen ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                  ),
                ),
                if (onTap != null) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.chevron_right, size: 18, color: Color(0xFF94A3B8)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showPeriodExpensesDetailSheet(
    BuildContext context,
    ExpenseController controller,
    String title,
    String subtitle,
    List<ExpenseItem> items,
    double totalAmount,
  ) {
    final needAmt = items.where((e) => e.isNeed).fold(0.0, (sum, e) => sum + e.amount);
    final wantAmt = items.where((e) => e.isWant).fold(0.0, (sum, e) => sum + e.amount);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.75,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0C4A6E), Color(0xFF0284C7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TOTAL EXPENSES',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFBAE6FD),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '₹${totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${items.length} ${items.length == 1 ? "transaction" : "transactions"}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFFE0F2FE),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'NEED: ₹${needAmt.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF86EFAC),
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'WANT: ₹${wantAmt.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFDE68A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 16, color: Color(0xFFF1F5F9)),
              Expanded(
                child: items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.receipt_long_outlined, size: 48, color: Color(0xFF94A3B8)),
                            SizedBox(height: 10),
                            Text(
                              'No expenses recorded for this period',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        itemCount: items.length,
                        separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        itemBuilder: (context, idx) {
                          final item = items[idx];
                          final cat = CategoryData.getCategory(item.category);
                          final dateStr = DateFormat('dd MMM, hh:mm a').format(item.date);

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: cat.color.withValues(alpha: 0.15),
                                  child: Icon(cat.icon, size: 18, color: cat.color),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        style: const TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF1E293B),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Text(
                                            '${item.category} • $dateStr',
                                            style: const TextStyle(
                                              fontSize: 10.5,
                                              color: Color(0xFF64748B),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: item.isNeed
                                                  ? const Color(0xFFDCFCE7)
                                                  : const Color(0xFFFEF3C7),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              item.isNeed ? 'NEED' : 'WANT',
                                              style: TextStyle(
                                                fontSize: 8.5,
                                                fontWeight: FontWeight.bold,
                                                color: item.isNeed
                                                    ? const Color(0xFF166534)
                                                    : const Color(0xFF92400E),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '-₹${item.amount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFFDC2626),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }


  Widget _buildDrawer(BuildContext context, ExpenseController controller) {
    final user = AuthService().currentUser;
    final userName = user?.displayName ?? 'Expense Manager';
    final userEmail = user?.email ?? 'Logged in user';
    final initial = (userName.isNotEmpty ? userName[0] : 'U').toUpperCase();

    return Drawer(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.white.withValues(alpha: 0.25),
                            child: Text(
                              initial,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  userEmail,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Cash, Credit & Savings Manager',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.notes, color: Color(0xFF0284C7)),
                  title: const Text('Summary Dashboard'),
                  onTap: () {
                    setState(() => _activeScreen = ActiveScreen.summary);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.receipt_long, color: Color(0xFF16A34A)),
                  title: const Text('Credit & Debit Records'),
                  onTap: () {
                    setState(() => _activeScreen = ActiveScreen.activity);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.calculate_outlined, color: Color(0xFF0284C7)),
                  title: const Text('Target Budget Planner'),
                  selected: _activeScreen == ActiveScreen.budget,
                  onTap: () {
                    setState(() => _activeScreen = ActiveScreen.budget);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.label, color: Color(0xFF0F766E)),
                  title: const Text('Categories & Records'),
                  selected: _activeScreen == ActiveScreen.categories,
                  onTap: () {
                    setState(() => _activeScreen = ActiveScreen.categories);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.pie_chart, color: Color(0xFF475569)),
                  title: const Text('Expense & Savings Charts'),
                  onTap: () {
                    setState(() => _activeScreen = ActiveScreen.chart);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.calendar_month, color: Color(0xFFD97706)),
                  title: const Text('Calendar View'),
                  onTap: () {
                    setState(() => _activeScreen = ActiveScreen.calendar);
                    Navigator.pop(context);
                  },
                ),
                if (controller.hasActiveBudget)
                  ListTile(
                    leading: const Icon(Icons.delete_sweep_outlined, color: Color(0xFFDC2626)),
                    title: const Text('Clear All Budgets', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w600)),
                    onTap: () async {
                      Navigator.pop(context);
                      await controller.clearAllBudgets();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('All budgets and planned targets cleared'),
                            backgroundColor: Color(0xFFDC2626),
                            behavior: SnackBarBehavior.floating,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  ),
                if (controller.allTransactions.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.delete_forever_outlined, color: Color(0xFFDC2626)),
                    title: const Text('Clear All Transactions', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w600)),
                    onTap: () async {
                      Navigator.pop(context);
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Clear All Transactions?'),
                          content: const Text('Are you sure you want to delete all transaction records? This action cannot be undone.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: TextButton.styleFrom(foregroundColor: const Color(0xFFDC2626)),
                              child: const Text('Clear All'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await controller.clearAllExpenses();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('All transactions deleted and state saved'),
                              backgroundColor: Color(0xFFDC2626),
                              behavior: SnackBarBehavior.floating,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.cloud_sync_rounded, color: Color(0xFF0284C7)),
                  title: const Text('Sync with Cloud Firestore'),
                  subtitle: const Text('Synchronize transactions & budgets with Cloud Firestore', style: TextStyle(fontSize: 11)),
                  onTap: () async {
                    Navigator.pop(context);
                    await controller.syncWithFirestore();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Cloud Firestore synchronization complete!'),
                          backgroundColor: Color(0xFF0284C7),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.receipt_long_rounded, color: Color(0xFF16A34A)),
                  title: const Text('Export Statement & Excel/PDF Report'),
                  onTap: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (_) => ExportStatementDialog(controller: controller),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.notifications_active_rounded, color: Color(0xFFD97706)),
                  title: const Text('Daily Spending Reminders & Alerts'),
                  onTap: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (_) => ReminderDialog(controller: controller),
                    );
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444)),
            title: const Text(
              'Sign Out',
              style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold),
            ),
            onTap: () {
              Navigator.pop(context);
              _confirmSignOut(context);
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFFEF4444)),
            SizedBox(width: 8),
            Text('Sign Out'),
          ],
        ),
        content: const Text('Are you sure you want to sign out from your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthService().signOut();
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _showBudgetDialog(BuildContext context, ExpenseController controller) {
    final hasBudget = controller.monthlyBudget > 0 || controller.totalAllocatedBudget > 0;
    final textCtrl = TextEditingController(
      text: controller.monthlyBudget > 0 ? controller.monthlyBudget.toStringAsFixed(0) : '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, size: 20, color: Color(0xFF334155)),
              tooltip: 'Back',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => Navigator.pop(ctx),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.calculate_outlined, color: Color(0xFF0284C7)),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Set Monthly Budget / Target', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your total planned budget target for the month. This sets your planned target ceiling and will NOT automatically split into categories. You allocate particular amounts to each category individually.',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: textCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: 'Monthly Planned Budget (₹)',
                hintText: 'e.g. 25000',
                prefixIcon: const Icon(Icons.currency_rupee, color: Color(0xFF0284C7)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            if (hasBudget) ...[
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  await controller.clearAllBudgets();
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Monthly budget and category targets cleared!'),
                        backgroundColor: Color(0xFFDC2626),
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.delete_outline, size: 16, color: Color(0xFFDC2626)),
                      SizedBox(width: 6),
                      Text(
                        'Clear Budget (One-Click Reset to ₹0)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (hasBudget)
            TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFDC2626),
              ),
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('Clear Budget', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () async {
                await controller.clearAllBudgets();
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Monthly budget and category targets cleared!'),
                      backgroundColor: Color(0xFFDC2626),
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
          TextButton.icon(
            icon: const Icon(Icons.arrow_back, size: 16),
            label: const Text('Back'),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final val = double.tryParse(textCtrl.text.trim());
              if (val != null && val > 0) {
                await controller.updateMonthlyBudget(val);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Monthly Planned Budget updated to ₹${val.toStringAsFixed(0)}'),
                      backgroundColor: const Color(0xFF10B981),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              } else if (val != null && val == 0) {
                await controller.clearAllBudgets();
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Monthly budget cleared!'),
                      backgroundColor: Color(0xFFDC2626),
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
            child: const Text('Save Budget'),
          ),
        ],
      ),
    );
  }

  void _showDayExpensesSheet(BuildContext context, ExpenseController controller, DateTime date, List<ExpenseItem> dayExpenses) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(DateFormat('dd MMMM yyyy').format(date), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...dayExpenses.map((item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(CategoryData.getCategory(item.category).icon, color: CategoryData.getCategory(item.category).color),
                  title: Row(
                    children: [
                      Expanded(child: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w700))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: item.isNeed ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.isNeed ? 'NEED' : 'WANT',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: item.isNeed ? const Color(0xFF15803D) : const Color(0xFFB45309),
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(item.category),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('-₹${item.amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFFDC2626))),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20, color: Color(0xFF94A3B8)),
                        onPressed: () {
                          controller.deleteExpense(item.id);
                          Navigator.pop(ctx);
                        },
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  void _showSearchDialog(BuildContext context, ExpenseController controller) {
    showSearch(
      context: context,
      delegate: _ExpenseSearchDelegate(controller),
    );
  }
}

class _ExpenseSearchDelegate extends SearchDelegate {
  final ExpenseController controller;

  _ExpenseSearchDelegate(this.controller);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [IconButton(icon: const Icon(Icons.clear), onPressed: () => query = '')];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, null));
  }

  @override
  Widget buildResults(BuildContext context) => _buildSearchResults();

  @override
  Widget buildSuggestions(BuildContext context) => _buildSearchResults();

  Widget _buildSearchResults() {
    final results = controller.expenses
        .where((e) => e.title.toLowerCase().contains(query.toLowerCase()) || e.category.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (ctx, idx) {
        final item = results[idx];
        return ListTile(
          leading: Icon(CategoryData.getCategory(item.category).icon, color: CategoryData.getCategory(item.category).color),
          title: Row(
            children: [
              Expanded(child: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: item.isNeed ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  item.isNeed ? 'NEED' : 'WANT',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: item.isNeed ? const Color(0xFF15803D) : const Color(0xFFB45309),
                  ),
                ),
              ),
            ],
          ),
          subtitle: Text('${item.category} • ${item.account}'),
          trailing: Text('-₹${item.amount.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold)),
        );
      },
    );
  }
}

// ===========================================================================
// ANIMATION COMPONENTS
// ===========================================================================
class AnimatedFadeSlide extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final double offsetDistance;

  const AnimatedFadeSlide({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.offsetDistance = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, offsetDistance * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class AnimatedPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const AnimatedPressable({
    super.key,
    required this.child,
    this.onTap,
  });

  @override
  State<AnimatedPressable> createState() => _AnimatedPressableState();
}

class _AnimatedPressableState extends State<AnimatedPressable> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) {
        if (widget.onTap != null) setState(() => _isPressed = true);
      },
      onTapUp: (_) {
        if (_isPressed) setState(() => _isPressed = false);
      },
      onTapCancel: () {
        if (_isPressed) setState(() => _isPressed = false);
      },
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}