import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salon_booking_mobile/features/dashboard/screens/dashboard_screen.dart';
import 'package:salon_booking_mobile/features/dashboard/widgets/dashboard_card.dart';
import 'package:salon_booking_mobile/features/dashboard/widgets/quick_action_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const quickActionTitles = [
    'Appointment',
    'Appointment Service',
    'Appointment Status History',
    'Branch',
    'Customer',
    'Customer Note',
    'Employee',
    'Invoice',
    'Payment',
    'Inventory',
    'Service',
    'Service Category',
    'Staff',
    'Staff Schedule',
    'Staff Leave',
    'Report',
  ];

  const systemModuleTitles = [
    'Permission',
    'Role',
    'Role Permission',
    'Tenant',
    'Users',
    'User Roles',
    'Setting',
  ];

  Future<void> pumpDashboard(WidgetTester tester, Size size) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(home: DashboardScreen()));
    await tester.pumpAndSettle();
  }

  testWidgets('dashboard module cards follow the final order', (tester) async {
    await pumpDashboard(tester, const Size(1440, 2400));

    expect(find.text('Quick Action'), findsOneWidget);
    expect(find.text('System Modules'), findsOneWidget);

    final quickTitles = tester
        .widgetList<QuickActionCard>(find.byType(QuickActionCard))
        .map((card) => card.title)
        .toList();
    final systemTitles = tester
        .widgetList<DashboardCard>(find.byType(DashboardCard))
        .map((card) => card.title)
        .toList();

    expect(quickTitles, quickActionTitles);
    expect(systemTitles, systemModuleTitles);
    expect(quickTitles.length + systemTitles.length, 23);
    expect(tester.takeException(), isNull);
  });

  testWidgets('module grids do not overflow on desktop, laptop, or phone', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));

    for (final size in const [
      Size(1440, 900),
      Size(1024, 768),
      Size(600, 800),
    ]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(MaterialApp(home: DashboardScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Quick Action'), findsOneWidget);
      expect(find.text('System Modules'), findsOneWidget);
      expect(find.byType(QuickActionCard), findsNWidgets(16));
      expect(find.byType(DashboardCard), findsNWidgets(7));
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('module cards do not overflow on a phone-width dashboard', (
    tester,
  ) async {
    final details = <FlutterErrorDetails>[];
    final previousOnError = FlutterError.onError;
    FlutterError.onError = details.add;
    addTearDown(() => FlutterError.onError = previousOnError);

    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(home: DashboardScreen()));
    await tester.pumpAndSettle();

    expect(find.byType(QuickActionCard), findsNWidgets(16));
    expect(find.byType(DashboardCard), findsNWidgets(7));

    while (tester.takeException() != null) {}

    final moduleOverflows = details.where((detail) {
      final text = detail.toString();
      return text.contains('quick_action_card.dart') ||
          text.contains('dashboard_card.dart');
    });
    expect(moduleOverflows, isEmpty);
  });

  testWidgets('unimplemented modules show a coming soon message', (tester) async {
    await pumpDashboard(tester, const Size(1440, 2400));

    final branch = find.widgetWithText(QuickActionCard, 'Branch');
    await tester.ensureVisible(branch);
    await tester.tap(branch);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Branch is coming soon.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
