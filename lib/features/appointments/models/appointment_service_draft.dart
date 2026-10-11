import 'package:flutter/material.dart';

/// Create-form state for one service. Stylist and times stay on the line.
/// They are not appointment header fields and are not sent until scheduling.
class AppointmentServiceDraft {
  final int serviceId;
  final int? employeeId;
  final String? employeeName;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final TimeOfDay? preferredStart;
  final TimeOfDay? preferredEnd;
  final int? appointmentServiceId;
  final String? rowVersion;
  final int? durationMinutes;
  final double? unitPrice;
  final bool scheduleSaved;

  const AppointmentServiceDraft({
    required this.serviceId,
    this.employeeId,
    this.employeeName,
    this.startTime,
    this.endTime,
    this.preferredStart,
    this.preferredEnd,
    this.appointmentServiceId,
    this.rowVersion,
    this.durationMinutes,
    this.unitPrice,
    this.scheduleSaved = false,
  });

  bool get hasSchedule => employeeId != null && startTime != null && endTime != null;

  AppointmentServiceDraft copyWith({
    Object? employeeId = _keep,
    Object? employeeName = _keep,
    Object? startTime = _keep,
    Object? endTime = _keep,
    Object? preferredStart = _keep,
    Object? preferredEnd = _keep,
    Object? appointmentServiceId = _keep,
    Object? rowVersion = _keep,
    Object? durationMinutes = _keep,
    Object? unitPrice = _keep,
    Object? scheduleSaved = _keep,
  }) {
    return AppointmentServiceDraft(
      serviceId: serviceId,
      employeeId: employeeId == _keep ? this.employeeId : employeeId as int?,
      employeeName: employeeName == _keep ? this.employeeName : employeeName as String?,
      startTime: startTime == _keep ? this.startTime : startTime as TimeOfDay?,
      endTime: endTime == _keep ? this.endTime : endTime as TimeOfDay?,
      preferredStart: preferredStart == _keep ? this.preferredStart : preferredStart as TimeOfDay?,
      preferredEnd: preferredEnd == _keep ? this.preferredEnd : preferredEnd as TimeOfDay?,
      appointmentServiceId: appointmentServiceId == _keep
          ? this.appointmentServiceId
          : appointmentServiceId as int?,
      rowVersion: rowVersion == _keep ? this.rowVersion : rowVersion as String?,
      durationMinutes: durationMinutes == _keep ? this.durationMinutes : durationMinutes as int?,
      unitPrice: unitPrice == _keep ? this.unitPrice : unitPrice as double?,
      scheduleSaved: scheduleSaved == _keep ? this.scheduleSaved : scheduleSaved as bool,
    );
  }
}

const Object _keep = Object();
