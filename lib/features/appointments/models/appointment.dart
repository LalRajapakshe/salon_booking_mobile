import 'package:flutter/material.dart';

import 'appointment_service_line.dart';
import 'appointment_status.dart';

/// Screen appointment. Employee and times on this header are the list's
/// display span. The API stores those values on each service line.
class Appointment {
  final int appointmentId;
  final int branchId;
  final int customerId;
  final DateTime appointmentDate;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final int employeeId;
  final AppointmentStatus status;
  final List<AppointmentServiceLine> appointmentServices;
  final String? customerName;
  final String? employeeName;
  final String? notes;
  final String? schedulingState;
  final bool hasScheduledTime;

  /// A slot is allocated when any open service line has a start time.
  /// Header times on the local catalog are display-only and do not count.
  bool get slotAllocated {
    if (schedulingState == 'Scheduled' || schedulingState == 'PartiallyScheduled') {
      return true;
    }
    return appointmentServices.any(
      (line) => !line.isCancelled && (line.startTime != null || line.isFullyScheduled),
    );
  }

  /// Pending is the only status before the customer confirms.
  /// The local catalog uses [AppointmentStatus.scheduled] for the same open state.
  bool get customerConfirmed => switch (status) {
        AppointmentStatus.pending || AppointmentStatus.scheduled => false,
        _ => true,
      };

  /// Edit is open only before a time slot is allocated and before confirmation.
  bool get canEdit => !slotAllocated && !customerConfirmed;

  const Appointment({
    required this.appointmentId,
    required this.branchId,
    required this.customerId,
    required this.appointmentDate,
    required this.startTime,
    required this.endTime,
    required this.employeeId,
    required this.status,
    required this.appointmentServices,
    this.customerName,
    this.employeeName,
    this.notes,
    this.schedulingState,
    this.hasScheduledTime = true,
  });
}
