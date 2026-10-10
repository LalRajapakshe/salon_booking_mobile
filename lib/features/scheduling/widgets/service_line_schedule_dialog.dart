import 'package:flutter/material.dart';

import '../../../core/api/api_exception.dart';
import '../../../shared/widgets/app_primary_button.dart';
import '../../appointments/data/appointment_repository.dart';
import '../../appointments/data/availability_repository.dart';
import '../../appointments/models/employee_availability.dart';
import '../models/scheduling_models.dart';

class ServiceLineScheduleResult {
  final bool scheduled;
  final bool refreshed;

  const ServiceLineScheduleResult({
    this.scheduled = false,
    this.refreshed = false,
  });
}

/// Picks a server availability slot, then schedules that service line.
Future<ServiceLineScheduleResult> showServiceLineScheduleDialog({
  required BuildContext context,
  required SchedulingServiceSegment segment,
  required DateTime date,
  required AvailabilityRepository availability,
  required AppointmentRepository appointments,
  required bool changeEmployee,
}) {
  return showDialog<ServiceLineScheduleResult>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return ServiceLineScheduleDialog(
        segment: segment,
        date: date,
        availability: availability,
        appointments: appointments,
        changeEmployee: changeEmployee,
      );
    },
  ).then((value) => value ?? const ServiceLineScheduleResult());
}

class ServiceLineScheduleDialog extends StatefulWidget {
  final SchedulingServiceSegment segment;
  final DateTime date;
  final AvailabilityRepository availability;
  final AppointmentRepository appointments;
  final bool changeEmployee;

  const ServiceLineScheduleDialog({
    super.key,
    required this.segment,
    required this.date,
    required this.availability,
    required this.appointments,
    required this.changeEmployee,
  });

  @override
  State<ServiceLineScheduleDialog> createState() =>
      _ServiceLineScheduleDialogState();
}

class _ServiceLineScheduleDialogState extends State<ServiceLineScheduleDialog> {
  List<EmployeeAvailability> _options = const [];
  AvailabilitySlot? _selected;
  int? _employeeId;
  bool _loading = true;
  bool _saving = false;
  bool _refreshed = false;
  String? _error;
  late String _rowVersion;

  @override
  void initState() {
    super.initState();
    _rowVersion = widget.segment.rowVersion ?? '';
    _load();
  }

  Future<void> _load() async {
    await Future<void>.value();
    if (!mounted) return;
    final serviceId = widget.segment.serviceId;
    if (serviceId == null || serviceId <= 0) {
      setState(() {
        _loading = false;
        _error = 'This service line cannot be rescheduled.';
      });
      return;
    }

    try {
      final options = await widget.availability.find(
        serviceId: serviceId,
        date: widget.date,
        employeeId: widget.changeEmployee ? null : widget.segment.employeeId,
      );
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = null;
        _options = options.where((item) => item.slots.isNotEmpty).toList();
        _selected = null;
        _employeeId = null;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Availability could not be loaded.';
      });
    }
  }

  Future<void> _save() async {
    final segment = widget.segment;
    final slot = _selected;
    final employeeId = _employeeId;
    final appointmentId = segment.appointmentId;
    final lineId = segment.appointmentServiceId;
    if (slot == null ||
        employeeId == null ||
        appointmentId == null ||
        lineId == null ||
        _saving) {
      return;
    }
    if (_rowVersion.isEmpty) {
      setState(() {
        _error = 'This booking has no row version. Reload the schedule and try again.';
      });
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.appointments.scheduleLine(
        appointmentId: appointmentId,
        appointmentServiceId: lineId,
        employeeId: employeeId,
        startTime: slot.startTime,
        endTime: slot.endTime,
        rowVersion: _rowVersion,
      );
      if (!mounted) return;
      Navigator.of(context).pop(
        const ServiceLineScheduleResult(scheduled: true),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      if (_isConcurrency(error)) {
        await _refreshVersion(error);
        return;
      }
      setState(() {
        _saving = false;
        _error = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'The service could not be rescheduled.';
      });
    }
  }

  Future<void> _refreshVersion(ApiException error) async {
    final appointmentId = widget.segment.appointmentId;
    final lineId = widget.segment.appointmentServiceId;
    if (appointmentId == null || lineId == null) {
      setState(() {
        _saving = false;
        _error = error.message;
      });
      return;
    }

    try {
      final fresh = await widget.appointments.get(appointmentId);
      String? replacement;
      for (final line in fresh.appointmentServices) {
        if (line.appointmentServiceId == lineId &&
            line.rowVersion != null &&
            line.rowVersion!.isNotEmpty) {
          replacement = line.rowVersion;
        }
      }
      if (!mounted) return;
      setState(() {
        _saving = false;
        if (replacement != null) {
          _rowVersion = replacement;
          _refreshed = true;
        }
        _error = replacement == null
            ? '${error.message} The latest row version was not returned.'
            : 'This booking was changed. It has been refreshed. Try again.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = '${error.message} The latest booking could not be loaded.';
      });
    }
  }

  bool _isConcurrency(ApiException error) {
    return error.statusCode == 409 &&
        error.message.contains('changed by someone else');
  }

  void _close() {
    Navigator.of(context).pop(
      ServiceLineScheduleResult(refreshed: _refreshed),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.changeEmployee ? 'Change employee' : 'Reschedule';
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 560),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 12, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: _saving ? null : _close,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              Text(
                widget.segment.serviceName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                '${widget.segment.durationMinutes} min · ${widget.segment.staffName ?? widget.segment.staffId}',
                style: const TextStyle(color: Color(0xFF616161)),
              ),
              Text(
                formatScheduleRange(
                  widget.segment.startMinute,
                  widget.segment.endMinute,
                ),
                style: const TextStyle(color: Colors.grey),
              ),
              if (widget.segment.durationMismatch)
                Text(
                  'Duration ${widget.segment.durationMinutes} min does not match this time.',
                  style: const TextStyle(
                    color: Color(0xFFE53935),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              const SizedBox(height: 12),
              Flexible(child: _body()),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(color: Color(0xFFC62828)),
                ),
              ],
              const SizedBox(height: 12),
              AppPrimaryButton(
                text: 'Save',
                icon: Icons.save_outlined,
                isLoading: _saving,
                onPressed: _selected == null || _loading ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_options.isEmpty && _error != null) {
      return Center(
        child: OutlinedButton(
          onPressed: () {
            setState(() {
              _loading = true;
              _error = null;
            });
            _load();
          },
          child: const Text('Retry'),
        ),
      );
    }
    if (_options.isEmpty) {
      return const Center(
        child: Text('No available times for this service.'),
      );
    }

    return ListView(
      shrinkWrap: true,
      children: [
        for (final employee in _options)
          for (final slot in employee.slots)
            Padding(
              padding: const EdgeInsets.only(bottom: 8, right: 8),
              child: _slotButton(employee, slot),
            ),
      ],
    );
  }

  Widget _slotButton(EmployeeAvailability employee, AvailabilitySlot slot) {
    final selected = _employeeId == employee.employeeId &&
        _selected?.startTime == slot.startTime &&
        _selected?.endTime == slot.endTime;
    final label =
        '${employee.employeeName} · ${_clock(slot.startTime)} → ${_clock(slot.endTime)}';
    void select() {
      setState(() {
        _employeeId = employee.employeeId;
        _selected = slot;
      });
    }

    if (selected) {
      return FilledButton(onPressed: _saving ? null : select, child: Text(label));
    }
    return OutlinedButton(onPressed: _saving ? null : select, child: Text(label));
  }

  String _clock(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
