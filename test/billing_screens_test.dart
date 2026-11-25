import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salon_booking_mobile/core/api/api_exception.dart';
import 'package:salon_booking_mobile/core/auth/auth_session.dart';
import 'package:salon_booking_mobile/features/billing/data/billing_repository.dart';
import 'package:salon_booking_mobile/features/billing/models/billing_models.dart';
import 'package:salon_booking_mobile/features/billing/screens/bill_detail_screen.dart';
import 'package:salon_booking_mobile/features/billing/screens/products_screen.dart';
import 'package:salon_booking_mobile/features/billing/screens/tax_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(AuthSession.instance.clear);
  tearDown(AuthSession.instance.clear);

  testWidgets('tax screen shows 0% until an authorized user saves a rate', (tester) async {
    AuthSession.instance.save(
      accessToken: 'token',
      username: 'admin',
      branchId: 4,
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
      permissions: {'tax.read', 'tax.manage'},
    );
    final billing = _FakeBilling();
    await tester.pumpWidget(MaterialApp(home: TaxScreen(repository: billing)));
    await tester.pumpAndSettle();

    expect(find.textContaining('No tax is configured'), findsOneWidget);
    expect(find.textContaining('0.00%'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Percentage'), '150');
    await tester.tap(find.text('Save tax'));
    await tester.pump();
    expect(find.textContaining('0 to 100'), findsOneWidget);
    expect(billing.saves, 0);

    await tester.enterText(find.widgetWithText(TextFormField, 'Tax name'), 'VAT');
    await tester.enterText(find.widgetWithText(TextFormField, 'Percentage'), '8.50');
    await tester.tap(find.text('Save tax'));
    await tester.pumpAndSettle();

    expect(billing.saves, 1);
    expect(find.textContaining('Tax saved'), findsOneWidget);
    expect(find.textContaining('Current rate: VAT 8.50%'), findsOneWidget);
  });

  testWidgets('a receptionist can read tax and cannot change it', (tester) async {
    AuthSession.instance.save(
      accessToken: 'token',
      username: 'desk',
      branchId: 4,
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
      permissions: {'tax.read'},
    );
    final billing = _FakeBilling()
      ..current = const TaxSetting(branchId: 4, configured: true, name: 'VAT', ratePercent: 8);
    await tester.pumpWidget(MaterialApp(home: TaxScreen(repository: billing)));
    await tester.pumpAndSettle();

    expect(find.textContaining('Current rate: VAT 8.00%'), findsOneWidget);
    expect(find.text('Save tax'), findsNothing);
  });

  testWidgets('tax errors from the API stay on the screen', (tester) async {
    AuthSession.instance.save(
      accessToken: 'token',
      username: 'admin',
      branchId: 4,
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
      permissions: {'tax.manage'},
    );
    final billing = _FakeBilling()..loadError = 'Tax service unavailable';
    await tester.pumpWidget(MaterialApp(home: TaxScreen(repository: billing)));
    await tester.pumpAndSettle();

    expect(find.text('Tax service unavailable'), findsOneWidget);
  });

  testWidgets('the catalogue keeps inactive products and confirms a save', (tester) async {
    AuthSession.instance.save(
      accessToken: 'token',
      username: 'admin',
      branchId: 4,
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
      permissions: {'products.read', 'products.manage'},
    );
    final billing = _FakeBilling();
    await tester.pumpWidget(MaterialApp(home: ProductsScreen(repository: billing)));
    await tester.pumpAndSettle();

    expect(billing.includeInactive, isTrue);
    expect(find.textContaining('Inactive'), findsOneWidget);

    await tester.tap(find.text('Styling wax'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Product saved and marked inactive.'), findsOneWidget);
  });

  testWidgets('draft and finalized bills expose only the allowed actions', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    AuthSession.instance.save(
      accessToken: 'token',
      username: 'desk',
      branchId: 4,
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
      permissions: {'bills.read', 'bills.manage', 'payments.collect', 'products.read'},
    );
    final billing = _FakeBilling();
    await tester.pumpWidget(MaterialApp(home: BillDetailScreen(key: const ValueKey('draft'), billId: 9, repository: billing)));
    await tester.pumpAndSettle();

    expect(find.text('Finalize'), findsOneWidget);
    expect(find.text('Add product'), findsOneWidget);
    expect(find.text('Record payment'), findsNothing);

    billing.bill = _bill(status: 'Finalized', paymentStatus: 'PartiallyPaid', outstanding: 40, net: 60);
    await tester.pumpWidget(MaterialApp(home: BillDetailScreen(key: const ValueKey('final'), billId: 9, repository: billing)));
    await tester.pumpAndSettle();

    expect(find.text('Record payment'), findsOneWidget);
    expect(find.text('Record refund'), findsOneWidget);
    expect(find.textContaining('Void is available after'), findsOneWidget);
    expect(find.text('Finalize'), findsNothing);

    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') return null;
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    await tester.tap(find.byTooltip('Copy receipt'));
    await tester.pump();
    expect(find.text('Receipt copied.'), findsOneWidget);
  });
}

class _FakeBilling extends BillingRepository {
  TaxSetting current = const TaxSetting(branchId: 4, configured: false, name: 'Tax', ratePercent: 0);
  String? loadError;
  int saves = 0;
  bool includeInactive = false;
  SalonBill bill = _bill();

  @override
  Future<TaxSetting> getTax(int branchId) async {
    if (loadError != null) throw ApiException(loadError!);
    return current;
  }

  @override
  Future<TaxSetting> saveTax({
    required int branchId,
    required String name,
    required double ratePercent,
  }) async {
    saves++;
    current = TaxSetting(branchId: branchId, configured: true, name: name, ratePercent: ratePercent);
    return current;
  }

  @override
  Future<List<RetailProduct>> listProducts({String? search, bool includeInactive = false}) async {
    this.includeInactive = includeInactive;
    return [
      const RetailProduct(
        id: 3,
        branchId: 4,
        code: 'WAX',
        name: 'Styling wax',
        sellingPrice: 12,
        isActive: false,
        description: 'Matte finish',
      ),
    ];
  }

  @override
  Future<RetailProduct> saveProduct({
    int? id,
    required String code,
    required String name,
    required double sellingPrice,
    String? description,
    bool isActive = true,
  }) async {
    return RetailProduct(
      id: id ?? 3,
      branchId: 4,
      code: code,
      name: name,
      sellingPrice: sellingPrice,
      isActive: isActive,
      description: description,
    );
  }

  @override
  Future<SalonBill> getBill(int id) async => bill;
}

SalonBill _bill({
  String status = 'Draft',
  String paymentStatus = 'Unpaid',
  double outstanding = 80,
  double net = 0,
}) {
  return SalonBill(
    id: 9,
    branchId: 4,
    customerId: 2,
    customerName: 'Maya Fernando',
    status: status,
    paymentStatus: paymentStatus,
    billDate: DateTime.utc(2026, 11, 25),
    subtotal: 80,
    taxAmount: 0,
    total: 80,
    netCollected: net,
    outstanding: outstanding,
    rowVersion: 'rv',
    billNumber: status == 'Draft' ? null : 'BIL000001',
    lines: [
      const BillLine(
        id: 1,
        lineType: 'Service',
        description: 'Cut',
        quantity: 1,
        unitPrice: 80,
        taxAmount: 0,
        lineTotal: 80,
      ),
    ],
    payments: const [],
  );
}
