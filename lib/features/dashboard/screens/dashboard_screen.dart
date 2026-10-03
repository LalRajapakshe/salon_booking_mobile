import 'package:flutter/material.dart';

import '../../../shared/widgets/app_snackbar.dart';
import '../widgets/ai_summary_card.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/employee_card.dart';
import '../widgets/executive_header.dart';
import '../widgets/inventory_alert_card.dart';
import '../widgets/kpi_card.dart';
import '../widgets/quick_action_card.dart';
import '../widgets/schedule_card.dart';
import '../widgets/section_title.dart';

//import '../../revenue/widgets/revenue_trend_chart.dart';
//import '../../revenue/widgets/revenue_service_pie.dart';
//import '../../revenue/widgets/payment_breakdown_card.dart';

import '../../appointments/screens/appointments_screen.dart';
import '../../customers/screens/customers_screen.dart';
import '../../revenue/screens/revenue_dashboard_screen.dart';
import '../../scheduling/screens/scheduling_board_screen.dart';
import '../../services/screens/services_screen.dart';

class DashboardScreen extends StatelessWidget {
  DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final quickActionItems = _quickActionItems(context);
    final systemModuleItems = _systemModuleItems(context);

    return Scaffold(
      backgroundColor: const Color(0xffF4F6FA),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          "Salon Booking System",
          style: TextStyle(fontWeight: FontWeight.bold),
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
                } else if (constraints.maxWidth > 700) {
                  crossAxisCount = 3;
                }

