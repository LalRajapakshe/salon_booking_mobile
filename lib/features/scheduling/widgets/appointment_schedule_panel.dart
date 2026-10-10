import 'package:flutter/material.dart';

import '../../../shared/widgets/app_primary_button.dart';
import '../../../shared/widgets/app_secondary_button.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../data/mock_scheduling_data.dart';
import '../models/scheduling_models.dart';

Future<void> showAppointmentSchedulePanel({
  required BuildContext context,
  required SchedulingAppointment appointment,
  SchedulingServiceSegment? focus,
  Future<void> Function(SchedulingServiceSegment segment)? onRescheduleLine,
  Future<void> Function(SchedulingServiceSegment segment)? onChangeEmployeeLine,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      void closeAndNotify(String message) {
        Navigator.of(dialogContext).pop();
        AppSnackBar.info(context, message);
      }

      void closeAndRun(
        Future<void> Function(SchedulingServiceSegment segment)? action,
        String notedMessage,
      ) {
        Navigator.of(dialogContext).pop();
        final line = focus;
        if (action != null && line?.appointmentServiceId != null) {
          action(line!);
          return;
        }
        AppSnackBar.info(context, notedMessage);
      }

      return AppointmentSchedulePanel(
        appointment: appointment,
        focus: focus,
        onClose: () => Navigator.of(dialogContext).pop(),
        onView: () =>
            closeAndNotify('Appointment ${appointment.reference} opened.'),
        onReschedule: () => closeAndRun(
          onRescheduleLine,
          'Reschedule noted for ${appointment.reference}.',
        ),
        onChangeEmployee: () => closeAndRun(
          onChangeEmployeeLine,
          'Employee change noted for ${appointment.reference}.',
        ),
      );
    },
  );
}

class AppointmentSchedulePanel extends StatelessWidget {
  final SchedulingAppointment appointment;
  final SchedulingServiceSegment? focus;
  final VoidCallback onClose;
  final VoidCallback onView;
  final VoidCallback onReschedule;
  final VoidCallback onChangeEmployee;

  const AppointmentSchedulePanel({
    super.key,
    required this.appointment,
    this.focus,
    required this.onClose,
    required this.onView,
    required this.onReschedule,
    required this.onChangeEmployee,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 12, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Appointment #${appointment.reference}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: onClose,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _field('Customer', appointment.customerName),
              const SizedBox(height: 14),
              const Text(
                'Services',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              for (final segment in appointment.services) ...[
                _serviceLine(segment),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 6),
              _field('Date', formatScheduleDate(appointment.date)),
              const SizedBox(height: 12),
              _field(
                'Time',
                formatScheduleRange(
                  appointment.startMinute,
                  appointment.endMinute,
                ),
              ),
              const SizedBox(height: 12),
              _field('Status', appointment.status),
              const SizedBox(height: 20),
              AppSecondaryButton(
                text: 'View Appointment',
                icon: Icons.visibility_outlined,
                onPressed: onView,
              ),
              const SizedBox(height: 10),
              AppSecondaryButton(
                text: 'Reschedule',
                icon: Icons.schedule,
                onPressed: onReschedule,
              ),
              const SizedBox(height: 10),
              AppPrimaryButton(
                text: 'Change Employee',
                icon: Icons.badge_outlined,
                onPressed: onChangeEmployee,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _serviceLine(SchedulingServiceSegment segment) {
    final staffName = segment.staffName ?? staffById(segment.staffId).name;
    final selected = focus?.appointmentServiceId != null &&
        focus!.appointmentServiceId == segment.appointmentServiceId;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            segment.serviceName,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            '${segment.durationMinutes} min · $staffName',
            style: const TextStyle(color: Color(0xFF616161), fontSize: 13),
          ),
          Text(
            formatScheduleRange(segment.startMinute, segment.endMinute),
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          if (segment.durationMismatch)
            Text(
              'Duration ${segment.durationMinutes} min does not match this time.',
              style: const TextStyle(
                color: Color(0xFFE53935),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          if (selected)
            const Text(
              'Reschedule and Change Employee apply to this line.',
              style: TextStyle(color: Color(0xFF5E548E), fontSize: 12),
            ),
        ],
      ),
    );
  }

  Widget _field(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
