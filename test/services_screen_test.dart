import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salon_booking_mobile/features/dashboard/screens/dashboard_screen.dart';
import 'package:salon_booking_mobile/features/dashboard/widgets/quick_action_card.dart';
import 'package:salon_booking_mobile/features/services/data/service_directory.dart';
import 'package:salon_booking_mobile/features/services/screens/services_screen.dart';
import 'package:salon_booking_mobile/shared/widgets/app_primary_button.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(ServiceDirectory.resetSession);

  Future<void> pumpServices(WidgetTester tester, Size size) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(home: ServicesScreen(directory: ServiceDirectory())),
    );
    await tester.pumpAndSettle();
  }

  void expectNoExceptions(WidgetTester tester) {
    final errors = <Object>[];
    Object? error = tester.takeException();
    while (error != null) {
      errors.add(error);
      error = tester.takeException();
    }
    expect(errors, isEmpty);
  }

  Finder field(String labelText) =>
      find.widgetWithText(TextFormField, labelText);

  Finder label(String text) {
    return find.byWidgetPredicate(
      (widget) => widget is Text && widget.data == text,
    );
  }

  Finder dropdown<T>(String label) {
    return find.widgetWithText(DropdownButtonFormField<T>, label);
  }

  Future<void> choose<T>(
    WidgetTester tester,
    String label,
    String option,
  ) async {
    final target = dropdown<T>(label);
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.pumpAndSettle();
    await tester.tap(find.text(option).last);
    await tester.pumpAndSettle();
  }

  Future<void> search(WidgetTester tester, String query) async {
    await tester.enterText(find.byKey(const Key('service-search')), query);
    await tester.pumpAndSettle();
  }

  Future<void> openActions(WidgetTester tester, int serviceId) async {
    final button = find.byKey(ValueKey('service-actions-$serviceId'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  testWidgets('service screen renders summary and list', (tester) async {
    await pumpServices(tester, const Size(1440, 900));

    expect(find.text('Service Management'), findsWidgets);
    expect(
      find.text(
        'Manage your salon services, pricing, duration and availability.',
      ),
      findsOneWidget,
    );
    expect(find.text('Add Service'), findsOneWidget);
    expect(find.text('Total Services'), findsOneWidget);
    expect(find.text('Active Services'), findsOneWidget);
    expect(find.text('Categories'), findsOneWidget);
    expect(find.text('Average Price'), findsOneWidget);
    expect(find.text('22'), findsOneWidget);
    expect(find.text('20'), findsOneWidget);
    expect(find.text('6'), findsOneWidget);
    expect(find.text('Anti-Aging Facial'), findsOneWidget);
    expect(find.text('Basic Facial'), findsOneWidget);
    expect(find.byType(DataTable), findsOneWidget);
    expectNoExceptions(tester);
  });

  testWidgets('search matches service name and category', (tester) async {
    await pumpServices(tester, const Size(1440, 900));

    await search(tester, 'Manicure');
    expect(label('Manicure'), findsOneWidget);
    expect(label('Hair Cut'), findsNothing);
    expect(label('Anti-Aging Facial'), findsNothing);

    await search(tester, 'nails');
    expect(label('Manicure'), findsOneWidget);
    expect(label('Pedicure'), findsOneWidget);
    expect(label('Gel Polish'), findsOneWidget);
    expect(label('Hair Cut'), findsNothing);
  });

  testWidgets('category filter limits the list', (tester) async {
    await pumpServices(tester, const Size(1440, 900));

    await choose<String>(tester, 'Category', 'Nails');

    expect(find.text('Manicure'), findsOneWidget);
    expect(find.text('Pedicure'), findsOneWidget);
    expect(find.text('Nail Art'), findsOneWidget);
    expect(find.text('Hair Cut'), findsNothing);
    expect(find.text('Anti-Aging Facial'), findsNothing);
  });

  testWidgets('status filter shows inactive services', (tester) async {
    await pumpServices(tester, const Size(1440, 900));

    await choose<String>(tester, 'Status', 'Inactive');

    expect(find.text('Nail Art'), findsOneWidget);
    expect(find.text('Relaxation Massage'), findsOneWidget);
    expect(find.text('Hair Cut'), findsNothing);
    expect(find.text('Manicure'), findsNothing);
  });

  testWidgets('sort by price orders the cheapest services first', (
    tester,
  ) async {
    await pumpServices(tester, const Size(1440, 900));

    await choose<String>(tester, 'Sort', 'Price');

    expect(find.text('Threading'), findsOneWidget);
    expect(find.text('Bridal Makeup'), findsNothing);
  });

  testWidgets('create service opens the form', (tester) async {
    await pumpServices(tester, const Size(1440, 900));

    await tester.tap(find.text('Add Service'));
    await tester.pumpAndSettle();

    expect(find.text('Create Service'), findsWidgets);
    expect(
      find.text('Add a service clients can book, with a duration and price.'),
      findsOneWidget,
    );
    expect(field('Service Name'), findsOneWidget);
    expect(dropdown<String>('Category'), findsOneWidget);
    expect(dropdown<int>('Branch'), findsOneWidget);
    expect(field('Duration (minutes)'), findsOneWidget);
    expect(field('Price (Rs.)'), findsOneWidget);
    expect(field('Description'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    expectNoExceptions(tester);
  });

  testWidgets('create service validates required and numeric fields', (
    tester,
  ) async {
    await pumpServices(tester, const Size(1280, 1400));

    await tester.tap(find.text('Add Service'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Service name is required'), findsOneWidget);
    expect(find.text('Category is required'), findsOneWidget);
    expect(find.text('Duration is required'), findsOneWidget);
    expect(find.text('Price is required'), findsOneWidget);
    expect(find.text('Create Service'), findsWidgets);

    await tester.enterText(field('Service Name'), 'Aroma Massage');
    await tester.enterText(field('Duration (minutes)'), 'abc');
    await tester.enterText(field('Price (Rs.)'), '0');
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid duration in minutes'), findsOneWidget);
    expect(find.text('Enter a valid price'), findsOneWidget);
    expect(find.text('Create Service'), findsWidgets);
  });

  testWidgets('saving a service returns it to the list', (tester) async {
    await pumpServices(tester, const Size(1280, 1400));

    await tester.tap(find.text('Add Service'));
    await tester.pumpAndSettle();

    await tester.enterText(field('Service Name'), 'Aroma Massage');
    await tester.enterText(field('Duration (minutes)'), '60');
    await tester.enterText(field('Price (Rs.)'), '4500');
    await tester.enterText(
      field('Description'),
      'Warm oil massage for the shoulders and scalp.',
    );
    await choose<String>(tester, 'Category', 'Spa');
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Aroma Massage was saved.'), findsOneWidget);
    expect(
      find.text(
        'Manage your salon services, pricing, duration and availability.',
      ),
      findsOneWidget,
    );
    expect(find.text('Aroma Massage'), findsOneWidget);
    expect(find.text('23'), findsOneWidget);
  });

  testWidgets('service details opens from the list', (tester) async {
    await pumpServices(tester, const Size(1440, 900));

    await search(tester, 'Hair Colour');
    await openActions(tester, 2);
    await tester.tap(find.text('View'));
    await tester.pumpAndSettle();

    expect(find.text('Service Details'), findsWidgets);
    expect(find.text('Hair Colour'), findsWidgets);
    expect(find.text('90 minutes'), findsOneWidget);
    expect(find.text('Rs. 7,500.00'), findsWidgets);
    expect(find.text('Operational Information'), findsOneWidget);
    expect(
      find.text(
        'Professional colour service with a consultation, application, and styled finish.',
      ),
      findsOneWidget,
    );
    expect(find.text('Edit Service'), findsOneWidget);
    expect(find.textContaining('SRV-002'), findsWidgets);
    expect(find.textContaining('Colombo'), findsWidgets);
    expectNoExceptions(tester);
  });

  testWidgets('edit service opens with populated values', (tester) async {
    await pumpServices(tester, const Size(1280, 1400));

    await search(tester, 'Hair Colour');
    await openActions(tester, 2);
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Service'), findsWidgets);
    expect(
      tester.widget<TextFormField>(field('Service Name')).controller?.text,
      'Hair Colour',
    );
    expect(
      tester.widget<TextFormField>(field('Service Code')).controller?.text,
      'SRV-002',
    );
    expect(
      tester
          .widget<TextFormField>(field('Duration (minutes)'))
          .controller
          ?.text,
      '90',
    );
    expect(
      tester.widget<TextFormField>(field('Price (Rs.)')).controller?.text,
      '7500',
    );
    expect(
      tester
          .widget<TextFormField>(field('Description'))
          .controller
          ?.text
          .contains('Professional colour service'),
      isTrue,
    );
    expect(
      tester.state<FormFieldState<String>>(dropdown<String>('Category')).value,
      'Hair',
    );
    expect(tester.state<FormFieldState<int>>(dropdown<int>('Branch')).value, 1);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    expectNoExceptions(tester);
  });

  testWidgets('delete confirmation can cancel or remove the service', (
    tester,
  ) async {
    await pumpServices(tester, const Size(1440, 900));

    await search(tester, 'Nail Art');
    await openActions(tester, 14);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Delete Service?'), findsOneWidget);
    expect(
      find.textContaining('Are you sure you want to delete "Nail Art"'),
      findsOneWidget,
    );
    expect(
      find.textContaining('This action cannot be undone.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(label('Nail Art'), findsOneWidget);

    await openActions(tester, 14);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AppPrimaryButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(label('Nail Art'), findsNothing);
    expect(find.text('Nail Art was deleted.'), findsOneWidget);
    expectNoExceptions(tester);
  });

  testWidgets('layouts do not overflow on desktop, tablet, or phone', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));

    for (final size in const [
      Size(1440, 900),
      Size(1024, 768),
      Size(768, 1024),
      Size(390, 844),
    ]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        MaterialApp(home: ServicesScreen(directory: ServiceDirectory())),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Manage your salon services, pricing, duration and availability.',
        ),
        findsOneWidget,
      );
      expect(
        find.byType(DataTable),
        size.width >= 948 ? findsOneWidget : findsNothing,
      );
      expectNoExceptions(tester);
    }

    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(
      MaterialApp(home: ServicesScreen(directory: ServiceDirectory())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add Service'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save'));
    expect(find.text('Create Service'), findsWidgets);
    expectNoExceptions(tester);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await search(tester, 'Hair Colour');
    await openActions(tester, 2);
    await tester.tap(find.text('View'));
    await tester.pumpAndSettle();
    expect(find.text('90 minutes'), findsOneWidget);
    await tester.ensureVisible(find.text('Edit Service'));
    expectNoExceptions(tester);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await search(tester, 'Nail Art');
    await openActions(tester, 14);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Delete Service?'), findsOneWidget);
    expectNoExceptions(tester);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expectNoExceptions(tester);
  });

  testWidgets('dashboard service card opens service management', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1440, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(home: DashboardScreen()));
    await tester.pumpAndSettle();

    final service = find.widgetWithText(QuickActionCard, 'Service');
    await tester.ensureVisible(service);
    await tester.tap(service);
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Manage your salon services, pricing, duration and availability.',
      ),
      findsOneWidget,
    );
    expectNoExceptions(tester);
  });
}
