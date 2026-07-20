import 'package:flutter/material.dart';

import '../../../shared/theme/theme.dart';

class LoginLogo extends StatelessWidget {
  const LoginLogo({
    super.key,
    this.logo,
    this.appName = 'Salon Booking ERP',
  });

  final Widget? logo;
  final String appName;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        logo ??
            Container(
              height: 90,
              width: 90,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.content_cut_rounded,
                color: Colors.white,
                size: 48,
              ),
            ),

        const SizedBox(height: AppDimensions.spaceL),

        Text(
          appName,
          style: AppTextStyles.pageTitle,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}