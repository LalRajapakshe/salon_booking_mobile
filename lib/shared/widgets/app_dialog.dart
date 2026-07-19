import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_text_styles.dart';
import 'app_primary_button.dart';
import 'app_secondary_button.dart';

class AppDialog {
  AppDialog._();

  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'OK',
    String cancelText = 'Cancel',
    IconData icon = Icons.info_outline,
    Color iconColor = AppColors.primary,
    bool showCancelButton = true,
    VoidCallback? onConfirm,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              AppDimensions.radiusL,
            ),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),

          title: Row(
            children: [
              Icon(
                icon,
                color: iconColor,
                size: 28,
              ),
              const SizedBox(width: AppDimensions.spaceM),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.sectionTitle,
                ),
              ),
            ],
          ),

          content: Text(
            message,
            style: AppTextStyles.body,
          ),

          actions: [
            if (showCancelButton)
              SizedBox(
                width: 110,
                child: AppSecondaryButton(
                  text: cancelText,
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                ),
              ),

            SizedBox(
              width: 110,
              child: AppPrimaryButton(
                text: confirmText,
                onPressed: () {
                  Navigator.of(context).pop(true);

                  if (onConfirm != null) {
                    onConfirm();
                  }
                },
              ),
            ),
          ],
        );
      },
    );
  }
}