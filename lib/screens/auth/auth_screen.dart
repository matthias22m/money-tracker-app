import 'package:flutter/material.dart';
// import 'package:money_tracker_app/screens/auth/jwt_demo_screen.dart';
import 'login_page.dart';
import 'signup_page.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _showLoginPage = true;

  void _togglePages() {
    setState(() {
      _showLoginPage = !_showLoginPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showLoginPage) {
      return LoginPage(showSignupPage: _togglePages);
    } else {
      return SignupPage(showLoginPage: _togglePages);
    }
  }
}
