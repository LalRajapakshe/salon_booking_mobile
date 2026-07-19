import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_text_styles.dart';

class AppPage extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final List<Widget>? actions;
  final FloatingActionButton? floatingActionButton;
  final Widget? drawer;
  final bool showAppBar;

  const AppPage({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.actions,
    this.floatingActionButton,
    this.drawer,
    this.showAppBar = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      drawer: drawer,
      floatingActionButton: floatingActionButton,

      appBar: showAppBar
          ? AppBar(
              title: Text(title),
              actions: actions,
            )
          : null,

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(
            AppDimensions.screenPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              if (subtitle != null) ...[
                Text(
                  subtitle!,
                  style: AppTextStyles.pageSubtitle,
                ),
                const SizedBox(
                  height: AppDimensions.spaceL,
                ),
              ],

              Expanded(
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}