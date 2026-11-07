import 'package:flutter/material.dart';
import '../controllers/expense_controller.dart';
import 'home_page.dart';

// Redirect to simplified HomePage
class ReportsPage extends StatelessWidget {
  final ExpenseController controller;
  final bool showBackButton;

  const ReportsPage({
    super.key,
    required this.controller,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return HomePage(controller: controller);
  }
}
