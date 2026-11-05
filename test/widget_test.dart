import 'package:flutter_test/flutter_test.dart';
import 'package:salon_booking_mobile/features/branches/models/branch_record.dart';

void main() {
  test('a branch stays hidden from customers until it is published', () {
    const branch = BranchRecord(
      id: 1,
      tenantId: 1,
      branchCode: 'BRN-1',
      branchName: 'Studio',
      isHeadOffice: false,
      isActive: true,
    );

    expect(branch.isCustomerVisible, isFalse);
    expect(branch.photoPath, isNull);
  });
}
