import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../controllers/expense_controller.dart';
import '../../services/auth_service.dart';
import '../home_page.dart';
import 'login_page.dart';

class AuthWrapper extends StatelessWidget {
  final ExpenseController controller;

  const AuthWrapper({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        // While Firebase is checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFF8FAFC),
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF0284C7),
              ),
            ),
          );
        }

        // If user is authenticated, show the Main Expense Home Page
        if (snapshot.hasData && snapshot.data != null) {
          return HomePage(controller: controller);
        }

        // Otherwise show the Login Page
        return const LoginPage();
      },
    );
  }
}
