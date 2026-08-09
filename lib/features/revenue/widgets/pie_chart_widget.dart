import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class PieChartWidget extends StatelessWidget {
  final Map<String, double> data;
  final double radius;
  final double centerSpaceRadius;

  const PieChartWidget({
    super.key,
    required this.data,
    this.radius = 80,
    this.centerSpaceRadius = 45,
  });

  static const List<Color> chartColors = [
    Color(0xFF4F46E5),
    Color(0xFF06B6D4),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF8B5CF6),
  ];

  @override
  Widget build(BuildContext context) {
    final entries = data.entries.toList();

    return SizedBox(
      height: 260,
      child: PieChart(
        PieChartData(
          centerSpaceRadius: centerSpaceRadius,
          sectionsSpace: 3,
          borderData: FlBorderData(show: false),
          sections: List.generate(entries.length, (index) {
            final item = entries[index];

            return PieChartSectionData(
              value: item.value,
              title: '',
              radius: radius,
              color: chartColors[index % chartColors.length],
            );
          }),
        ),
      ),
    );
  }
}