import 'package:flutter/material.dart';

import '../../../shared/theme/theme.dart';
import '../../../shared/widgets/widgets.dart';

class LoginForm extends StatelessWidget {
  const LoginForm({
    super.key,
    required this.usernameController,
    required this.passwordController,
    this.tenantCodeController,
    required this.formKey,
    this.isLoading = false,
    this.obscurePassword = true,
    this.rememberMe = false,
    this.onToggleRememberMe,
    this.onTogglePassword,
    this.onLoginPressed,
    this.onForgotPassword,
  });

  final GlobalKey<FormState> formKey;

  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final TextEditingController? tenantCodeController;

  final bool isLoading;
  final bool obscurePassword;
  final bool rememberMe;

  final VoidCallback? onTogglePassword;
  final ValueChanged<bool?>? onToggleRememberMe;
  final VoidCallback? onLoginPressed;
  final VoidCallback? onForgotPassword;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [

          AppTextField(
            controller: usernameController,
            labelText: 'Username',
            hintText: 'Enter your username',
            prefixIcon: Icons.person_outline,
            keyboardType: TextInputType.text,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Username is required';
              }
              return null;
            },
          ),

          const SizedBox(height: AppDimensions.spaceL),

          AppTextField(
            controller: passwordController,
            labelText: 'Password',
            hintText: 'Enter your password',
            prefixIcon: Icons.lock_outline,
            obscureText: obscurePassword,
            suffixIcon: obscurePassword
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            onSuffixIconPressed: onTogglePassword,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Password is required';
              }

              return null;
            },
          ),

          if (tenantCodeController != null) ...[
            const SizedBox(height: AppDimensions.spaceM),
            AppTextField(
              controller: tenantCodeController!,
              labelText: 'Tenant code',
              hintText: 'Only if your username is used by more than one salon',
              prefixIcon: Icons.apartment_outlined,
            ),
          ],

          const SizedBox(height: AppDimensions.spaceM),

          Row(
            children: [

              Checkbox(
                value: rememberMe,
                onChanged: onToggleRememberMe,
              ),

              const Text('Remember Me'),

              const Spacer(),

              TextButton(
                onPressed: onForgotPassword,
                child: const Text('Forgot Password?'),
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.spaceL),

          AppPrimaryButton(
            text: 'Login',
            isLoading: isLoading,
            onPressed: onLoginPressed,
          ),
        ],
      ),
    );
  }
}