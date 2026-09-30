import 'package:flutter/material.dart';

import '../models/appointment_status.dart';

class AppointmentStatusBadge extends StatelessWidget {
  final AppointmentStatus status;

  const AppointmentStatusBadge({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final (Color background, Color foreground) = switch (status) {
      AppointmentStatus.scheduled => (const Color(0xFFE3F2FD), const Color(0xFF1565C0)),
      AppointmentStatus.confirmed => (const Color(0xFFF3E5F5), const Color(0xFF6A1B9A)),
      AppointmentStatus.completed => (const Color(0xFFE8F5E9), const Color(0xFF2E7D32)),
      AppointmentStatus.cancelled => (const Color(0xFFFFEBEE), const Color(0xFFC62828)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
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
