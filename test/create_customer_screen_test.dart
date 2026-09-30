import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salon_booking_mobile/features/customers/screens/create_customer_screen.dart';
import 'package:salon_booking_mobile/features/customers/screens/customers_screen.dart';
import 'package:salon_booking_mobile/features/dashboard/screens/dashboard_screen.dart';
import 'package:salon_booking_mobile/features/dashboard/widgets/dashboard_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> openCreate(WidgetTester tester, Size size) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: CustomersScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Amanda Silva'), findsOneWidget);
    await tester.tap(find.text('Add Customer'));
    await tester.pumpAndSettle();
  }

  Finder field(String label) => find.widgetWithText(TextFormField, label);

  testWidgets('create customer form on a wide layout', (tester) async {
    await openCreate(tester, const Size(1280, 900));

    expect(find.text('Create Customer'), findsWidgets);
    expect(field('Customer Code'), findsOneWidget);
    expect(field('First Name'), findsOneWidget);
    expect(field('Last Name'), findsOneWidget);
    expect(field('Mobile Number'), findsOneWidget);
    expect(field('Email'), findsOneWidget);
    expect(find.widgetWithText(DropdownButtonFormField<String>, 'Gender'), findsOneWidget);
    expect(field('Date of Birth'), findsOneWidget);
    expect(field('Address'), findsOneWidget);
    expect(field('Notes'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.byType(Switch), findsOneWidget);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);

    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Customer code is required'), findsOneWidget);
    expect(find.text('First name is required'), findsOneWidget);
    expect(find.text('Last name is required'), findsOneWidget);
    expect(find.text('Phone number is required.'), findsOneWidget);
    expect(find.text('Create Customer'), findsWidgets);

    await tester.enterText(field('Mobile Number'), '12345');
    await tester.enterText(field('Email'), 'not-an-email');
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid phone number.'), findsOneWidget);
    expect(find.text('Enter a valid email address.'), findsOneWidget);

    await tester.enterText(field('Customer Code'), 'CUS-099');
    await tester.enterText(field('First Name'), 'Nimal');
    await tester.enterText(field('Last Name'), 'Perera');
    await tester.enterText(field('Mobile Number'), '0771234567');
    await tester.enterText(field('Email'), 'nimal@example.com');
    await tester.enterText(field('Address'), 'Colombo');
    await tester.enterText(field('Notes'), 'New customer');

    final genderField = find.byType(DropdownButtonFormField<String>);
    await tester.ensureVisible(genderField);
    await tester.tap(genderField);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Male').last);
    await tester.pumpAndSettle();
    expect(tester.state<FormFieldState<String>>(genderField).value, 'Male');

    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);

    await tester.ensureVisible(field('Date of Birth'));
    await tester.tap(field('Date of Birth'));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsNothing);
    expect(find.textContaining('/'), findsWidgets);

    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Nimal Perera was saved.'), findsOneWidget);
    expect(find.text('Manage customer records and relationships'), findsOneWidget);
    expect(find.text('Amanda Silva'), findsOneWidget);
  });

  testWidgets('cancel returns to the customers list', (tester) async {
    await openCreate(tester, const Size(1280, 900));

    await tester.ensureVisible(find.text('Cancel'));
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Manage customer records and relationships'), findsOneWidget);
    expect(find.text('Add Customer'), findsOneWidget);
    expect(find.text('Amanda Silva'), findsOneWidget);
  });

  testWidgets('narrow layout does not overflow', (tester) async {
    await openCreate(tester, const Size(360, 800));

    expect(find.text('Create Customer'), findsWidgets);
    expect(field('First Name'), findsOneWidget);
    expect(field('Last Name'), findsOneWidget);

    await tester.ensureVisible(find.text('Save'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('dashboard opens create customer', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(MaterialApp(home: DashboardScreen()));
    await tester.pumpAndSettle();

    final customersModule = find.widgetWithText(DashboardCard, 'Customers');
    await tester.ensureVisible(customersModule);
    await tester.tap(customersModule);
    await tester.pumpAndSettle();

    expect(find.text('Add Customer'), findsOneWidget);
    await tester.tap(find.text('Add Customer'));
    await tester.pumpAndSettle();

    expect(find.text('Customer Code'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('create screen builds directly without overflow', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(home: CreateCustomerScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Customer Code'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
