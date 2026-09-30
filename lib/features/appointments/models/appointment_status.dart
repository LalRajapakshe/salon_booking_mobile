/// Presentation labels for the appointment list and form.
///
/// `SalonBooking.Domain` does not define an appointment status enum.
/// `Appointment.cs` is an empty class, so these names are not copied
/// from the backend.
enum AppointmentStatus {
  scheduled,
  confirmed,
  completed,
  cancelled;

  String get label => switch (this) {
        AppointmentStatus.scheduled => 'Scheduled',
        AppointmentStatus.confirmed => 'Confirmed',
        AppointmentStatus.completed => 'Completed',
        AppointmentStatus.cancelled => 'Cancelled',
      };

  static AppointmentStatus? fromLabel(String label) {
    for (final status in AppointmentStatus.values) {
      if (status.label == label) return status;
    }
    return null;
  }
}
