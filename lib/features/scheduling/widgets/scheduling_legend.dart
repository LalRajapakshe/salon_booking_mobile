import 'package:flutter/material.dart';

class SchedulingLegend extends StatelessWidget {
  const SchedulingLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _LegendItem(
          color: Color(0xFF2E7D32),
          icon: Icons.add_circle_outline,
          label: 'Available',
        ),
        _LegendItem(
          color: Color(0xFF673AB7),
          icon: Icons.event_note_outlined,
          label: 'Booked',
        ),
        _LegendItem(
          color: Color(0xFFF9A825),
          icon: Icons.free_breakfast_outlined,
          label: 'Break',
        ),
        _LegendItem(
          color: Color(0xFFC62828),
          icon: Icons.event_busy_outlined,
          label: 'Leave',
        ),
        _LegendItem(
          color: Color(0xFF757575),
          icon: Icons.do_not_disturb_on_outlined,
          label: 'Off duty',
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;

  const _LegendItem({
    required this.color,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Color(0xFF424242)),
        ),
      ],
    );
  }
}
