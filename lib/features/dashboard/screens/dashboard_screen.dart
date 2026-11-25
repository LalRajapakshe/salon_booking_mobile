import 'package:flutter/material.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/auth/staff_access.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../settings/screens/permissions_screen.dart';
import '../../settings/screens/roles_screen.dart';
import '../../settings/screens/users_screen.dart';
import '../widgets/ai_summary_card.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/employee_card.dart';
import '../widgets/executive_header.dart';
import '../widgets/inventory_alert_card.dart';
import '../widgets/quick_action_card.dart';
import '../widgets/schedule_card.dart';
import '../widgets/section_title.dart';

//import '../../revenue/widgets/revenue_trend_chart.dart';
//import '../../revenue/widgets/revenue_service_pie.dart';
//import '../../revenue/widgets/payment_breakdown_card.dart';

import '../../appointments/screens/appointments_screen.dart';
import '../../billing/screens/bills_screen.dart';
import '../../billing/screens/products_screen.dart';
import '../../billing/screens/tax_screen.dart';
import '../../operations/widgets/live_operations_panel.dart';
import '../../rentals/screens/rentals_screen.dart';
import '../../stylist/screens/stylist_board_screen.dart';
import '../../appointments/widgets/cancellation_queue_button.dart';
import '../../customers/screens/customers_screen.dart';
import '../../branches/screens/branches_screen.dart';
import '../../employees/screens/employees_screen.dart';
import '../../reception/screens/reception_desk_screen.dart';
import '../../revenue/screens/revenue_dashboard_screen.dart';
import '../../scheduling/screens/scheduling_board_screen.dart';
import '../../services/screens/service_categories_screen.dart';
import '../../services/screens/services_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

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
        actions: const [
          CancellationQueueButton(),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            ExecutiveHeader(
              greeting: "Good Morning 👋",
              userName: AuthSession.instance.fullName ?? AuthSession.instance.username ?? "Administrator",
              date: DateTime.now().toString().split(' ').first,
              businessHealth: -1,
              statusLine: AuthSession.instance.isSignedIn
                  ? "Today's figures below are from the salon."
                  : 'Sign in to replace the preview with live figures.',
            ),

            const SizedBox(height: 30),

            const SectionTitle(
              title: "Business Overview",
              subtitle: "Today's performance",
              icon: Icons.analytics_outlined,
            ),

            const SizedBox(height: 20),

            const LiveOperationsPanel(),
            if (!AuthSession.instance.isSignedIn) ...[
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
            ],

            //////////////////////////////////////////////////
            const SizedBox(height: 30),

            if (!AuthSession.instance.isSignedIn) ...[
            const SectionTitle(
              title: "AI Business Assistant",
              subtitle: "Business insights powered by AI",
              icon: Icons.auto_awesome,
            ),

            const SizedBox(height: 16),

            const AiSummaryCard(),
            ],

            const SizedBox(height: 30),

            if (!AuthSession.instance.isSignedIn) LayoutBuilder(
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
  final session = AuthSession.instance;
  bool show(String permission) => !session.isSignedIn || session.can(permission);
  return [
    if (show('appointments.read'))
    _DashboardItem(
      icon: Icons.desk,
      title: 'Front Desk',
      color: Colors.deepPurple,
      onTap: () => _openScreen(context, const ReceptionDeskScreen()),
    ),
    if (show('appointments.read'))
    _DashboardItem(
      icon: Icons.calendar_month,
      title: 'Appointment',
      color: Colors.blue,
      onTap: () => _openScreen(context, const AppointmentsScreen()),
    ),
    if (StaffAccess.seesOwnAppointments(session) && !show('appointments.read'))
    _DashboardItem(
      icon: Icons.calendar_month,
      title: 'My appointments',
      color: Colors.blue,
      onTap: () => _openScreen(context, const StylistBoardScreen()),
    ),
    if (!session.isSignedIn)
    _DashboardItem(
      icon: Icons.design_services,
      title: 'Appointment Service',
      color: Colors.indigo,
      onTap: () => _showComingSoon(context, 'Appointment Service'),
    ),
    if (!session.isSignedIn)
    _DashboardItem(
      icon: Icons.history,
      title: 'Appointment Status History',
      color: Colors.blueGrey,
      onTap: () => _showComingSoon(context, 'Appointment Status History'),
    ),
    if (show('branches.read'))
    _DashboardItem(
      icon: Icons.store,
      title: 'Branch',
      color: Colors.brown,
      onTap: () => _openScreen(context, const BranchesScreen()),
    ),
    if (show('customers.read'))
    _DashboardItem(
      icon: Icons.people,
      title: 'Customer',
      color: Colors.orange,
      onTap: () => _openScreen(context, const CustomersScreen()),
    ),
    if (!session.isSignedIn)
    _DashboardItem(
      icon: Icons.sticky_note_2,
      title: 'Customer Note',
      color: Colors.deepOrange,
      onTap: () => _showComingSoon(context, 'Customer Note'),
    ),
    if (show('employees.read'))
    _DashboardItem(
      icon: Icons.badge,
      title: 'Employee',
      color: Colors.deepPurple,
      onTap: () => _openScreen(context, const EmployeesScreen()),
    ),
    if (session.isSignedIn && StaffAccess.seesBills(session))
    _DashboardItem(
      icon: Icons.receipt_long,
      title: 'Billing',
      color: Colors.green,
      onTap: () => _openScreen(context, const BillsScreen()),
    ),
    if (session.isSignedIn && StaffAccess.seesProducts(session))
    _DashboardItem(
      icon: Icons.shopping_bag_outlined,
      title: 'Retail products',
      color: Colors.teal,
      onTap: () => _openScreen(context, const ProductsScreen()),
    ),
    if (session.isSignedIn && StaffAccess.seesRentals(session))
    _DashboardItem(
      icon: Icons.checkroom,
      title: 'Rentals',
      color: Colors.indigo,
      onTap: () => _openScreen(context, const RentalsScreen()),
    ),
    if (session.isSignedIn && StaffAccess.seesTax(session))
    _DashboardItem(
      icon: Icons.percent,
      title: 'Tax',
      color: Colors.blueGrey,
      onTap: () => _openScreen(context, const TaxScreen()),
    ),
    if (!session.isSignedIn)
    _DashboardItem(
      icon: Icons.receipt_long,
      title: 'Invoice',
      color: Colors.green,
      onTap: () => _showComingSoon(context, 'Invoice'),
    ),
    if (!session.isSignedIn)
    _DashboardItem(
      icon: Icons.payments,
      title: 'Payment',
      color: Colors.lightGreen,
      onTap: () => _showComingSoon(context, 'Payment'),
    ),
    if (!session.isSignedIn)
    _DashboardItem(
      icon: Icons.inventory_2,
      title: 'Inventory',
      color: Colors.red,
      onTap: () => _showComingSoon(context, 'Inventory'),
    ),
    if (show('services.read'))
    _DashboardItem(
      icon: Icons.content_cut,
      title: 'Service',
      color: Colors.purple,
      onTap: () => _openScreen(context, const ServicesScreen()),
    ),
    if (show('serviceCategories.read'))
    _DashboardItem(
      icon: Icons.category,
      title: 'Service Category',
      color: Colors.purpleAccent,
      onTap: () => _openScreen(context, const ServiceCategoriesScreen()),
    ),
    if (!session.isSignedIn)
    _DashboardItem(
      icon: Icons.groups,
      title: 'Staff',
      color: Colors.indigo,
      onTap: () => _showComingSoon(context, 'Staff'),
    ),
    if (show('appointments.read') || show('schedules.read'))
    _DashboardItem(
      icon: Icons.schedule,
      title: 'Staff Schedule',
      color: Colors.cyan,
      onTap: () => _openScreen(context, const SchedulingBoardScreen()),
    ),
    if (show('leaves.read'))
    _DashboardItem(
      icon: Icons.event_busy,
      title: 'Staff Leave',
      color: Colors.amber,
      onTap: () => _showComingSoon(context, 'Staff Leave'),
    ),
    if (!session.isSignedIn)
    _DashboardItem(
      icon: Icons.bar_chart,
      title: 'Report',
      color: Colors.teal,
      onTap: () => _showComingSoon(context, 'Report'),
    ),
  ];
}

List<_DashboardItem> _systemModuleItems(BuildContext context) {
  final session = AuthSession.instance;
  bool show(String permission) => !session.isSignedIn || session.can(permission);
  return [
    if (show('permissions.read'))
      _DashboardItem(
        icon: Icons.vpn_key,
        title: 'Permission',
        onTap: () => _openScreen(context, const PermissionsScreen()),
      ),
    if (show('roles.read'))
      _DashboardItem(
        icon: Icons.admin_panel_settings,
        title: 'Role',
        onTap: () => _openScreen(context, const RolesScreen()),
      ),
    if (show('roles.manage'))
      _DashboardItem(
        icon: Icons.rule,
        title: 'Role Permission',
        onTap: () => _openScreen(context, const RolesScreen(assignPermissions: true)),
      ),
    _DashboardItem(
      icon: Icons.apartment,
      title: 'Tenant',
      onTap: () => _showComingSoon(context, 'Tenant'),
    ),
    if (show('users.read'))
      _DashboardItem(
        icon: Icons.group,
        title: 'Users',
        onTap: () => _openScreen(context, const UsersScreen()),
      ),
    if (show('users.manage'))
      _DashboardItem(
        icon: Icons.manage_accounts,
        title: 'User Roles',
        onTap: () => _openScreen(context, const UsersScreen(assignRoles: true)),
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
