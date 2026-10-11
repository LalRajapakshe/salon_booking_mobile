/// One service line. Employee, start, end, duration, and price come from
/// the appointment-service API. [serviceName] is filled only when a lookup
/// already knows it.
class AppointmentServiceLine {
  final int appointmentServiceId;
  final int appointmentId;
  final int serviceId;
  final int? employeeId;
  final DateTime? startTime;
  final DateTime? endTime;
  final DateTime? preferredStartTime;
  final DateTime? preferredEndTime;
  final int? durationMinutes;
  final double? unitPrice;
  final int? sequence;
  final String? notes;
  final bool isCancelled;
  final bool isFullyScheduled;
  final String? rowVersion;
  final String? serviceName;

  const AppointmentServiceLine({
    required this.appointmentServiceId,
    required this.appointmentId,
    required this.serviceId,
    this.employeeId,
    this.startTime,
    this.endTime,
    this.preferredStartTime,
    this.preferredEndTime,
    this.durationMinutes,
    this.unitPrice,
    this.sequence,
    this.notes,
    this.isCancelled = false,
    this.isFullyScheduled = false,
    this.rowVersion,
    this.serviceName,
  });
}
