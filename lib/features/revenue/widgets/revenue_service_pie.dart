import 'package:flutter/material.dart';

import '../data/mock_revenue_data.dart';
import 'pie_chart_widget.dart';

class RevenueServicePie extends StatelessWidget {
  const RevenueServicePie({super.key});

  @override
  Widget build(BuildContext context) {
    final services = MockRevenueData.serviceRevenue;

    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// Header
            const Text(
              'Revenue by Service',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 4),

            const Text(
              'Revenue contribution by salon services',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 24),

            /// Donut Chart
            PieChartWidget(
              data: services,
            ),

            const SizedBox(height: 24),

            /// Legend
            ...List.generate(
              services.length,
              (index) {
                final item = services.entries.elementAt(index);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [

                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: PieChartWidget.chartColors[
                              index % PieChartWidget.chartColors.length],
                          shape: BoxShape.circle,
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Text(
                          item.key,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                      Text(
                        "Rs. ${item.value.toStringAsFixed(0)}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}