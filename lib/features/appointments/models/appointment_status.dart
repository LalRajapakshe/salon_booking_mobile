/// List and form labels. [fromApi] reads the backend status name.
/// [scheduled] remains for the local catalog used before sign-in.
enum AppointmentStatus {
  scheduled,
  pending,
  confirmed,
  checkedIn,
  inProgress,
  completed,
  cancelled,
  noShow;

  String get label => switch (this) {
        AppointmentStatus.scheduled => 'Scheduled',
        AppointmentStatus.pending => 'Pending',
        AppointmentStatus.confirmed => 'Confirmed',
        AppointmentStatus.checkedIn => 'Checked in',
        AppointmentStatus.inProgress => 'In progress',
        AppointmentStatus.completed => 'Completed',
        AppointmentStatus.cancelled => 'Cancelled',
        AppointmentStatus.noShow => 'No show',
      };

  /// Backend status name. [scheduled] is local-only and is omitted on create.
  String? get apiValue => switch (this) {
        AppointmentStatus.scheduled => null,
        AppointmentStatus.pending => 'Pending',
        AppointmentStatus.confirmed => 'Confirmed',
        AppointmentStatus.checkedIn => 'CheckedIn',
        AppointmentStatus.inProgress => 'InProgress',
        AppointmentStatus.completed => 'Completed',
        AppointmentStatus.cancelled => 'Cancelled',
        AppointmentStatus.noShow => 'NoShow',
      };

  static AppointmentStatus fromApi(String value) {
    return switch (value.toLowerCase()) {
      'pending' => AppointmentStatus.pending,
      'confirmed' => AppointmentStatus.confirmed,
      'checkedin' => AppointmentStatus.checkedIn,
      'inprogress' => AppointmentStatus.inProgress,
      'completed' => AppointmentStatus.completed,
      'cancelled' => AppointmentStatus.cancelled,
      'noshow' => AppointmentStatus.noShow,
      _ => AppointmentStatus.scheduled,
    };
  }

  static AppointmentStatus? fromLabel(String label) {
    for (final status in AppointmentStatus.values) {
      if (status.label == label) return status;
    }
    return null;
  }
}