                return GridView.count(
                  crossAxisCount: crossAxisCount,

                  shrinkWrap: true,

                  physics: const NeverScrollableScrollPhysics(),

                  crossAxisSpacing: 16,

                  mainAxisSpacing: 16,

                  //childAspectRatio: 1.35,
                  childAspectRatio: constraints.maxWidth < 600
                      ? 1.20
                      : constraints.maxWidth < 900
                      ? 1.28
                      : 1.35,

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
                    //                   KpiCard(
                    // title: "Outstanding",
                    // value: "Rs.21K",
                    // change: "-4%",
                    // icon: Icons.account_balance_wallet,
                    // color: Colors.red,
                    //),
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
            ///////////////////////////////////////////////////
            const SizedBox(height: 30),

            const SectionTitle(
              title: "Revenue Analytics",
              subtitle: "Revenue insights and trends",
              icon: Icons.bar_chart,
            ),

            const SizedBox(height: 16),

            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Revenue Performance",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          SizedBox(height: 6),

                          Text(
                            "View detailed revenue trends, services and payment breakdown.",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 16),

                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RevenueDashboardScreen(),
                          ),
                        );
                      },
                      child: const Text("View Analytics →"),
                    ),
                  ],
                ),
              ),
            ),

            //////////////////////////////////////////////////
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
                      const Expanded(flex: 2, child: ScheduleCard()),

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
              title: "Quick Action",
              subtitle: "Frequently used shortcuts",
              icon: Icons.flash_on,
            ),

            const SizedBox(height: 16),

            LayoutBuilder(
              builder: (context, constraints) {
                return _moduleGrid(
                  maxWidth: constraints.maxWidth,
                  itemCount: quickActionItems.length,
                  mainAxisExtent: 168,
                  itemBuilder: (index) {
                    final item = quickActionItems[index];
                    return QuickActionCard(
                      icon: item.icon,
                      title: item.title,
                      color: item.color,
                      onTap: item.onTap,
                    );
                  },
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

            LayoutBuilder(
              builder: (context, constraints) {
                return _moduleGrid(
                  maxWidth: constraints.maxWidth,
                  itemCount: systemModuleItems.length,
                  mainAxisExtent: 148,
                  itemBuilder: (index) {
                    final item = systemModuleItems[index];
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
  final Color color;
  final VoidCallback onTap;

  const _DashboardItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.color = Colors.deepPurple,
  });
}

void _openScreen(BuildContext context, Widget screen) {
  Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
}

void _showComingSoon(BuildContext context, String moduleName) {
  AppSnackBar.info(context, '$moduleName is coming soon.');
}

List<_DashboardItem> _quickActionItems(BuildContext context) {
  return [
    _DashboardItem(
      icon: Icons.calendar_month,
      title: 'Appointment',
      color: Colors.blue,
      onTap: () => _openScreen(context, const AppointmentsScreen()),
    ),
    _DashboardItem(
      icon: Icons.design_services,
      title: 'Appointment Service',
      color: Colors.indigo,
      onTap: () => _showComingSoon(context, 'Appointment Service'),
    ),
    _DashboardItem(
      icon: Icons.history,
      title: 'Appointment Status History',
      color: Colors.blueGrey,
      onTap: () => _showComingSoon(context, 'Appointment Status History'),
    ),
    _DashboardItem(
      icon: Icons.store,
      title: 'Branch',
      color: Colors.brown,
      onTap: () => _showComingSoon(context, 'Branch'),
    ),
    _DashboardItem(
      icon: Icons.people,
      title: 'Customer',
      color: Colors.orange,
      onTap: () => _openScreen(context, const CustomersScreen()),
    ),
    _DashboardItem(
      icon: Icons.sticky_note_2,
      title: 'Customer Note',
      color: Colors.deepOrange,
      onTap: () => _showComingSoon(context, 'Customer Note'),
    ),
    _DashboardItem(
      icon: Icons.badge,
      title: 'Employee',
      color: Colors.deepPurple,
      onTap: () => _showComingSoon(context, 'Employee'),
    ),
    _DashboardItem(
      icon: Icons.receipt_long,
      title: 'Invoice',
      color: Colors.green,
      onTap: () => _showComingSoon(context, 'Invoice'),
    ),
    _DashboardItem(
      icon: Icons.payments,
      title: 'Payment',
      color: Colors.lightGreen,
      onTap: () => _showComingSoon(context, 'Payment'),
    ),
    _DashboardItem(
      icon: Icons.inventory_2,
      title: 'Inventory',
      color: Colors.red,
      onTap: () => _showComingSoon(context, 'Inventory'),
    ),
    _DashboardItem(
      icon: Icons.content_cut,
      title: 'Service',
      color: Colors.purple,
      onTap: () => _openScreen(context, const ServicesScreen()),
    ),
    _DashboardItem(
      icon: Icons.category,
      title: 'Service Category',
      color: Colors.purpleAccent,
      onTap: () => _showComingSoon(context, 'Service Category'),
    ),
    _DashboardItem(
      icon: Icons.groups,
      title: 'Staff',
      color: Colors.indigo,
      onTap: () => _showComingSoon(context, 'Staff'),
    ),
    _DashboardItem(
      icon: Icons.schedule,
      title: 'Staff Schedule',
      color: Colors.cyan,
      onTap: () => _openScreen(context, const SchedulingBoardScreen()),
    ),
    _DashboardItem(
      icon: Icons.event_busy,
      title: 'Staff Leave',
      color: Colors.amber,
      onTap: () => _showComingSoon(context, 'Staff Leave'),
    ),
    _DashboardItem(
      icon: Icons.bar_chart,
      title: 'Report',
      color: Colors.teal,
      onTap: () => _showComingSoon(context, 'Report'),
    ),
  ];
}

List<_DashboardItem> _systemModuleItems(BuildContext context) {
  return [
    _DashboardItem(
      icon: Icons.vpn_key,
      title: 'Permission',
      onTap: () => _showComingSoon(context, 'Permission'),
    ),
    _DashboardItem(
      icon: Icons.admin_panel_settings,
      title: 'Role',
      onTap: () => _showComingSoon(context, 'Role'),
    ),
    _DashboardItem(
      icon: Icons.rule,
      title: 'Role Permission',
      onTap: () => _showComingSoon(context, 'Role Permission'),
    ),
    _DashboardItem(
      icon: Icons.apartment,
      title: 'Tenant',
      onTap: () => _showComingSoon(context, 'Tenant'),
    ),
    _DashboardItem(
      icon: Icons.group,
      title: 'Users',
      onTap: () => _showComingSoon(context, 'Users'),
    ),
    _DashboardItem(
      icon: Icons.manage_accounts,
      title: 'User Roles',
      onTap: () => _showComingSoon(context, 'User Roles'),
    ),
    _DashboardItem(
      icon: Icons.settings,
      title: 'Setting',
      onTap: () => _showComingSoon(context, 'Setting'),
    ),
  ];
}

Widget _moduleGrid({
  required double maxWidth,
  required int itemCount,
  required double mainAxisExtent,
  required Widget Function(int index) itemBuilder,
}) {
  final crossAxisCount = maxWidth > 1200
      ? 6
      : maxWidth > 900
      ? 4
      : maxWidth > 600
      ? 3
      : 2;

  return GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: itemCount,
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      mainAxisExtent: mainAxisExtent,
    ),
    itemBuilder: (context, index) => itemBuilder(index),
  );
}
