import 'package:flutter/material.dart';

import '../../../core/api/api_exception.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../appointments/data/appointment_repository.dart';
import '../../appointments/data/availability_repository.dart';
import '../../appointments/models/appointment.dart';
import '../../appointments/models/appointment_service_line.dart';
import '../../appointments/models/appointment_status.dart';
import '../../appointments/models/employee_availability.dart' as availability;
import '../../customers/data/customer_repository.dart';
import '../../employees/data/employee_repository.dart';
import '../../services/data/service_repository.dart';
import '../api/scheduling_board_mapper.dart';
import '../api/vacant_slot_assignments.dart';
import '../data/mock_scheduling_data.dart';
import '../models/scheduling_models.dart';
import '../widgets/appointment_schedule_panel.dart';
import '../widgets/availability_slot.dart';
import '../widgets/find_availability_dialog.dart';
import '../widgets/scheduling_legend.dart';
import '../widgets/service_line_schedule_dialog.dart';
import '../widgets/scheduling_toolbar.dart';
import '../widgets/time_slot_grid.dart';
import '../widgets/working_hours_dialog.dart';

class SchedulingBoardScreen extends StatefulWidget {
  final AppointmentRepository? appointments;
  final AvailabilityRepository? availability;

  const SchedulingBoardScreen({
    super.key,
    this.appointments,
    this.availability,
  });

  @override
  State<SchedulingBoardScreen> createState() => _SchedulingBoardScreenState();
}

class _SchedulingBoardScreenState extends State<SchedulingBoardScreen> {
  DateTime _date = schedulingDemoDate;
  String _staffFilter = 'All';
  String _serviceFilter = 'All';
  String _statusFilter = 'All';
  bool _loading = false;
  String? _error;
  SchedulingBoardDay _loaded = const SchedulingBoardDay(
    staff: [],
    appointments: [],
  );
  List<Appointment> _dayAppointments = const [];
  Map<int, String> _customerNames = const {};
  Map<int, String> _serviceNamesById = const {};
  late final AppointmentRepository _repository;
  late final AvailabilityRepository _availability;
  late final EmployeeRepository _employees;
  late final CustomerRepository _customers;
  late final ServiceRepository _services;

  bool get _demo => !_repository.isApiBacked;

  /// Production loads employees, customers, and services. Tests that inject
  /// the appointment repository keep the appointment payload alone.
  bool get _useDirectory => widget.appointments == null && !_demo;

  List<SchedulingAppointment> get _appointments =>
      _demo ? appointmentsForDate(_date) : _loaded.appointments;

  List<SchedulingStaff> get _allStaff =>
      _demo ? schedulingStaff : _loaded.staff;

  List<SchedulingStaff> get _visibleStaff {
    if (_staffFilter == 'All') return _allStaff;
    return _allStaff.where((staff) => staff.name == _staffFilter).toList();
  }

  List<SchedulingBlock> get _blocks => _demo
      ? blocksForDate(_date)
      : [for (final appointment in _appointments) ...appointment.toBlocks()];

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

  List<String> get _serviceNames {
    if (_demo) return schedulingServiceNames();
    final names = <String>{
      for (final appointment in _appointments)
        for (final segment in appointment.services) segment.serviceName,
    };
    final sorted = names.toList()..sort();
    return sorted;
  }

  List<String> get _statuses {
    if (_demo) return schedulingStatuses;
    final names = _appointments.map((item) => item.status).toSet().toList()
      ..sort();
    return names;
  }

