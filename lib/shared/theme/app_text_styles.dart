import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // ==========================================================
  // PAGE TITLES
  // ==========================================================

  static const TextStyle pageTitle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.heading,
  );

  static const TextStyle pageSubtitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.subtitle,
  );

  // ==========================================================
  // SECTION TITLES
  // ==========================================================

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.heading,
  );

  // ==========================================================
  // CARD
  // ==========================================================

  static const TextStyle cardTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.heading,
  );

  static const TextStyle cardSubtitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.subtitle,
  );

  // ==========================================================
  // BODY
  // ==========================================================

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.body,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.body,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.subtitle,
  );

  // ==========================================================
  // BUTTON
  // ==========================================================

  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  // ==========================================================
  // TEXT FIELD
  // ==========================================================

  static const TextStyle textField = TextStyle(
    fontSize: 15,
    color: AppColors.body,
  );

  static const TextStyle textFieldLabel = TextStyle(
    fontSize: 14,
    color: AppColors.subtitle,
  );

  // ==========================================================
  // TABLE
  // ==========================================================

  static const TextStyle tableHeader = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: AppColors.heading,
  );

  static const TextStyle tableBody = TextStyle(
    fontSize: 14,
    color: AppColors.body,
  );

  // ==========================================================
  // STATUS
  // ==========================================================

  static const TextStyle success = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.success,
  );

  static const TextStyle warning = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.warning,
  );

  static const TextStyle error = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.error,
  );
}