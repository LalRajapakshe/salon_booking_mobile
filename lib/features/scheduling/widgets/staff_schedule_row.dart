import 'package:flutter/material.dart';

import '../models/scheduling_models.dart';

class StaffScheduleRow extends StatelessWidget {
  final SchedulingStaff staff;
  final StaffDaySummary summary;
  final double height;

  const StaffScheduleRow({
    super.key,
    required this.staff,
    required this.summary,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final indicator = switch (summary.state) {
      StaffDayState.open => const Color(0xFF2E7D32),
      StaffDayState.busy => const Color(0xFFF9A825),
      StaffDayState.leave => const Color(0xFFC62828),
      StaffDayState.offDuty => const Color(0xFF757575),
    };

    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: _avatarColor(staff.staffId),
              child: Text(
                staff.initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    staff.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    staff.role,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: indicator,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          summary.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: indicator, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Color _avatarColor(String staffId) {
  return switch (staffId) {
    'kasun' => const Color(0xFF5E35B1),
    'amali' => const Color(0xFF00897B),
    'ravi' => const Color(0xFF3949AB),
    'nadeesha' => const Color(0xFF8E24AA),
    'dilshan' => const Color(0xFF546E7A),
    _ => const Color(0xFF6D4C41),
  };
}
