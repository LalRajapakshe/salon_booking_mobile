class AvailabilitySlot {
  final DateTime startTime;
  final DateTime endTime;

  const AvailabilitySlot({
    required this.startTime,
    required this.endTime,
  });
}

class EmployeeAvailability {
  final int employeeId;
  final String employeeName;
  final int serviceId;
  final int durationMinutes;
  final List<AvailabilitySlot> slots;

  const EmployeeAvailability({
    required this.employeeId,
    required this.employeeName,
    required this.serviceId,
    required this.durationMinutes,
    required this.slots,
  });
}
