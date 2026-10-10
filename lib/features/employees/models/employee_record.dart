class EmployeeRecord {
  final int id;
  final String employeeCode;
  final String firstName;
  final String lastName;
  final String mobileNo;
  final String? email;
  final String? gender;
  final DateTime? dateOfBirth;
  final String? address;
  final DateTime? hireDate;
  final String? designation;
  final double salary;
  final bool isActive;
  final DateTime createdDate;
  final int branchId;

  const EmployeeRecord({
    required this.id,
    required this.employeeCode,
    required this.firstName,
    required this.lastName,
    required this.mobileNo,
    this.email,
    this.gender,
    this.dateOfBirth,
    this.address,
    this.hireDate,
    this.designation,
    required this.salary,
    required this.isActive,
    required this.createdDate,
    required this.branchId,
  });

  String get fullName => '$firstName $lastName'.trim();
}
