import 'package:flutter/material.dart';

import '../../appointments/models/appointment_status.dart';

/// One row on the reception desk. Names come from lookup APIs, not from the appointment payload.
class ReceptionVisit {
  final int appointmentId;
  final int customerId;
  final String customerName;
  final String mobile;
  final DateTime date;
  final TimeOfDay? start;
  final String services;
  final String employee;
  final AppointmentStatus status;
  final String? priceLabel;
  final String? notes;

  const ReceptionVisit({
    required this.appointmentId,
    required this.customerId,
    required this.customerName,
    required this.mobile,
    required this.date,
    required this.start,
    required this.services,
    required this.employee,
    required this.status,
    this.priceLabel,
    this.notes,
  });

  bool get canConfirm =>
      status == AppointmentStatus.pending || status == AppointmentStatus.scheduled;

  bool get canCheckIn =>
      status == AppointmentStatus.pending ||
      status == AppointmentStatus.confirmed ||
      status == AppointmentStatus.scheduled;

  String get timeLabel {
    final value = start;
    if (value == null) return 'Not placed';
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class ReceptionDay {
  final DateTime date;
  final bool sampleDay;
  final List<ReceptionVisit> visits;

  const ReceptionDay({
    required this.date,
    required this.visits,
    this.sampleDay = false,
  });
}
