import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salon_booking_mobile/features/appointments/models/appointment_status.dart';
import 'package:salon_booking_mobile/features/appointments/screens/appointments_screen.dart';
import 'package:salon_booking_mobile/features/appointments/screens/create_appointment_screen.dart';
import 'package:salon_booking_mobile/features/dashboard/screens/dashboard_screen.dart';
import 'package:salon_booking_mobile/features/dashboard/widgets/quick_action_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpAt(WidgetTester tester, Widget home, Size size) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(home: home));
    await tester.pumpAndSettle();
  }

  Finder dropdown<T>(String label) {
    return find.widgetWithText(DropdownButtonFormField<T>, label);
  }

  Future<void> choose<T>(WidgetTester tester, String label, String option) async {
    final field = dropdown<T>(label);
    await tester.ensureVisible(field);
    await tester.tap(field);
    await tester.pumpAndSettle();
    await tester.tap(find.text(option).last);
    await tester.pumpAndSettle();
  }

  testWidgets('appointment list filters search, status, and date', (tester) async {
    await pumpAt(tester, const AppointmentsScreen(), const Size(1280, 900));

    expect(find.text('Schedule and review salon appointments'), findsOneWidget);
    expect(find.text('Amanda Silva'), findsWidgets);
    expect(find.text('Hair Colour, Hair Spa'), findsOneWidget);
    expect(find.text('09:00'), findsWidgets);
    expect(find.text('09:45'), findsOneWidget);
    expect(find.text('Add Appointment'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Bridal');
    await tester.pumpAndSettle();
    expect(find.text('Daniel Silva'), findsWidgets);
    expect(find.text('Amanda Silva'), findsNothing);
    expect(find.text('Bridal Makeup'), findsWidgets);

    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();

    await choose<String>(tester, 'Status', 'Cancelled');
    expect(find.text('Nethmi Perera'), findsOneWidget);
    expect(find.text('Amanda Silva'), findsNothing);

    await choose<String>(tester, 'Status', 'All');
    await choose<String>(tester, 'Date', '29/09/2026');
    expect(find.text('Nethmi Perera'), findsOneWidget);
    expect(find.text('Sarah Perera'), findsNothing);

    await choose<String>(tester, 'Date', 'All');
    await tester.enterText(find.byType(TextField), 'zzzz');
    await tester.pumpAndSettle();
    expect(find.text('No appointments found'), findsOneWidget);

    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Actions').first);
    await tester.pumpAndSettle();
    expect(find.text('View'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('create appointment validates, edits services, and saves', (tester) async {
    await pumpAt(tester, const AppointmentsScreen(), const Size(1280, 900));
    await tester.tap(find.text('Add Appointment'));
    await tester.pumpAndSettle();

    expect(find.text('Create Appointment'), findsWidgets);
    expect(find.text('Appointment Services'), findsOneWidget);
    expect(dropdown<int>('Branch'), findsOneWidget);
    expect(dropdown<int>('Customer'), findsOneWidget);
    expect(dropdown<int>('Employee'), findsOneWidget);
    expect(dropdown<AppointmentStatus>('Status'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Appointment Date'), findsOneWidget);
    expect(dropdown<TimeOfDay>('Start Time'), findsOneWidget);
    expect(dropdown<TimeOfDay>('End Time'), findsOneWidget);
    expect(dropdown<int>('Service'), findsOneWidget);
    expect(find.text('Notes'), findsNothing);
    expect(find.text('Remarks'), findsNothing);
    expect(find.text('Quantity'), findsNothing);

    final branch = tester.getTopLeft(dropdown<int>('Branch'));
    final customer = tester.getTopLeft(dropdown<int>('Customer'));
    expect((branch.dy - customer.dy).abs(), lessThan(8));

    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Branch is required'), findsOneWidget);
    expect(find.text('Customer is required'), findsOneWidget);
    expect(find.text('Employee is required'), findsOneWidget);
    expect(find.text('Appointment date is required'), findsOneWidget);
    expect(find.text('Start time is required'), findsOneWidget);
    expect(find.text('End time is required'), findsOneWidget);
    expect(find.text('Service is required'), findsOneWidget);
    expect(find.text('Create Appointment'), findsWidgets);

    await choose<int>(tester, 'Branch', 'Colombo (BR-001)');
    await choose<int>(tester, 'Customer', 'Amanda Silva (CUS-001)');
    await choose<int>(tester, 'Employee', 'Kevin Perera · Stylist');
    await choose<TimeOfDay>(tester, 'Start Time', '10:00');
    await choose<TimeOfDay>(tester, 'End Time', '09:00');

    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('End time must be after start time'), findsOneWidget);

    await choose<TimeOfDay>(tester, 'Start Time', '09:00');
    await choose<TimeOfDay>(tester, 'End Time', '10:00');

    final dateField = find.widgetWithText(TextFormField, 'Appointment Date');
    await tester.ensureVisible(dateField);
    await tester.tap(dateField);
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.textContaining('/'), findsWidgets);

    await choose<int>(tester, 'Service', 'Hair Cut · 45 min · Rs. 2,500.00');
    await tester.ensureVisible(find.text('Add'));
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    await choose<int>(tester, 'Service', 'Hair Colour · 90 min · Rs. 7,500.00');
    await tester.ensureVisible(find.text('Add'));
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(find.text('45 min · Rs. 2,500.00'), findsOneWidget);
    expect(find.text('90 min · Rs. 7,500.00'), findsOneWidget);

    await tester.tap(find.byTooltip('Remove Hair Cut'));
    await tester.pumpAndSettle();
    expect(find.text('45 min · Rs. 2,500.00'), findsNothing);
    expect(find.text('90 min · Rs. 7,500.00'), findsOneWidget);
    expect(dropdown<int>('Employee'), findsOneWidget);
    expect(dropdown<TimeOfDay>('Start Time'), findsOneWidget);
    expect(dropdown<TimeOfDay>('End Time'), findsOneWidget);

    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Amanda Silva was saved.'), findsOneWidget);
    expect(find.text('Schedule and review salon appointments'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancel returns to the appointment list', (tester) async {
    await pumpAt(tester, const AppointmentsScreen(), const Size(1280, 900));
    await tester.tap(find.text('Add Appointment'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Cancel'));
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Add Appointment'), findsOneWidget);
    expect(find.text('Amanda Silva'), findsWidgets);
  });

  testWidgets('dashboard opens the appointment list and create form', (tester) async {
    await pumpAt(tester, DashboardScreen(), const Size(1400, 2400));

    final appointments = find.widgetWithText(QuickActionCard, 'Appointment');
    await tester.ensureVisible(appointments);
    await tester.tap(appointments);
    await tester.pumpAndSettle();

    expect(find.text('Add Appointment'), findsOneWidget);
    await tester.tap(find.text('Add Appointment'));
    await tester.pumpAndSettle();

    expect(find.text('Branch'), findsWidgets);
    expect(find.text('Service'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop, laptop, and mobile layouts do not overflow', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));

    for (final size in const [
      Size(1440, 900),
      Size(1024, 768),
      Size(768, 1024),
      Size(360, 800),
    ]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(const MaterialApp(home: AppointmentsScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Add Appointment'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Add Appointment'));
      await tester.pumpAndSettle();
      expect(find.text('Create Appointment'), findsWidgets);

      final branch = tester.getTopLeft(dropdown<int>('Branch'));
      final customer = tester.getTopLeft(dropdown<int>('Customer'));
      if (size.width >= 640) {
        expect((branch.dy - customer.dy).abs(), lessThan(8));
      } else {
        expect(customer.dy, greaterThan(branch.dy + 20));
      }

      await tester.ensureVisible(find.text('Save'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.pageBack();
      await tester.pumpAndSettle();
    }
  });

  testWidgets('create screen builds directly without overflow', (tester) async {
    await pumpAt(tester, const CreateAppointmentScreen(), const Size(800, 700));

    expect(find.text('Appointment Services'), findsOneWidget);
    expect(find.text('Employee'), findsWidgets);
    expect(find.text('Start Time'), findsWidgets);

    final branch = tester.getTopLeft(dropdown<int>('Branch'));
    final customer = tester.getTopLeft(dropdown<int>('Customer'));
    expect((branch.dy - customer.dy).abs(), lessThan(8));
    expect(tester.takeException(), isNull);
  });
}
