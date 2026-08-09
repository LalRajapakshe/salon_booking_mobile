import 'package:flutter/material.dart';

import '../data/mock_revenue_data.dart';
import 'pie_chart_widget.dart';

class PaymentBreakdownCard extends StatelessWidget {
  const PaymentBreakdownCard({super.key});

  @override
  Widget build(BuildContext context) {
    final paymentMethods = MockRevenueData.paymentMethods;

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
            const Text(
              'Payment Breakdown',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 4),

            const Text(
              'Distribution of revenue by payment method',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 24),

            PieChartWidget(
              data: paymentMethods,
            ),

            const SizedBox(height: 24),

            ...List.generate(
              paymentMethods.length,
              (index) {
                final item = paymentMethods.entries.elementAt(index);

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
                        "${item.value.toStringAsFixed(1)}%",
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