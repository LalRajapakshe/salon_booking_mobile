import 'package:flutter/material.dart';

import 'appointment_service_line.dart';
import 'appointment_status.dart';

/// Presentation appointment (the booking header).
///
/// `SalonBooking.Domain.Entities.Appointment` has no properties, DTOs,
/// or validators, and there is no `AppointmentService` entity. These
/// members are the screen fields, using the same id names as Branch,
/// Customer, Employee, and Service.
/// Employee, start time, and end time stay on the appointment. Each
/// [AppointmentServiceLine] only identifies a service on this booking.
/// `Staff` is an empty class, so the person on the appointment is
/// `employeeId`. Customer has `Remarks`; Appointment does not, so this
/// model has no notes field.
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
  });
}
