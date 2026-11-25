import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salon_booking_mobile/core/auth/auth_session.dart';
import 'package:salon_booking_mobile/features/billing/data/billing_repository.dart';
import 'package:salon_booking_mobile/features/billing/models/billing_models.dart';
import 'package:salon_booking_mobile/features/billing/screens/bill_detail_screen.dart';
import 'package:salon_booking_mobile/features/billing/screens/bill_editor_screen.dart';
import 'package:salon_booking_mobile/features/customers/data/customer_repository.dart';
import 'package:salon_booking_mobile/features/customers/models/customer_model.dart';
import 'package:salon_booking_mobile/features/rentals/data/rental_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(AuthSession.instance.clear);
  tearDown(AuthSession.instance.clear);

  testWidgets('a draft can be created with no lines in the customer branch', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    _signIn({'bills.manage', 'rentals.read'});
    final billing = _Billing();
    await tester.pumpWidget(MaterialApp(
      home: BillEditorScreen(repository: billing, customers: _Customers()),
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining('A draft can be saved with no lines'), findsOneWidget);
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Maya Fernando').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create draft').last);
    await tester.pumpAndSettle();

    expect(billing.customerId, 7);
    expect(billing.branchId, 3);
    expect(billing.serviceIds, isEmpty);
    expect(billing.products, isEmpty);
    expect(find.text('Add rental'), findsOneWidget);
  });

  testWidgets('a returned rental is added from the customer list, not a typed id', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    _signIn({'bills.manage', 'rentals.read'});
    final billing = _Billing();
    await tester.pumpWidget(MaterialApp(
      home: BillDetailScreen(billId: 8, repository: billing, rentals: _ReturnedRentals()),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add rental'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Silk saree'), findsOneWidget);
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    expect(billing.addedReservation, 11);
  });
}

void _signIn(Set<String> permissions) {
  AuthSession.instance.save(
    accessToken: 'token',
    username: 'desk',
    expiresAt: DateTime.now().add(const Duration(hours: 1)),
    permissions: permissions,
  );
}

SalonBill _draft() => SalonBill(
      id: 8,
      branchId: 3,
      customerId: 7,
      customerName: 'Maya Fernando',
      status: 'Draft',
      paymentStatus: 'Unpaid',
      billDate: DateTime.utc(2026, 11, 25),
      subtotal: 0,
      taxAmount: 0,
      total: 0,
      netCollected: 0,
      outstanding: 0,
      rowVersion: 'row',
      lines: [],
      payments: [],
    );

class _Billing extends BillingRepository {
  int? customerId;
  int? branchId;
  List<int> serviceIds = const [];
  List<Map<String, dynamic>> products = const [];
  int? addedReservation;

  @override
  Future<List<RetailProduct>> listProducts({String? search, bool includeInactive = false}) async => const [];

  @override
  Future<SalonBill> createBill({
    required int customerId,
    int? branchId,
    int? appointmentId,
    List<int> appointmentServiceIds = const [],
    List<Map<String, dynamic>> products = const [],
    String? notes,
  }) async {
    this.customerId = customerId;
    this.branchId = branchId;
    serviceIds = appointmentServiceIds;
    this.products = products;
    return _draft();
  }

  @override
  Future<SalonBill> getBill(int id) async => _draft();

  @override
  Future<SalonBill> addRental({
    required int billId,
    required String rowVersion,
    required int reservationId,
  }) async {
    addedReservation = reservationId;
    return _draft();
  }
}

class _Customers extends CustomerRepository {
  @override
  Future<List<Customer>> list() async => [
        Customer(
          id: 7,
          customerCode: 'C7',
          firstName: 'Maya',
          lastName: 'Fernando',
          mobileNumber: '0770000000',
          branchId: 3,
          createdDate: DateTime(2026, 1, 1),
        ),
      ];
}

class _ReturnedRentals extends RentalRepository {
  @override
  Future<List<RentalReservation>> reservations() async => [
        RentalReservation(
          id: 11,
          branchId: 3,
          customerId: 7,
          customerName: 'Maya Fernando',
          assetName: 'Silk saree',
          status: 'Returned',
          isOverdue: false,
          chargePerUse: 25,
          isBillable: true,
          conditionDiscrepancy: false,
        ),
        RentalReservation(
          id: 12,
          branchId: 9,
          customerId: 8,
          customerName: 'Other',
          assetName: 'Other asset',
          status: 'Returned',
          isOverdue: false,
          chargePerUse: 10,
          isBillable: true,
          conditionDiscrepancy: false,
        ),
      ];
}
