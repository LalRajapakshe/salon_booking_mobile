import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_text_styles.dart';
import 'app_primary_button.dart';

class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? buttonText;
  final VoidCallback? onPressed;

  const AppEmptyState({
    super.key,
    this.icon = Icons.inbox_outlined,
    this.title = 'No Data Found',
    this.message = 'There is nothing to display at the moment.',
    this.buttonText,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spaceL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 80,
              color: AppColors.subtitle,
            ),

            const SizedBox(
              height: AppDimensions.spaceL,
            ),

            Text(
              title,
              style: AppTextStyles.sectionTitle,
              textAlign: TextAlign.center,
            ),

            const SizedBox(
              height: AppDimensions.spaceS,
            ),

            Text(
              message,
              style: AppTextStyles.body,
              textAlign: TextAlign.center,
            ),

            if (buttonText != null && onPressed != null) ...[
              const SizedBox(
                height: AppDimensions.spaceXL,
              ),

              AppPrimaryButton(
                text: buttonText!,
                onPressed: onPressed,
                width: 180,
              ),
            ],
          ],
        ),
      ),
    );
  }
}