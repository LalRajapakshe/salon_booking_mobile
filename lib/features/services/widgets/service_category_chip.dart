import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';

Color serviceCategoryColor(String category) {
  switch (category) {
    case 'Hair':
      return const Color(0xFF6A1B9A);
    case 'Nails':
      return const Color(0xFFAD1457);
    case 'Facial':
      return const Color(0xFF00897B);
    case 'Skin':
      return const Color(0xFFEF6C00);
    case 'Spa':
      return const Color(0xFF1565C0);
    case 'Makeup':
      return const Color(0xFF5E35B1);
    default:
      return AppColors.service;
  }
}

class ServiceCategoryChip extends StatelessWidget {
  final String category;

  const ServiceCategoryChip({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final color = serviceCategoryColor(category);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        category,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class ServiceStatusBadge extends StatelessWidget {
  final bool isActive;

  const ServiceStatusBadge({super.key, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final background = isActive
        ? const Color(0xFFE8F5E9)
        : const Color(0xFFF3F4F6);
    final foreground = isActive
        ? const Color(0xFF2E7D32)
        : const Color(0xFF616161);
    final label = isActive ? 'Active' : 'Inactive';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: foreground,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
