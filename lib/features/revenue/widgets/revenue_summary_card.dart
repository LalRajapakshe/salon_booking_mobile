import 'package:flutter/material.dart';

import '../data/mock_revenue_data.dart';
import 'summary_kpi_card.dart';

class RevenueSummaryCard extends StatelessWidget {
  const RevenueSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final revenue = MockRevenueData.summary;

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 4;

        if (constraints.maxWidth < 700) {
          crossAxisCount = 2;
        }

        if (constraints.maxWidth < 450) {
          crossAxisCount = 1;
        }

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.35,
          children: [
            SummaryKpiCard(
              title: "Today's Revenue",
              value: "Rs. ${revenue.todayRevenue.toStringAsFixed(0)}",
              change: "+12.4%",
              icon: Icons.today,
              color: Colors.blue,
            ),

            SummaryKpiCard(
              title: "Weekly Revenue",
              value: "Rs. ${revenue.weeklyRevenue.toStringAsFixed(0)}",
              change: "+8.1%",
              icon: Icons.calendar_view_week,
              color: Colors.green,
            ),

            SummaryKpiCard(
              title: "Monthly Revenue",
              value: "Rs. ${revenue.monthlyRevenue.toStringAsFixed(0)}",
              change: "+18.6%",
              icon: Icons.calendar_month,
              color: Colors.orange,
            ),

            SummaryKpiCard(
              title: "Yearly Revenue",
              value: "Rs. ${revenue.yearlyRevenue.toStringAsFixed(0)}",
              change: "+24.2%",
              icon: Icons.trending_up,
              color: Colors.purple,
            ),
          ],
        );
      },
    );
  }
}