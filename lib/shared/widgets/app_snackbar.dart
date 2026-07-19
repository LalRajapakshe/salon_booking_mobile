import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AppSnackBar {
  AppSnackBar._();

  static void success(
    BuildContext context,
    String message,
  ) {
    _show(
      context,
      message,
      AppColors.success,
      Icons.check_circle_outline,
    );
  }

  static void error(
    BuildContext context,
    String message,
  ) {
    _show(
      context,
      message,
      AppColors.error,
      Icons.error_outline,
    );
  }

  static void warning(
    BuildContext context,
    String message,
  ) {
    _show(
      context,
      message,
      AppColors.warning,
      Icons.warning_amber_rounded,
    );
  }

  static void info(
    BuildContext context,
    String message,
  ) {
    _show(
      context,
      message,
      AppColors.primary,
      Icons.info_outline,
    );
  }

  static void _show(
    BuildContext context,
    String message,
    Color backgroundColor,
    IconData icon,
  ) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: backgroundColor,
          duration: const Duration(seconds: 3),
          content: Row(
            children: [
              Icon(
                icon,
                color: Colors.white,
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }
}