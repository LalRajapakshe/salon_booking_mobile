import 'package:flutter_test/flutter_test.dart';
import 'package:salon_booking_mobile/core/auth/auth_session.dart';
import 'package:salon_booking_mobile/core/auth/staff_access.dart';
import 'package:salon_booking_mobile/features/billing/models/billing_models.dart';

void main() {
  tearDown(AuthSession.instance.clear);

  test('a stylist cannot see billing and a cashier can', () {
    AuthSession.instance.save(
      accessToken: 'token',
      username: 'stylist',
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
      permissions: {'appointments.own.read'},
    );
    expect(StaffAccess.seesBills(AuthSession.instance), isFalse);

    AuthSession.instance.save(
      accessToken: 'token',
      username: 'desk',
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
      permissions: {'bills.read', 'bills.manage', 'payments.collect', 'products.read'},
    );
    expect(StaffAccess.seesBills(AuthSession.instance), isTrue);
    expect(StaffAccess.canManageBills(AuthSession.instance), isTrue);
    expect(StaffAccess.canCollectPayments(AuthSession.instance), isTrue);
    expect(StaffAccess.seesProducts(AuthSession.instance), isTrue);
    expect(StaffAccess.canManageProducts(AuthSession.instance), isFalse);
    expect(StaffAccess.seesTax(AuthSession.instance), isFalse);
    expect(StaffAccess.canManageTax(AuthSession.instance), isFalse);

    AuthSession.instance.save(
      accessToken: 'token',
      username: 'admin',
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
      permissions: {'tax.read', 'tax.manage', 'products.manage'},
    );
    expect(StaffAccess.seesTax(AuthSession.instance), isTrue);
    expect(StaffAccess.canManageTax(AuthSession.instance), isTrue);
    expect(StaffAccess.canManageProducts(AuthSession.instance), isTrue);
  });

  test('receipt text keeps the finalized totals', () {
    final bill = SalonBill.fromJson({
      'billId': 4,
      'branchId': 1,
      'customerId': 2,
      'customerName': 'Maya Fernando',
      'billNumber': 'BIL000001',
      'status': 'Finalized',
      'paymentStatus': 'PartiallyPaid',
      'billDate': '2026-11-24T10:00:00Z',
      'subtotal': 100,
      'taxAmount': 10,
      'total': 110,
      'netCollected': 40,
      'outstanding': 70,
      'rowVersion': 'abc',
      'lines': [
        {
          'billLineId': 1,
          'lineType': 'Service',
          'description': 'Cut',
          'quantity': 1,
          'unitPrice': 100,
          'taxAmount': 10,
          'lineTotal': 110,
        }
      ],
      'payments': [],
    });

    expect(bill.receiptText, contains('BIL000001'));
    expect(bill.receiptText, contains('110.00'));
    expect(bill.receiptText, contains('70.00'));
    expect(bill.isFinalized, isTrue);
  });
}
