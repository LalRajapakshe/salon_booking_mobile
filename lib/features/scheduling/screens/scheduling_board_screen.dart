import 'package:flutter/material.dart';

import '../data/mock_scheduling_data.dart';
import '../models/scheduling_models.dart';
import '../widgets/appointment_schedule_panel.dart';
import '../widgets/availability_slot.dart';
import '../widgets/find_availability_dialog.dart';
import '../widgets/scheduling_legend.dart';
import '../widgets/scheduling_toolbar.dart';
import '../widgets/time_slot_grid.dart';

class SchedulingBoardScreen extends StatefulWidget {
  const SchedulingBoardScreen({super.key});

  @override
  State<SchedulingBoardScreen> createState() => _SchedulingBoardScreenState();
}

class _SchedulingBoardScreenState extends State<SchedulingBoardScreen> {
  DateTime _date = schedulingDemoDate;
  String _staffFilter = 'All';
  String _serviceFilter = 'All';
  String _statusFilter = 'All';

  List<SchedulingStaff> get _visibleStaff {
    if (_staffFilter == 'All') return schedulingStaff;
    return schedulingStaff
        .where((staff) => staff.name == _staffFilter)
        .toList();
  }

  List<SchedulingBlock> get _blocks => blocksForDate(_date);

  List<SchedulingBlock> get _visibleBlocks {
    final ids = _visibleStaff.map((staff) => staff.staffId).toSet();
    return _blocks.where((block) => ids.contains(block.staffId)).toList();
  }

  List<String> get _coverageNotes {
    final notes = <String>[];
    for (final staff in _visibleStaff) {
      final blocks = _visibleBlocks
          .where((block) => block.staffId == staff.staffId)
          .toList();
      final summary = summarizeStaffDay(blocks);
      if (summary.state == StaffDayState.leave ||
          summary.state == StaffDayState.offDuty) {
        notes.add('${staff.name} · ${summary.label}');
      }
    }
    return notes;
  }

  String get _summary {
    final ids = _visibleStaff.map((staff) => staff.staffId).toSet();
    final count = appointmentsForDate(_date).where((appointment) {
      return appointment.services.any(
        (segment) => ids.contains(segment.staffId),
      );
    }).length;
    final staffLabel = _visibleStaff.length == 1 ? 'staff member' : 'staff';
    final appointmentLabel = count == 1 ? 'appointment' : 'appointments';
    return '${_visibleStaff.length} $staffLabel · $count $appointmentLabel';
  }

  bool _isDimmed(SchedulingBlock block) {
    if (block.kind != ScheduleBlockKind.booked) return false;
    final serviceOff =
        _serviceFilter != 'All' && block.subtitle != _serviceFilter;
    final statusOff = _statusFilter != 'All' && block.status != _statusFilter;
    return serviceOff || statusOff;
  }

  void _shiftDay(int days) {
    setState(() {
      _date = DateTime(_date.year, _date.month, _date.day + days);
    });
  }

  @override
  Widget build(BuildContext context) {
    final conflict = firstConflict(_visibleBlocks);
    final padding = MediaQuery.sizeOf(context).width < 520 ? 16.0 : 24.0;

    return Scaffold(
      backgroundColor: const Color(0xffF4F6FA),
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Schedule',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.fromLTRB(padding, padding, padding, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SchedulingToolbar(
              date: _date,
              summary: _summary,
              staffFilter: _staffFilter,
              serviceFilter: _serviceFilter,
              statusFilter: _statusFilter,
              staffNames: schedulingStaff.map((staff) => staff.name).toList(),
              serviceNames: schedulingServiceNames(),
              statuses: schedulingStatuses,
              onPrevious: () => _shiftDay(-1),
              onNext: () => _shiftDay(1),
              onToday: () => setState(() => _date = schedulingDemoDate),
              onStaffChanged: (value) =>
                  setState(() => _staffFilter = value ?? 'All'),
              onServiceChanged: (value) =>
                  setState(() => _serviceFilter = value ?? 'All'),
              onStatusChanged: (value) =>
                  setState(() => _statusFilter = value ?? 'All'),
              onFindAvailability: () {
                showFindAvailabilityDialog(context: context, date: _date);
              },
            ),
            const SizedBox(height: 14),
            const SchedulingLegend(),
            if (conflict != null) ...[
              const SizedBox(height: 12),
              _ConflictNotice(block: conflict),
            ],
            if (_coverageNotes.isNotEmpty) ...[
              const SizedBox(height: 8),
              for (final note in _coverageNotes)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    note,
                    style: const TextStyle(
                      color: Color(0xFF616161),
                      fontSize: 13,
                    ),
                  ),
                ),
            ],
            const SizedBox(height: 12),
            Expanded(
              child: Card(
                elevation: 0,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TimeSlotGrid(
                  key: ValueKey(
                    '${_date.toIso8601String()}|$_staffFilter|$_serviceFilter|$_statusFilter',
                  ),
                  staff: _visibleStaff,
                  blocks: _visibleBlocks,
                  isDimmed: _isDimmed,
                  onAppointmentTap: (block) {
                    final appointment = appointmentByReference(
                      block.appointmentReference,
                    );
                    if (appointment == null) return;
                    showAppointmentSchedulePanel(
                      context: context,
                      appointment: appointment,
                    );
                  },
                  onAvailableTap: (staff, startMinute) {
                    showOpenSlotDialog(
                      context: context,
                      staff: staff,
                      date: _date,
                      startMinute: startMinute,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConflictNotice extends StatelessWidget {
  final SchedulingBlock block;

  const _ConflictNotice({required this.block});

  @override
  Widget build(BuildContext context) {
    final staff = staffById(block.staffId);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4F4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFCDD2)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFE53935),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Overlap · ${staff.name} · ${formatScheduleRange(block.startMinute, block.endMinute)}',
              style: const TextStyle(
                color: Color(0xFFC62828),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
