class EmployeeCapabilityRecord {
  final int id;
  final int employeeId;
  final int serviceId;
  final bool isActive;

  const EmployeeCapabilityRecord({
    required this.id,
    required this.employeeId,
    required this.serviceId,
    required this.isActive,
  });
}
