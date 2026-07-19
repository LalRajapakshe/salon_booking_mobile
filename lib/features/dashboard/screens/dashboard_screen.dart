import 'package:flutter/material.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/statistic_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        title: const Text(
          'Salon Booking System',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Welcome Section
            const Text(
              'Good Morning 👋',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              'Welcome back, Administrator',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
            ),

            const SizedBox(height: 25),

            // Statistics
            Row(
              children: [
                Expanded(
                  child: StatisticCard(
                    'Appointments',
                    '18',
                    Icons.calendar_month,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatisticCard(
                    'Revenue',
                    'Rs. 42,500',
                    Icons.payments,
                    Colors.green,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: StatisticCard(
                    'Customers',
                    '324',
                    Icons.people,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatisticCard(
                    'Employees',
                    '12',
                    Icons.badge,
                    Colors.purple,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            const Text(
              'Modules',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.15,
              children: [

                DashboardCard(Icons.people, "Customers", () {}),
                DashboardCard(Icons.badge, "Employees", () {}),
                DashboardCard(Icons.calendar_month, "Appointments", () {}),
                DashboardCard(Icons.content_cut, "Services", () {}),
                DashboardCard(Icons.payments, "Billing", () {}),
                DashboardCard(Icons.bar_chart, "Reports", () {}),
                DashboardCard(Icons.settings, "Settings", () {}),

              ],
            ),
          ],
        ),
      ),
    );
  }

  
}