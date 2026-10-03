import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salon_booking_mobile/features/dashboard/screens/dashboard_screen.dart';
import 'package:salon_booking_mobile/features/dashboard/widgets/quick_action_card.dart';
import 'package:salon_booking_mobile/features/scheduling/screens/scheduling_board_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpAt(WidgetTester tester, Widget home, Size size) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(home: home));
    await tester.pumpAndSettle();
  }

  Finder dropdown(String label) {
    return find.widgetWithText(DropdownButtonFormField<String>, label);
  }

  Future<void> choose(WidgetTester tester, String label, String option) async {
    final field = dropdown(label);
    await tester.ensureVisible(field);
    await tester.tap(field);
    await tester.pumpAndSettle();
    await tester.tap(find.text(option).last);
    await tester.pumpAndSettle();
  }

  testWidgets('schedule board shows staff, bookings, and availability states', (
    tester,
  ) async {
    await pumpAt(tester, const SchedulingBoardScreen(), const Size(1440, 900));

    expect(find.text('10 October 2026'), findsOneWidget);
    expect(
      find.text('Staff availability and appointments for the day'),
      findsOneWidget,
    );
    expect(find.text('Kasun Perera'), findsOneWidget);
    expect(find.text('Amali Fernando'), findsOneWidget);
    expect(find.text('Ishara Jayawardena · On leave'), findsOneWidget);
    expect(find.text('Dilshan Wickrama · Off from 13:00'), findsOneWidget);
    expect(find.text('Break'), findsWidgets);
    expect(find.text('Available'), findsWidgets);
    expect(find.text('Booked'), findsOneWidget);
    expect(find.text('Conflict'), findsWidgets);
    expect(find.textContaining('Overlap · Kasun Perera'), findsOneWidget);
    expect(find.text('Find Availability'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Ishara Jayawardena'),
      400,
      scrollable: find.descendant(
        of: find.byKey(const Key('schedule-staff-list')),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.text('On leave'), findsWidgets);
    expect(find.text('Off duty'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('appointment detail shows services across staff', (tester) async {
    await pumpAt(tester, const SchedulingBoardScreen(), const Size(1440, 900));

    final haircut = find.byTooltip('Nimal Perera, Haircut');
    await tester.ensureVisible(haircut);
    await tester.tap(haircut);
    await tester.pumpAndSettle();

    expect(find.text('Appointment #APT-1042'), findsOneWidget);
    expect(find.text('Nimal Perera'), findsWidgets);
    expect(find.text('Haircut'), findsWidgets);
    expect(find.text('Hair Coloring'), findsWidgets);
    expect(find.text('Hair Wash'), findsWidgets);
    expect(find.text('30 min · Kasun Perera'), findsWidgets);
    expect(find.text('60 min · Amali Fernando'), findsOneWidget);
    expect(find.text('Confirmed'), findsWidgets);
    expect(find.text('Change Employee'), findsOneWidget);

    await tester.tap(find.text('Change Employee'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Employee change noted for APT-1042.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('available slot can be selected', (tester) async {
    await pumpAt(tester, const SchedulingBoardScreen(), const Size(1440, 900));

    final slot = find.byTooltip('Open 09:00 for Kasun Perera');
    await tester.ensureVisible(slot);
    await tester.tap(slot);
    await tester.pumpAndSettle();

    expect(find.text('Open time slot'), findsOneWidget);
    expect(find.text('This time is open for a booking.'), findsOneWidget);
    expect(find.text('09:00 – 09:30'), findsOneWidget);

    await tester.tap(find.text('Use this slot'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('09:00 – 09:30 noted for Kasun Perera.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('find availability shows sample schedules', (tester) async {
    await pumpAt(tester, const SchedulingBoardScreen(), const Size(1440, 900));

    await tester.tap(find.text('Find Availability'));
    await tester.pumpAndSettle();

    expect(find.text('Find availability'), findsOneWidget);
    expect(find.text('Haircut — 30 min'), findsOneWidget);
    expect(find.text('Hair Coloring — 60 min'), findsOneWidget);
    expect(find.text('Hair Wash — 30 min'), findsOneWidget);
    expect(find.text('Option 1'), findsOneWidget);
    expect(find.text('10:00 – 12:00'), findsOneWidget);
    expect(find.text('Option 2'), findsOneWidget);

    await tester.tap(find.text('Select').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      find.text('10:00 – 12:00 selected for Nimal Perera.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('date navigation and staff filter update the board', (
    tester,
  ) async {
    await pumpAt(tester, const SchedulingBoardScreen(), const Size(1280, 900));

    await tester.tap(find.byTooltip('Next day'));
    await tester.pumpAndSettle();
    expect(find.text('11 October 2026'), findsOneWidget);
    expect(find.text('Nimal Perera'), findsNothing);
    expect(find.text('Harini Silva'), findsOneWidget);

    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();
    expect(find.text('10 October 2026'), findsOneWidget);
    expect(find.text('Nimal Perera'), findsWidgets);

    await tester.tap(find.byTooltip('Previous day'));
    await tester.pumpAndSettle();
    expect(find.text('9 October 2026'), findsOneWidget);
    expect(find.text('Ruwan Perera'), findsOneWidget);

    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();
    await choose(tester, 'Staff', 'Kasun Perera');
    expect(find.text('Amali Fernando'), findsNothing);
    expect(find.text('Kasun Perera'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dashboard opens the scheduling board', (tester) async {
    await pumpAt(tester, DashboardScreen(), const Size(1440, 2400));

    final schedule = find.widgetWithText(QuickActionCard, 'Staff Schedule');
    await tester.ensureVisible(schedule);
    await tester.tap(schedule);
    await tester.pumpAndSettle();

    expect(find.text('10 October 2026'), findsOneWidget);
    expect(find.text('Kasun Perera'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('schedule board does not overflow at presentation sizes', (
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
      await tester.pumpWidget(const MaterialApp(home: SchedulingBoardScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Find Availability'), findsOneWidget);
      expect(find.text('Kasun Perera'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Find Availability'));
      await tester.pumpAndSettle();
      expect(find.text('Available schedules'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();

      final haircut = find.byTooltip('Nimal Perera, Haircut');
      await tester.ensureVisible(haircut);
      await tester.tap(haircut);
      await tester.pumpAndSettle();
      expect(find.text('Appointment #APT-1042'), findsOneWidget);
      expect(find.text('Change Employee'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
    }
  });
}
