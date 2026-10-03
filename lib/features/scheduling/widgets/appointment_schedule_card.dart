import 'package:flutter/material.dart';

import '../models/scheduling_models.dart';

class AppointmentScheduleCard extends StatelessWidget {
  final SchedulingBlock block;
  final bool dimmed;
  final VoidCallback onTap;

  const AppointmentScheduleCard({
    super.key,
    required this.block,
    required this.dimmed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final conflict = block.conflict;
    final background = conflict
        ? const Color(0xFFFFF5F5)
        : const Color(0xFFF6F3FB);
    final border = conflict ? const Color(0xFFE53935) : const Color(0xFFD1C4E9);
    final accent = conflict ? const Color(0xFFE53935) : const Color(0xFF673AB7);

    return Padding(
      padding: const EdgeInsets.all(4),
      child: Opacity(
        opacity: dimmed ? 0.38 : 1,
        child: Material(
          color: background,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onTap,
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(8),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final roomy = constraints.maxWidth >= 64;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                block.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                              if (roomy)
                                Text(
                                  block.subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF5E548E),
                                  ),
                                ),
                              Text(
                                formatScheduleRange(
                                  block.startMinute,
                                  block.endMinute,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                              if (conflict)
                                const Text(
                                  'Conflict',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFE53935),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
