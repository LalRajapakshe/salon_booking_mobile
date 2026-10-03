/// One service line on an appointment.
///
/// The backend has no `AppointmentService` entity. This line keeps only
/// the identifiers for that relationship. Employee, start time, and end
/// time belong to the appointment, not to this line. Duration and price
/// are read from the existing `Service` entity when the row is shown.
class AppointmentServiceLine {
  final int appointmentServiceId;
  final int appointmentId;
  final int serviceId;

  const AppointmentServiceLine({
    required this.appointmentServiceId,
    required this.appointmentId,
    required this.serviceId,
  });
}
