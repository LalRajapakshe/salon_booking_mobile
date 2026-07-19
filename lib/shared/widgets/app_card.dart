import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_text_styles.dart';

class AppCard extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final Widget child;
  final VoidCallback? onTap;
  final Widget? trailing;

  const AppCard({
    super.key,
    this.title,
    this.subtitle,
    this.icon,
    this.iconColor,
    required this.child,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = Card(
      child: Padding(
        padding: const EdgeInsets.all(
          AppDimensions.cardPadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            if (title != null ||
                subtitle != null ||
                icon != null) ...[
              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [

                  if (icon != null)
                    Container(
                      padding: const EdgeInsets.all(
                        AppDimensions.spaceS,
                      ),
                      decoration: BoxDecoration(
                        color: (iconColor ??
                                AppColors.primary)
                            .withOpacity(0.10),
                        borderRadius:
                            BorderRadius.circular(10),
                      ),
                      child: Icon(
                        icon,
                        color: iconColor ??
                            AppColors.primary,
                        size:
                            AppDimensions.iconMedium,
                      ),
                    ),

                  if (icon != null)
                    const SizedBox(
                      width: AppDimensions.spaceL,
                    ),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [

                        if (title != null)
                          Text(
                            title!,
                            style:
                                AppTextStyles.cardTitle,
                          ),

                        if (subtitle != null)
                          Padding(
                            padding:
                                const EdgeInsets.only(
                              top: AppDimensions.spaceXS,
                            ),
                            child: Text(
                              subtitle!,
                              style:
                                  AppTextStyles.cardSubtitle,
                            ),
                          ),
                      ],
                    ),
                  ),

                  if (trailing != null)
                    trailing!,
                ],
              ),

              const SizedBox(
                height: AppDimensions.spaceL,
              ),
            ],

            child,
          ],
        ),
      ),
    );

    if (onTap != null) {
      return InkWell(
        borderRadius: BorderRadius.circular(
          AppDimensions.cardRadius,
        ),
        onTap: onTap,
        child: card,
      );
    }

    return card;
  }
}