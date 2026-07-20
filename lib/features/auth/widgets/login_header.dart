import 'package:flutter/material.dart';

import '../../../shared/theme/theme.dart';

class LoginHeader extends StatelessWidget {
  const LoginHeader({
    super.key,
    this.title = 'Welcome Back!',
    this.subtitle = 'Sign in to continue to your account.',
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppTextStyles.sectionTitle,
        ),

        const SizedBox(
          height: AppDimensions.spaceS,
        ),

        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: AppTextStyles.body.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}