import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_text_styles.dart';

class AppLoading extends StatelessWidget {
  final String message;
  final double size;

  const AppLoading({
    super.key,
    this.message = 'Loading...',
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 3,
            ),
          ),

          const SizedBox(
            height: AppDimensions.spaceL,
          ),

          Text(
            message,
            style: AppTextStyles.body,
          ),
        ],
      ),
    );
  }
}