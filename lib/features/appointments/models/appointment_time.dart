import 'package:flutter/material.dart';

int appointmentMinutes(TimeOfDay time) => time.hour * 60 + time.minute;

String formatAppointmentTime(TimeOfDay time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

/// Quarter-hour choices from 08:00 through 20:00.
List<TimeOfDay> appointmentTimeOptions() {
  return [
    for (var minutes = 8 * 60; minutes <= 20 * 60; minutes += 15)
      TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
  ];
}
