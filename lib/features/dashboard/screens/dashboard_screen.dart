import 'package:flutter/material.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/statistic_card.dart';

class DashboardScreen extends StatelessWidget {
  DashboardScreen({super.key});

  final List<_DashboardItem> dashboardItems = [

  _DashboardItem(
    Icons.people,
    'Customers',
    () {},
  ),

  _DashboardItem(
    Icons.badge,
    'Employees',
    () {},
  ),

  _DashboardItem(
    Icons.calendar_month,
    'Appointments',
    () {},
  ),

  _DashboardItem(
    Icons.content_cut,
    'Services',
    () {},
  ),

  _DashboardItem(
    Icons.payments,
    'Billing',
    () {},
  ),

  _DashboardItem(
    Icons.bar_chart,
    'Reports',
    () {},
  ),

  _DashboardItem(
    Icons.settings,
    'Settings',
    () {},
  ),

];

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
                   title: 'Appointments',
                   value:  '18',
                   icon: Icons.calendar_month,
                   color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatisticCard(
                    title: 'Revenue',
                    value: 'Rs. 42,500',
                    icon: Icons.payments,
                    color: Colors.green,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: StatisticCard(
                    title: 'Customers',
                    value: '324',
                    icon: Icons.people,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatisticCard(
                    title: 'Employees',
                    value: '12',
                    icon: Icons.badge,
                    color: Colors.purple,
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

            LayoutBuilder(
              builder: (context, constraints) {

                int crossAxisCount = 2;

                if (constraints.maxWidth >= 1200) {
                  crossAxisCount = 4;
                } else if (constraints.maxWidth >= 800) {
                  crossAxisCount = 3;
                } else {
                  crossAxisCount = 2;
                }

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),

                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.15,
                  ),

                  itemCount: dashboardItems.length,

                  itemBuilder: (context, index) {

                    final item = dashboardItems[index];

                    return DashboardCard(
                      icon: item.icon,
                      title: item.title,
                      onTap: item.onTap,
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  
}

class _DashboardItem {

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  _DashboardItem(
    this.icon,
    this.title,
    this.onTap,
  );

}