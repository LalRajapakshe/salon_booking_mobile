import 'package:flutter/material.dart';

import '../../../shared/utils/currency_formatter.dart';
import '../models/appointment_service_draft.dart';
import '../models/appointment_time.dart';
import '../models/employee_availability.dart';
import '../models/salon_lookups.dart';
import '../services/appointment_catalog.dart';

class ServiceLineAvailability {
  final bool loading;
  final bool loaded;
  final String? error;
  final List<EmployeeAvailability> options;

  const ServiceLineAvailability({
    this.loading = false,
    this.loaded = false,
    this.error,
    this.options = const [],
  });

  bool get hasSlots => options.any((employee) => employee.slots.isNotEmpty);
}

class SelectedServiceList extends StatelessWidget {
  final List<AppointmentServiceDraft> lines;
  final Map<int, ServiceLineAvailability> availability;
  final bool enabled;
  final ValueChanged<int> onRemove;
  final ValueChanged<int> onFindAvailability;
  final void Function(int serviceId, TimeOfDay time) onStartTime;
  final void Function(int serviceId, TimeOfDay time) onFinishTime;
  final void Function(int serviceId, EmployeeAvailability employee, AvailabilitySlot slot) onSelectSlot;
  final ValueChanged<int> onClearSchedule;
  final ServiceLookup Function(int serviceId)? serviceLookup;

  const SelectedServiceList({
    super.key,
    required this.lines,
    required this.availability,
    required this.enabled,
    required this.onRemove,
    required this.onFindAvailability,
    required this.onStartTime,
    required this.onFinishTime,
    required this.onSelectSlot,
    required this.onClearSchedule,
    this.serviceLookup,
  });

  @override
  Widget build(BuildContext context) {
    if (lines.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        for (final line in lines) ...[
          const SizedBox(height: 12),
          _ServiceCard(
            line: line,
            availability: availability[line.serviceId] ?? const ServiceLineAvailability(),
            enabled: enabled,
            onRemove: onRemove,
            onFindAvailability: onFindAvailability,
            onStartTime: onStartTime,
            onFinishTime: onFinishTime,
            onSelectSlot: onSelectSlot,
            onClearSchedule: onClearSchedule,
            serviceLookup: serviceLookup,
          ),
        ],
      ],
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final AppointmentServiceDraft line;
  final ServiceLineAvailability availability;
  final bool enabled;
  final ValueChanged<int> onRemove;
  final ValueChanged<int> onFindAvailability;
  final void Function(int serviceId, TimeOfDay time) onStartTime;
  final void Function(int serviceId, TimeOfDay time) onFinishTime;
  final void Function(int serviceId, EmployeeAvailability employee, AvailabilitySlot slot) onSelectSlot;
  final ValueChanged<int> onClearSchedule;
  final ServiceLookup Function(int serviceId)? serviceLookup;

  const _ServiceCard({
    required this.line,
    required this.availability,
    required this.enabled,
    required this.onRemove,
    required this.onFindAvailability,
    required this.onStartTime,
    required this.onFinishTime,
    required this.onSelectSlot,
    required this.onClearSchedule,
    this.serviceLookup,
  });

  @override
  Widget build(BuildContext context) {
    final service = serviceLookup?.call(line.serviceId) ?? AppointmentCatalog.service(line.serviceId);
    final price = CurrencyFormatter.formatWithSymbol(service.price);
    final schedule = _scheduleLabel();
    final preferred = _preferredLabel();

    return Material(
      color: const Color(0xffF7F8FC),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.serviceName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Duration: ${service.durationMinutes} min    Price: $price',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Remove ${service.serviceName}',
                  onPressed: enabled ? () => onRemove(service.serviceId) : null,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _timeButton(context, start: true)),
                const SizedBox(width: 8),
                Expanded(child: _timeButton(context, start: false)),
              ],
            ),
            const SizedBox(height: 4),
            if (preferred != null) ...[
              Text(preferred, style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 4),
            ],
            Text(schedule, style: const TextStyle(fontSize: 13)),
            if (line.hasSchedule)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: enabled ? () => onClearSchedule(line.serviceId) : null,
                  child: const Text('Clear time'),
                ),
              ),
            const SizedBox(height: 4),
            _availabilityBody(context),
          ],
        ),
      ),
    );
  }

  String? _preferredLabel() {
    final start = line.preferredStart;
    final end = line.preferredEnd;
    if (start == null && end == null) return null;
    final startLabel = start == null ? 'Preferred start' : formatAppointmentTime(start);
    final endLabel = end == null ? 'Preferred finish' : formatAppointmentTime(end);
    return 'Preferred $startLabel → $endLabel';
  }

  String _scheduleLabel() {
    final start = line.startTime;
    final end = line.endTime;
    if (line.hasSchedule) {
      final name = line.employeeName ?? 'Employee ${line.employeeId}';
      final saved = line.scheduleSaved ? ' · Scheduled' : '';
      return '$name   ${formatAppointmentTime(start!)} → ${formatAppointmentTime(end!)}$saved';
    }
    if (start != null || end != null) {
      final startLabel = start == null ? 'Start time' : formatAppointmentTime(start);
      final endLabel = end == null ? 'Finish time' : formatAppointmentTime(end);
      return '$startLabel → $endLabel';
    }
    return 'Unscheduled';
  }

  Widget _timeButton(BuildContext context, {required bool start}) {
    final value = start ? line.preferredStart : line.preferredEnd;
    final label = value == null
        ? (start ? 'Preferred start' : 'Preferred finish')
        : formatAppointmentTime(value);
    return OutlinedButton(
      onPressed: enabled
          ? () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: value ?? const TimeOfDay(hour: 9, minute: 0),
              );
              if (picked == null) return;
              if (start) {
                onStartTime(line.serviceId, picked);
              } else {
                onFinishTime(line.serviceId, picked);
              }
            }
          : null,
      child: Text(label),
    );
  }

  Widget _availabilityBody(BuildContext context) {
    if (availability.loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: enabled ? () => onFindAvailability(line.serviceId) : null,
            icon: const Icon(Icons.schedule),
            label: Text(availability.error == null ? 'Find Availability' : 'Retry'),
          ),
        ),
        if (availability.error != null) ...[
          const SizedBox(height: 8),
          Text(
            availability.error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 13),
          ),
        ],
        if (availability.loaded && availability.error == null && !availability.hasSlots) ...[
          const SizedBox(height: 8),
          const Text(
            'No available times for this service.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
        for (final employee in availability.options)
          if (employee.slots.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '${employee.employeeName} · ${employee.durationMinutes} min',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final slot in employee.slots)
                  _slotButton(employee, slot),
              ],
            ),
          ],
      ],
    );
  }

  Widget _slotButton(EmployeeAvailability employee, AvailabilitySlot slot) {
    final start = TimeOfDay.fromDateTime(slot.startTime);
    final end = TimeOfDay.fromDateTime(slot.endTime);
    final label = '${formatAppointmentTime(start)} → ${formatAppointmentTime(end)}';
    final selected = line.employeeId == employee.employeeId &&
        _sameTime(line.startTime, start) &&
        _sameTime(line.endTime, end);
    final onPressed = enabled ? () => onSelectSlot(line.serviceId, employee, slot) : null;

    if (selected) {
      return FilledButton(onPressed: onPressed, child: Text(label));
    }
    return OutlinedButton(onPressed: onPressed, child: Text(label));
  }

  bool _sameTime(TimeOfDay? left, TimeOfDay right) {
    return left != null && left.hour == right.hour && left.minute == right.minute;
  }
}
