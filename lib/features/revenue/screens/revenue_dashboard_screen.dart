import 'package:flutter/material.dart';

import '../widgets/ai_revenue_insights.dart';
import '../widgets/export_buttons.dart';
import '../widgets/payment_breakdown_card.dart';
import '../widgets/recent_transactions_table.dart';
import '../widgets/revenue_service_pie.dart';
import '../widgets/revenue_statistics_card.dart';
import '../widgets/revenue_summary_card.dart';
import '../widgets/revenue_trend_chart.dart';
import '../widgets/top_employee_card.dart';
import '../widgets/top_services_card.dart';



class RevenueDashboardScreen extends StatelessWidget {
  const RevenueDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Revenue Analytics',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:  [

            /// KPI Summary
            RevenueSummaryCard(),

            SizedBox(height: 24),

            /// Revenue Trend
            RevenueTrendChart(),

            SizedBox(height: 24),

            /// Revenue Breakdown
           /// Revenue Breakdown
LayoutBuilder(
                builder: (context, constraints) {

                  if (constraints.maxWidth > 900) {
                    return const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Expanded(
                          child: RevenueServicePie(),
                        ),

                        SizedBox(width: 20),

                        Expanded(
                          child: PaymentBreakdownCard(),
                        ),
                      ],
                    );
                  }

                  return const Column(
                    children: [

                      RevenueServicePie(),

                      SizedBox(height: 20),

                      PaymentBreakdownCard(),
                    ],
                  );
                },
              ),

            SizedBox(height: 24),

            /// Employees + Services
/// Employees + Services
LayoutBuilder(
                  builder: (context, constraints) {

                    if (constraints.maxWidth > 900) {
                      return const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          Expanded(
                            child: TopEmployeeCard(),
                          ),

                          SizedBox(width: 20),

                          Expanded(
                            child: TopServicesCard(),
                          ),
                        ],
                      );
                    }

                    return const Column(
                      children: [

                        TopEmployeeCard(),

                        SizedBox(height: 20),

                        TopServicesCard(),
                      ],
                    );
                  },
                ),

            SizedBox(height: 24),

            /// Statistics
            RevenueStatisticsCard(),

            SizedBox(height: 24),

            /// Transactions
            RecentTransactionsTable(),

            SizedBox(height: 24),

            /// AI Insights
            AiRevenueInsights(),

            SizedBox(height: 24),

            /// Export Buttons
            ExportButtons(),

            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}