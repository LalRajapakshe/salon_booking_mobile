import 'package:flutter/material.dart';

import '../widgets/ai_summary_card.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/employee_card.dart';
import '../widgets/executive_header.dart';
import '../widgets/inventory_alert_card.dart';
import '../widgets/kpi_card.dart';
import '../widgets/quick_action_card.dart';
import '../widgets/schedule_card.dart';
import '../widgets/section_title.dart';

class DashboardScreen extends StatelessWidget {
  DashboardScreen({super.key});

  final List<_DashboardItem> dashboardItems = [
    _DashboardItem(Icons.people, "Customers", () {}),
    _DashboardItem(Icons.badge, "Employees", () {}),
    _DashboardItem(Icons.calendar_month, "Appointments", () {}),
    _DashboardItem(Icons.content_cut, "Services", () {}),
    _DashboardItem(Icons.payments, "Billing", () {}),
    _DashboardItem(Icons.bar_chart, "Reports", () {}),
    _DashboardItem(Icons.settings, "Settings", () {}),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F6FA),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          "Salon Booking System",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            ExecutiveHeader(
              greeting: "Good Morning 👋",
              userName: "Administrator",
              date: "Monday, 20 July 2026",
              businessHealth: 94,
            ),

            const SizedBox(height: 30),

            const SectionTitle(
              title: "Business Overview",
              subtitle: "Today's performance",
              icon: Icons.analytics_outlined,
            ),

            const SizedBox(height: 20),

            LayoutBuilder(
              builder: (context, constraints) {

                int crossAxisCount = 2;

                if (constraints.maxWidth > 1200) {
                  crossAxisCount = 4;
                }
                else if (constraints.maxWidth > 700) {
                  crossAxisCount = 3;
                }

                return GridView.count(

                  crossAxisCount: crossAxisCount,

                  shrinkWrap: true,

                  physics: const NeverScrollableScrollPhysics(),

                  crossAxisSpacing: 16,

                  mainAxisSpacing: 16,

                  childAspectRatio: 1.35,

                  children: [

                    KpiCard(
                      title: "Revenue",
                      value: "Rs.84,500",
                      change: "+18%",
                      icon: Icons.payments,
                      color: Colors.green,
                    ),

                    KpiCard(
                      title: "Appointments",
                      value: "28",
                      change: "+6%",
                      icon: Icons.calendar_month,
                      color: Colors.blue,
                    ),

                    KpiCard(
                      title: "Customers",
                      value: "324",
                      change: "+9%",
                      icon: Icons.people,
                      color: Colors.orange,
                    ),

                    KpiCard(
                      title: "Walk-ins",
                      value: "14",
                      change: "+3%",
                      icon: Icons.directions_walk,
                      color: Colors.purple,
                    ),

                    KpiCard(
                      title: "New Customers",
                      value: "06",
                      change: "+2",
                      icon: Icons.person_add,
                      color: Colors.teal,
                    ),

                    KpiCard(
                      title: "Outstanding",
                      value: "Rs.21K",
                      change: "-4%",
                      icon: Icons.account_balance_wallet,
                      color: Colors.red,
                    ),
                    KpiCard(
  title: "Outstanding",
  value: "Rs.21K",
  change: "-4%",
  icon: Icons.account_balance_wallet,
  color: Colors.red,
),
                    KpiCard(
                      title: "VIP Members",
                      value: "18",
                      change: "+1",
                      icon: Icons.workspace_premium,
                      color: Colors.amber,
                    ),

                    KpiCard(
                      title: "Birthdays",
                      value: "04",
                      change: "Today",
                      icon: Icons.cake,
                      color: Colors.pink,
                    ),

                  ],
                );
              },
            ),

            const SizedBox(height: 30),

            const SectionTitle(
              title: "AI Business Assistant",
              subtitle: "Business insights powered by AI",
              icon: Icons.auto_awesome,
            ),

            const SizedBox(height: 16),

            const AiSummaryCard(),

            const SizedBox(height: 30),

            LayoutBuilder(
              builder: (context, constraints) {

                if (constraints.maxWidth > 1000) {

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      const Expanded(
                        flex: 2,
                        child: ScheduleCard(),
                      ),

                      const SizedBox(width: 20),

                      Expanded(
                        child: Column(
                          children: [

                            const InventoryAlertCard(),

                            const SizedBox(height: 20),

                            EmployeeCard(
                              name: "Amanda",
                              revenue: "Rs.48,000",
                              appointments: 14,
                              rating: 5,
                            ),

                          ],
                        ),
                      ),

                    ],
                  );
                }

                return Column(
                  children: [

                    const ScheduleCard(),

                    const SizedBox(height: 20),

                    const InventoryAlertCard(),

                    const SizedBox(height: 20),

                    EmployeeCard(
                      name: "Amanda",
                      revenue: "Rs.48,000",
                      appointments: 14,
                      rating: 5,
                    ),

                  ],
                );
              },
            ),

            const SizedBox(height: 30),

            const SectionTitle(
              title: "Quick Actions",
              subtitle: "Frequently used shortcuts",
              icon: Icons.flash_on,
            ),

            const SizedBox(height: 16),

            LayoutBuilder(
              builder: (context, constraints) {

                int crossAxisCount = 2;

                if (constraints.maxWidth > 1200) {
                  crossAxisCount = 6;
                } else if (constraints.maxWidth > 800) {
                  crossAxisCount = 3;
                }

                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                  children: [

                    QuickActionCard(
                      icon: Icons.calendar_month,
                      title: "Appointment",
                      color: Colors.blue,
                      onTap: () {},
                    ),

                    QuickActionCard(
                      icon: Icons.people,
                      title: "Customer",
                      color: Colors.orange,
                      onTap: () {},
                    ),

                    QuickActionCard(
                      icon: Icons.payments,
                      title: "Invoice",
                      color: Colors.green,
                      onTap: () {},
                    ),

                    QuickActionCard(
                      icon: Icons.inventory_2,
                      title: "Inventory",
                      color: Colors.red,
                      onTap: () {},
                    ),

                    QuickActionCard(
                      icon: Icons.badge,
                      title: "Employee",
                      color: Colors.deepPurple,
                      onTap: () {},
                    ),

                    QuickActionCard(
                      icon: Icons.bar_chart,
                      title: "Reports",
                      color: Colors.teal,
                      onTap: () {},
                    ),

                  ],
                );
              },
            ),

            const SizedBox(height: 35),

            const SectionTitle(
              title: "System Modules",
              subtitle: "Navigate through ERP modules",
              icon: Icons.dashboard_customize,
            ),

            const SizedBox(height: 18),
            const SizedBox(height: 18),
                        LayoutBuilder(
              builder: (context, constraints) {

                int crossAxisCount = 2;

                if (constraints.maxWidth > 1200) {
                  crossAxisCount = 4;
                } else if (constraints.maxWidth > 800) {
                  crossAxisCount = 3;
                }

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: dashboardItems.length,
                  gridDelegate:
                      SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.15,
                  ),
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

            const SizedBox(height: 30),

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

  const _DashboardItem(
    this.icon,
    this.title,
    this.onTap,
  );
}
