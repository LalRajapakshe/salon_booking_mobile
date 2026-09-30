/// Lookup records taken from the existing Branch, Customer, Employee,
/// and Service entities. Only the fields this screen displays are kept.
class BranchLookup {
  final int branchId;
  final String branchCode;
  final String branchName;

  const BranchLookup({
    required this.branchId,
    required this.branchCode,
    required this.branchName,
  });

  String get label => '$branchName ($branchCode)';
}

class CustomerLookup {
  final int customerId;
  final String customerCode;
  final String firstName;
  final String lastName;
  final String mobileNo;
  final int branchId;

  const CustomerLookup({
    required this.customerId,
    required this.customerCode,
    required this.firstName,
    required this.lastName,
    required this.mobileNo,
    required this.branchId,
  });

  String get fullName => '$firstName $lastName';

  String get label => '$fullName ($customerCode)';
}

class EmployeeLookup {
  final int employeeId;
  final String employeeCode;
  final String firstName;
  final String lastName;
  final String? designation;
  final int branchId;

  const EmployeeLookup({
    required this.employeeId,
    required this.employeeCode,
    required this.firstName,
    required this.lastName,
    this.designation,
    required this.branchId,
  });

  String get fullName => '$firstName $lastName';

  String get label {
    final role = designation;
    if (role == null || role.isEmpty) return '$fullName ($employeeCode)';
    return '$fullName · $role';
  }
}

class ServiceLookup {
  final int serviceId;
  final String serviceCode;
  final String serviceName;
  final int durationMinutes;
  final double price;
  final int branchId;

  const ServiceLookup({
    required this.serviceId,
    required this.serviceCode,
    required this.serviceName,
    required this.durationMinutes,
    required this.price,
    required this.branchId,
  });
}
