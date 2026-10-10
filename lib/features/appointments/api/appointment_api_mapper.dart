import 'package:flutter/material.dart';

import '../../../core/api/api_exception.dart';
import '../models/appointment.dart';
import '../models/appointment_service_line.dart';
import '../models/appointment_status.dart';

class AppointmentApiMapper {
  const AppointmentApiMapper._();

  static List<Appointment> page(Map<String, dynamic> json) {
    final items = json['items'];
    if (items is! List) return const [];
    return [
      for (final item in items)
        if (item is Map<String, dynamic>) appointment(item),
    ];
  }

  static int totalPages(Map<String, dynamic> json) {
    final value = json['totalPages'];
    if (value is num && value > 0) return value.toInt();
    return 1;
  }

  static Appointment appointment(Map<String, dynamic> json) {
    final id = _int(json['appointmentId']);
    final lines = _lines(json['services'], id);
    final openLines = lines.where((line) => !line.isCancelled && line.startTime != null && line.endTime != null);
    final scheduled = openLines.toList();
    final employeeIds = scheduled.map((line) => line.employeeId).whereType<int>().toSet();

    DateTime? earliest;
    DateTime? latest;
    for (final line in scheduled) {
      final start = line.startTime!;
      final end = line.endTime!;
      if (earliest == null || start.isBefore(earliest)) earliest = start;
      if (latest == null || end.isAfter(latest)) latest = end;
    }

    return Appointment(
      appointmentId: id,
      branchId: _int(json['branchId']),
      customerId: _int(json['customerId']),
      appointmentDate: DateTime.parse(json['appointmentDate'] as String),
      startTime: _time(earliest),
      endTime: _time(latest),
      employeeId: employeeIds.length == 1 ? employeeIds.first : 0,
      employeeName: employeeIds.length > 1 ? 'Multiple' : null,
      status: AppointmentStatus.fromApi(json['status'] as String? ?? ''),
      notes: json['notes'] as String?,
      schedulingState: json['schedulingState'] as String?,
      hasScheduledTime: scheduled.isNotEmpty,
      appointmentServices: lines,
    );
  }

  static AppointmentServiceLine serviceLine(Map<String, dynamic> json) {
    final lines = _lines([json], _int(json['appointmentId']));
    if (lines.length != 1 || lines.single.appointmentServiceId <= 0) {
      throw const ApiException('The server returned an unexpected response.');
    }
    return lines.single;
  }

  static List<AppointmentServiceLine> _lines(Object? raw, int appointmentId) {
    if (raw is! List) return const [];
    final lines = <AppointmentServiceLine>[
      for (final item in raw)
        if (item is Map<String, dynamic>)
          AppointmentServiceLine(
            appointmentServiceId: _int(item['appointmentServiceId']),
            appointmentId: _int(item['appointmentId'], fallback: appointmentId),
            serviceId: _int(item['serviceId']),
            employeeId: item['employeeId'] == null ? null : _int(item['employeeId']),
            startTime: _date(item['startTime']),
            endTime: _date(item['endTime']),
            durationMinutes: item['durationMinutes'] == null ? null : _int(item['durationMinutes']),
            unitPrice: item['unitPrice'] == null ? null : (item['unitPrice'] as num).toDouble(),
            sequence: item['sequence'] == null ? null : _int(item['sequence']),
            notes: item['notes'] as String?,
            isCancelled: item['isCancelled'] == true,
            isFullyScheduled: item['isFullyScheduled'] == true,
            rowVersion: item['rowVersion'] as String?,
          ),
    ];
    lines.sort((a, b) => (a.sequence ?? 0).compareTo(b.sequence ?? 0));
    return lines;
  }

  static int _int(Object? value, {int fallback = 0}) {
    if (value is num) return value.toInt();
    return fallback;
  }

  static DateTime? _date(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  static TimeOfDay _time(DateTime? value) {
    if (value == null) return const TimeOfDay(hour: 0, minute: 0);
    return TimeOfDay(hour: value.hour, minute: value.minute);
  }
}
