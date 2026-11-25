import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salon_booking_mobile/core/api/api_exception.dart';
import 'package:salon_booking_mobile/core/auth/auth_session.dart';
import 'package:salon_booking_mobile/features/rentals/data/rental_repository.dart';
import 'package:salon_booking_mobile/features/rentals/screens/rentals_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(AuthSession.instance.clear);
  tearDown(AuthSession.instance.clear);

  testWidgets('a stylist is denied the rental screen', (tester) async {
    _signIn({'appointments.own.read'}, employeeId: 4);
    await tester.pumpWidget(MaterialApp(home: RentalsScreen(repository: _Rentals())));
    expect(find.text('You do not have permission to view rentals.'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('a supervisor can read charges and cannot reserve or issue', (tester) async {
    _signIn({'rentals.read', 'appointments.read'}, branchId: 2);
    final rentals = _Rentals()
      ..assetsResult = [_asset()]
      ..reservationsResult = [_reservation(status: 'Reserved')];
    await tester.pumpWidget(MaterialApp(home: RentalsScreen(repository: rentals)));
    await tester.pumpAndSettle();

    expect(find.textContaining('25.00 per use'), findsOneWidget);
    expect(find.textContaining('buffer 45m'), findsOneWidget);
    expect(find.text('Reserve'), findsNothing);
    expect(find.text('Issue'), findsNothing);
    expect(find.text('Edit'), findsNothing);
    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('a load failure can be retried', (tester) async {
    _signIn({'rentals.read'});
    final rentals = _Rentals()..loadError = const ApiException('Rentals unavailable');
    await tester.pumpWidget(MaterialApp(home: RentalsScreen(repository: rentals)));
    await tester.pumpAndSettle();
    expect(find.text('Rentals unavailable'), findsOneWidget);

    rentals
      ..loadError = null
      ..assetsResult = [_asset()];
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Silk saree'), findsOneWidget);
  });

  testWidgets('a branch user saves an asset only in their branch', (tester) async {
    _signIn({'rentals.read', 'rentals.manage', 'rentals.issue'}, branchId: 4);
    final rentals = _Rentals();
    await tester.pumpWidget(MaterialApp(home: RentalsScreen(repository: rentals, loadBranches: () async => const [
      RentalBranchChoice(id: 9, name: 'Other'),
    ])));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('Branch'), findsNothing);
    await tester.enterText(find.widgetWithText(TextField, 'Code'), 'SAREE');
    await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Silk saree');
    await tester.enterText(find.widgetWithText(TextField, 'Charge per use'), '25');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(rentals.savedBranch, 4);
    expect(rentals.savedActive, isTrue);
  });

  testWidgets('a salon-wide user chooses a branch and a return records discrepancy notes', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    _signIn({'rentals.read', 'rentals.manage', 'rentals.issue'});
    final rentals = _Rentals()
      ..assetsResult = [_asset()]
      ..reservationsResult = [_reservation(status: 'Issued')];
    await tester.pumpWidget(MaterialApp(
      home: RentalsScreen(
        repository: rentals,
        loadBranches: () async => const [RentalBranchChoice(id: 3, name: 'Kollupitiya')],
        loadCustomers: () async => const [RentalCustomerChoice(id: 7, name: 'Maya Fernando', branchId: 3)],
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('Kollupitiya'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Code'), 'SAREE');
    await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Silk saree');
    await tester.enterText(find.widgetWithText(TextField, 'Charge per use'), '25');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(rentals.savedBranch, 3);

    await tester.tap(find.text('Return'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Condition'), 'Stain');
    await tester.enterText(find.widgetWithText(TextField, 'Discrepancy notes'), 'Hem marked');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(rentals.returnCondition, 'Stain');
    expect(rentals.returnNotes, 'Hem marked');
  });
}

void _signIn(Set<String> permissions, {int? branchId, int? employeeId}) {
  AuthSession.instance.save(
    accessToken: 'token',
    username: 'staff',
    expiresAt: DateTime.now().add(const Duration(hours: 1)),
    branchId: branchId,
    employeeId: employeeId,
    permissions: permissions,
  );
}

RentalAsset _asset() => RentalAsset(
      id: 5,
      branchId: 3,
      code: 'SAREE',
      name: 'Silk saree',
      category: 'Costume',
      chargePerUse: 25,
      cleaningBufferMinutes: 45,
      isActive: true,
      availability: 'Available',
    );

RentalReservation _reservation({required String status}) => RentalReservation(
      id: 11,
      branchId: 3,
      customerId: 7,
      customerName: 'Maya Fernando',
      assetName: 'Silk saree',
      status: status,
      isOverdue: status == 'Issued',
      chargePerUse: 25,
      isBillable: false,
      conditionDiscrepancy: false,
    );

class _Rentals extends RentalRepository {
  List<RentalAsset> assetsResult = [];
  List<RentalReservation> reservationsResult = [];
  Object? loadError;
  int? savedBranch;
  bool? savedActive;
  String? returnCondition;
  String? returnNotes;

  @override
  Future<List<RentalAsset>> assets({bool includeInactive = true}) async {
    if (loadError != null) throw loadError!;
    return assetsResult;
  }

  @override
  Future<List<RentalReservation>> reservations() async {
    if (loadError != null) throw loadError!;
    return reservationsResult;
  }

  @override
  Future<void> saveAsset({
    int? id,
    required int branchId,
    required String code,
    required String name,
    required String category,
    required double chargePerUse,
    required int cleaningBufferMinutes,
    bool isActive = true,
  }) async {
    savedBranch = branchId;
    savedActive = isActive;
  }

  @override
  Future<void> returned(int id, String condition, {String? notes}) async {
    returnCondition = condition;
    returnNotes = notes;
  }
}
