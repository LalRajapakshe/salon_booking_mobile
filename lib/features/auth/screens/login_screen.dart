import 'package:flutter/material.dart';

import '../../../shared/theme/theme.dart';
import '../widgets/login_form.dart';
import '../widgets/login_header.dart';
import '../widgets/login_logo.dart';
import '../../dashboard/screens/dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _togglePassword() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _toggleRememberMe(bool? value) {
    setState(() {
      _rememberMe = value ?? false;
    });
  }

  Future<void> _login() async {
  if (!_formKey.currentState!.validate()) {
    return;
  }

  setState(() {
    _isLoading = true;
  });

  // Temporary login delay
  await Future.delayed(const Duration(seconds: 1));

  if (!mounted) return;

  setState(() {
    _isLoading = false;
  });

  Navigator.of(context).pushReplacement(
    MaterialPageRoute(
      builder: (_) => DashboardScreen(),
    ),
  );
}



  void _forgotPassword() {
    // TODO:
    // Navigate to Forgot Password Screen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.spaceXL),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 420,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const LoginLogo(),

                  const SizedBox(height: AppDimensions.spaceXL),

                  const LoginHeader(),

                  const SizedBox(height: AppDimensions.spaceXL),

                  LoginForm(
                    formKey: _formKey,
                    usernameController: _usernameController,
                    passwordController: _passwordController,
                    obscurePassword: _obscurePassword,
                    rememberMe: _rememberMe,
                    isLoading: _isLoading,
                    onTogglePassword: _togglePassword,
                    onToggleRememberMe: _toggleRememberMe,
                    onLoginPressed: _login,
                    onForgotPassword: _forgotPassword,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}