  String get _summary {
    if (!_demo && _loading) return 'Loading schedule';
    final ids = _visibleStaff.map((staff) => staff.staffId).toSet();
    final count = _appointments.where((appointment) {
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

  @override
  void initState() {
    super.initState();
    _repository = widget.appointments ?? AppointmentRepository();
    _availability = widget.availability ?? AvailabilityRepository();
    _employees = EmployeeRepository();
    _customers = CustomerRepository();
    _services = ServiceRepository();
    if (_repository.isApiBacked) {
      final now = DateTime.now();
      _date = DateTime(now.year, now.month, now.day);
      _loading = true;
      _load();
    }
  }

  void _shiftDay(int days) {
    setState(() {
      _date = DateTime(_date.year, _date.month, _date.day + days);
      if (!_demo) {
        _loading = true;
        _error = null;
      }
    });
    _load();
  }

  void _goToday() {
    final now = DateTime.now();
    setState(() {
      _date = _demo
          ? schedulingDemoDate
          : DateTime(now.year, now.month, now.day);
      if (!_demo) {
        _loading = true;
        _error = null;
      }
    });
    _load();
  }

  Future<void> _load() async {
    if (_demo) return;
    final date = _date;
    try {
      final appointments = await _repository.list(date: date);
      final directory = _useDirectory ? await _directory() : _BoardDirectory.empty;
      if (!mounted || date != _date) return;
      final day = SchedulingBoardMapper.map(
        appointments,
        date,
        roster: directory.roster,
        customerNames: directory.customerNames,
        serviceNames: directory.serviceNames,
      );
      setState(() {
        _loading = false;
        _error = null;
        _loaded = day;
        _dayAppointments = appointments;
        _customerNames = directory.customerNames;
        _serviceNamesById = directory.serviceNames;
        _alignFilters();
      });
    } catch (error) {
      if (!mounted || date != _date) return;
      setState(() {
        _loading = false;
        _error = error is ApiException
            ? error.message
            : 'The schedule could not be loaded.';
        _dayAppointments = const [];
      });
    }
  }

  Future<_BoardDirectory> _directory() async {
    final roster = <SchedulingStaff>[];
    final customerNames = <int, String>{};
    final serviceNames = <int, String>{};
    try {
      for (final employee in await _employees.list()) {
        roster.add(
          SchedulingStaff(
            staffId: '${employee.id}',
            name: employee.fullName,
            role: employee.designation ?? '',
          ),
        );
      }
    } on ApiException {
      // Appointment blocks can still name the employee by id.
    }
    try {
      for (final customer in await _customers.list()) {
        customerNames[customer.id] = customer.fullName;
      }
    } on ApiException {}
    try {
      for (final service in await _services.list()) {
        serviceNames[service.serviceId] = service.serviceName;
      }
    } on ApiException {}
    return _BoardDirectory(roster, customerNames, serviceNames);
  }

  void _retry() {
    setState(() {
      _loading = true;
      _error = null;
    });
    _load();
  }

  void _alignFilters() {
    if (_staffFilter != 'All' &&
        !_allStaff.any((staff) => staff.name == _staffFilter)) {
      _staffFilter = 'All';
    }
    if (_serviceFilter != 'All' && !_serviceNames.contains(_serviceFilter)) {
      _serviceFilter = 'All';
    }
    if (_statusFilter != 'All' && !_statuses.contains(_statusFilter)) {
      _statusFilter = 'All';
    }
  }

  SchedulingAppointment? _appointmentByReference(String? reference) {
    if (reference == null) return null;
    if (_demo) return appointmentByReference(reference);
    for (final appointment in _appointments) {
      if (appointment.reference == reference) return appointment;
    }
    return null;
  }

  SchedulingServiceSegment? _segmentFor(SchedulingBlock block) {
    final appointment = _appointmentByReference(block.appointmentReference);
    if (appointment == null) return null;
    for (final segment in appointment.services) {
      if (segment.staffId == block.staffId &&
          segment.startMinute == block.startMinute &&
          segment.endMinute == block.endMinute) {
        return segment;
      }
    }
    return null;
  }

  Future<void> _scheduleLine(
    SchedulingServiceSegment segment, {
    required bool changeEmployee,
  }) async {
    final result = await showServiceLineScheduleDialog(
      context: context,
      segment: segment,
      date: _date,
      availability: _availability,
      appointments: _repository,
      changeEmployee: changeEmployee,
    );
    if (!mounted) return;
    if (result.scheduled) {
      AppSnackBar.success(context, 'The service was rescheduled.');
    }
    if (result.scheduled || result.refreshed) await _load();
  }

  Future<List<VacantSlotAssignment>> _assignmentsFor(
    SchedulingStaff staff,
    int startMinute,
  ) async {
    final employeeId = int.tryParse(staff.staffId) ?? 0;
    if (employeeId <= 0) return const [];
    final serviceIds = <int>{
      for (final appointment in _dayAppointments)
        if (_canPlace(appointment.status))
          for (final line in appointment.appointmentServices)
            if (!line.isCancelled && !_isPlaced(line)) line.serviceId,
    }..remove(0);

    final slotsByService = <int, List<availability.AvailabilitySlot>>{};
    for (final serviceId in serviceIds) {
      final rows = await _availability.find(
        serviceId: serviceId,
        date: _date,
        employeeId: employeeId,
      );
      slotsByService[serviceId] = [
        for (final row in rows)
          if (row.employeeId == employeeId) ...row.slots,
      ];
    }
    return VacantSlotAssignments.match(
      appointments: _dayAppointments,
      employeeId: employeeId,
      date: _date,
      startMinute: startMinute,
      slotsByService: slotsByService,
      customerNames: _customerNames,
      serviceNames: _serviceNamesById,
    );
  }

  bool _canPlace(AppointmentStatus status) {
    return status != AppointmentStatus.cancelled &&
        status != AppointmentStatus.completed &&
        status != AppointmentStatus.noShow;
  }

  bool _isPlaced(AppointmentServiceLine line) {
    final employeeId = line.employeeId;
    return line.startTime != null &&
        line.endTime != null &&
        employeeId != null &&
        employeeId > 0;
  }

  Future<void> _assignVacant(SchedulingStaff staff, VacantSlotAssignment assignment) async {
    final employeeId = int.tryParse(staff.staffId) ?? 0;
    await _repository.scheduleLine(
      appointmentId: assignment.appointmentId,
      appointmentServiceId: assignment.appointmentServiceId,
      employeeId: employeeId,
      startTime: assignment.startTime,
      endTime: assignment.endTime,
      rowVersion: assignment.rowVersion,
    );
    if (!mounted) return;
    AppSnackBar.success(
      context,
      '${assignment.serviceName} was assigned to ${staff.name}.',
    );
    await _load();
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
        actions: [
          TextButton(
            onPressed: () => showWorkingHoursDialog(context: context, date: _date),
            child: const Text('Working hours'),
          ),
        ],
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
              staffNames: _allStaff.map((staff) => staff.name).toList(),
              serviceNames: _serviceNames,
              statuses: _statuses,
              onPrevious: () => _shiftDay(-1),
              onNext: () => _shiftDay(1),
              onToday: _goToday,
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
                child: _boardBody(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _boardBody() {
    if (!_demo && _loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!_demo && _error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: _retry, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    final unscheduled = _demo ? const <UnscheduledVisit>[] : _loaded.unscheduled;
    if (!_demo && _allStaff.isEmpty && unscheduled.isEmpty) {
      return const Center(
        child: Text('No scheduled services for this day.'),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (unscheduled.isNotEmpty) _unscheduledPanel(unscheduled),
        if (_allStaff.isNotEmpty)
          Expanded(
            child: TimeSlotGrid(
      key: ValueKey(
        '${_date.toIso8601String()}|$_staffFilter|$_serviceFilter|$_statusFilter',
      ),
      staff: _visibleStaff,
      blocks: _visibleBlocks,
      isDimmed: _isDimmed,
      onAppointmentTap: (block) {
        final appointment = _appointmentByReference(block.appointmentReference);
        if (appointment == null) return;
        final segment = _segmentFor(block);
        showAppointmentSchedulePanel(
          context: context,
          appointment: appointment,
          focus: segment,
          onRescheduleLine: _demo
              ? null
              : (line) => _scheduleLine(line, changeEmployee: false),
          onChangeEmployeeLine: _demo
              ? null
              : (line) => _scheduleLine(line, changeEmployee: true),
        );
      },
      onAvailableTap: (staff, startMinute) {
        showOpenSlotDialog(
          context: context,
          staff: staff,
          date: _date,
          startMinute: startMinute,
          loadAssignments: _demo ? null : () => _assignmentsFor(staff, startMinute),
          onAssign: _demo ? null : (assignment) => _assignVacant(staff, assignment),
        );
      },
            ),
          ),
      ],
    );
  }

  Widget _unscheduledPanel(List<UnscheduledVisit> visits) {
    return Material(
      color: const Color(0xffF7F8FC),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Not placed on the board',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            for (final visit in visits)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${visit.customerName} · ${visit.servicesLabel} · ${visit.status}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BoardDirectory {
  final List<SchedulingStaff> roster;
  final Map<int, String> customerNames;
  final Map<int, String> serviceNames;

  const _BoardDirectory(this.roster, this.customerNames, this.serviceNames);

  static const empty = _BoardDirectory([], {}, {});
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
