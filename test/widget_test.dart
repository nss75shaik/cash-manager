import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:expense/controllers/expense_controller.dart';
import 'package:expense/models/category_data.dart';
import 'package:expense/theme/app_theme.dart';
import 'package:expense/views/home_page.dart';
import 'package:expense/views/export_statement_dialog.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    CategoryData.resetCustomClassifications();
  });

  testWidgets('Verify Cash Manager Dashboard and Credit/Debit buttons', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final controller = ExpenseController();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: HomePage(controller: controller),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));

    // Verify Title
    expect(find.text('Cash Manager'), findsWidgets);

    // Verify Credit and Debit buttons
    expect(find.text('Add credit details'), findsOneWidget);
    expect(find.text('Add debit details'), findsOneWidget);
  });

  testWidgets('Verify Export Statement Dialog has Excel and PDF download buttons', (WidgetTester tester) async {
    final controller = ExpenseController();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: ExportStatementDialog(controller: controller),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Dialog title & subtitle
    expect(find.text('Export Statement'), findsOneWidget);
    expect(find.text('Download Excel (.xlsx) & PDF (.pdf) Reports'), findsOneWidget);

    // Verify Download Excel and Download PDF buttons
    expect(find.text('Download Excel'), findsOneWidget);
    expect(find.text('Download PDF'), findsOneWidget);

    // Verify preview and copy buttons
    expect(find.text('Preview / Print'), findsOneWidget);
    expect(find.text('Copy CSV'), findsOneWidget);
  });

  testWidgets('Verify Budget Planner navigation from dashboard', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final controller = ExpenseController();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: HomePage(controller: controller),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));

    // Tap Budget Planner -> on target budget card
    final plannerFinder = find.text('Budget Planner →');
    expect(plannerFinder, findsOneWidget);
    await tester.tap(plannerFinder);
    await tester.pumpAndSettle();

    // Verify we are on Target Budget Planner screen
    expect(find.text('Target Budget Planner'), findsWidgets);
  });
}
