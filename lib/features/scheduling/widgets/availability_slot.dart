import 'package:flutter/material.dart';

import '../../../core/api/api_exception.dart';
import '../../../shared/widgets/app_primary_button.dart';
import '../../../shared/widgets/app_secondary_button.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../api/vacant_slot_assignments.dart';
import '../models/scheduling_models.dart';

Future<void> showOpenSlotDialog({
  required BuildContext context,
  required SchedulingStaff staff,
  required DateTime date,
  required int startMinute,
  Future<List<VacantSlotAssignment>> Function()? loadAssignments,
  Future<void> Function(VacantSlotAssignment assignment)? onAssign,
}) {
  final endMinute = startMinute + scheduleSlotMinutes;
  final range = formatScheduleRange(startMinute, endMinute);

  if (loadAssignments != null && onAssign != null) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return _PendingAssignDialog(
          staff: staff,
          dateLabel: formatScheduleDate(date),
          range: range,
          loadAssignments: loadAssignments,
          onAssign: onAssign,
        );
      },
    );
  }

  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Open time slot',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  staff.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(staff.role, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 12),
                Text(formatScheduleDate(date)),
                const SizedBox(height: 4),
                Text(
                  range,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This time is open for a booking.',
                  style: TextStyle(color: Color(0xFF616161)),
                ),
                const SizedBox(height: 20),
                AppSecondaryButton(
                  text: 'Close',
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
                const SizedBox(height: 10),
                AppPrimaryButton(
                  text: 'Use this slot',
                  icon: Icons.add,
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    AppSnackBar.success(
                      context,
                      '$range noted for ${staff.name}.',
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _PendingAssignDialog extends StatefulWidget {
  final SchedulingStaff staff;
  final String dateLabel;
  final String range;
  final Future<List<VacantSlotAssignment>> Function() loadAssignments;
  final Future<void> Function(VacantSlotAssignment assignment) onAssign;

  const _PendingAssignDialog({
    required this.staff,
    required this.dateLabel,
    required this.range,
    required this.loadAssignments,
    required this.onAssign,
  });

  @override
  State<_PendingAssignDialog> createState() => _PendingAssignDialogState();
}

class _PendingAssignDialogState extends State<_PendingAssignDialog> {
  List<VacantSlotAssignment> _assignments = const [];
  VacantSlotAssignment? _selected;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final assignments = await widget.loadAssignments();
      if (!mounted) return;
      setState(() {
        _assignments = assignments;
        _selected = null;
        _loading = false;
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
        _error = 'Pending appointments could not be loaded.';
      });
    }
  }

  Future<void> _assign() async {
    final selected = _selected;
    if (selected == null || _saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onAssign(selected);
      if (!mounted) return;
      Navigator.of(context).pop();
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'The appointment could not be assigned.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  const Expanded(
                    child: Text(
                      'Open time slot',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: _saving ? null : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.staff.name,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              if (widget.staff.role.isNotEmpty)
                Text(widget.staff.role, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 12),
              Text(widget.dateLabel),
              const SizedBox(height: 4),
              Text(
                widget.range,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Flexible(child: _body()),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Color(0xFFC62828))),
              ],
              const SizedBox(height: 16),
              AppSecondaryButton(
                text: 'Close',
                onPressed: _saving ? null : () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: 10),
              AppPrimaryButton(
                text: 'Assign',
                icon: Icons.event_available_outlined,
                isLoading: _saving,
                onPressed: _selected == null || _loading ? null : _assign,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_assignments.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'No pending appointment fits this employee at this time.',
          style: TextStyle(color: Color(0xFF616161)),
        ),
      );
    }
    return ListView(
      shrinkWrap: true,
      children: [
        for (final assignment in _assignments)
          Padding(
            padding: const EdgeInsets.only(bottom: 8, right: 8),
            child: _choice(assignment),
          ),
      ],
    );
  }

  Widget _choice(VacantSlotAssignment assignment) {
    final selected = _selected?.appointmentServiceId == assignment.appointmentServiceId &&
        _selected?.appointmentId == assignment.appointmentId;
    final label = '${assignment.customerName} · ${assignment.serviceName} · '
        '${assignment.durationMinutes} min · '
        '${formatScheduleRange(assignment.startTime.hour * 60 + assignment.startTime.minute, assignment.endTime.hour * 60 + assignment.endTime.minute)}';
    void select() => setState(() => _selected = assignment);
    if (selected) {
      return FilledButton(
        onPressed: _saving ? null : select,
        child: Text(label),
      );
    }
    return OutlinedButton(
      onPressed: _saving ? null : select,
      child: Text(label),
    );
  }
}

class AvailabilitySlot extends StatelessWidget {
  final String tooltip;
  final VoidCallback onTap;

  const AvailabilitySlot({
    super.key,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Material(
          color: const Color(0xFFF4FAF6),
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onTap,
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFC8E6C9)),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, size: 16, color: Color(0xFF2E7D32)),
                  SizedBox(height: 2),
                  Text(
                    'Available',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Color(0xFF2E7D32),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
