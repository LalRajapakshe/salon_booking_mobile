import 'package:flutter/material.dart';

import '../../../core/api/api_exception.dart';
import '../../../shared/widgets/app_dropdown.dart';
import '../../../shared/widgets/app_primary_button.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../employees/data/employee_repository.dart';
import '../../employees/models/employee_record.dart';
import '../data/staff_schedule_repository.dart';
import '../models/staff_schedule_record.dart';

Future<void> showWorkingHoursDialog({
  required BuildContext context,
  required DateTime date,
  EmployeeRepository? employees,
  StaffScheduleRepository? schedules,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return WorkingHoursDialog(
        date: date,
        employees: employees,
        schedules: schedules,
      );
    },
  );
}

class WorkingHoursDialog extends StatefulWidget {
  final DateTime date;
  final EmployeeRepository? employees;
  final StaffScheduleRepository? schedules;

  const WorkingHoursDialog({
    super.key,
    required this.date,
    this.employees,
    this.schedules,
  });

  @override
  State<WorkingHoursDialog> createState() => _WorkingHoursDialogState();
}

class _WorkingHoursDialogState extends State<WorkingHoursDialog> {
  late final EmployeeRepository _employees;
  late final StaffScheduleRepository _schedules;
  List<EmployeeRecord> _employeeOptions = const [];
  List<StaffScheduleRecord> _saved = const [];
  int? _employeeId;
  late int _dayOfWeek;
  TimeOfDay _start = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 17, minute: 0);
  bool _loading = false;
  bool _saving = false;
  String? _loadError;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _employees = widget.employees ?? EmployeeRepository();
    _schedules = widget.schedules ?? StaffScheduleRepository();
    _dayOfWeek = staffScheduleDay(widget.date);
    if (_schedules.isApiBacked) {
      _loading = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _load();
      });
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final employees = await _employees.list();
      final saved = await _schedules.list();
      if (!mounted) return;
      setState(() {
        _employeeOptions = employees;
        _saved = saved;
        if (_employeeId == null || !employees.any((item) => item.id == _employeeId)) {
          _employeeId = null;
        }
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error.message;
        _loading = false;
      });
    }
  }

  Future<void> _pickTime({required bool start}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: start ? _start : _end,
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (start) {
        _start = picked;
      } else {
        _end = picked;
      }
    });
  }

  Future<void> _save() async {
    final employeeId = _employeeId;
    if (employeeId == null) {
      setState(() => _saveError = 'Choose an employee.');
      return;
    }
    final startMinute = _start.hour * 60 + _start.minute;
    final endMinute = _end.hour * 60 + _end.minute;
    if (endMinute <= startMinute) {
      setState(() => _saveError = 'End time must be after start time.');
      return;
    }

    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      await _schedules.createWorking(
        employeeId: employeeId,
        dayOfWeek: _dayOfWeek,
        startTime: _clock(_start),
        endTime: _clock(_end),
      );
      if (!mounted) return;
      final name = _employeeName(employeeId);
      AppSnackBar.success(
        context,
        '${staffScheduleDayNames[_dayOfWeek]} hours were saved for $name.',
      );
      setState(() => _saving = false);
      await _load();
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveError = error.message;
      });
    }
  }

  String _employeeName(int id) {
    for (final employee in _employeeOptions) {
      if (employee.id == id) return employee.fullName;
    }
    return 'Employee $id';
  }

  String _clock(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute:00';
  }

  String _label(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 640),
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
                      'Working hours',
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
              const Text(
                'These hours repeat every week for the chosen day.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Flexible(child: _body()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body() {
    if (!_schedules.isApiBacked) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text('Sign in to save working hours.'),
      );
    }
    if (_loading && _employeeOptions.isEmpty && _saved.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_loadError != null && _employeeOptions.isEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_loadError!, style: const TextStyle(color: Color(0xFFC62828))),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: _load, child: const Text('Retry')),
        ],
      );
    }
    if (_employeeOptions.isEmpty) {
      return const Text('Save an employee before setting working hours.');
    }

    final saved = _saved.where((item) => item.employeeId == _employeeId).toList();
    return ListView(
      shrinkWrap: true,
      children: [
        AppDropdown<int>(
          labelText: 'Employee',
          value: _employeeId,
          items: [
            for (final employee in _employeeOptions)
              DropdownMenuItem(
                value: employee.id,
                child: Text('${employee.fullName} · ${employee.employeeCode}'),
              ),
          ],
          onChanged: _saving ? null : (value) => setState(() => _employeeId = value),
        ),
        const SizedBox(height: 12),
        AppDropdown<int>(
          labelText: 'Day',
          value: _dayOfWeek,
          items: [
            for (var day = 0; day < staffScheduleDayNames.length; day++)
              DropdownMenuItem(value: day, child: Text(staffScheduleDayNames[day])),
          ],
          onChanged: _saving
              ? null
              : (value) {
                  if (value != null) setState(() => _dayOfWeek = value);
                },
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            OutlinedButton(
              onPressed: _saving ? null : () => _pickTime(start: true),
              child: Text('Start ${_label(_start)}'),
            ),
            OutlinedButton(
              onPressed: _saving ? null : () => _pickTime(start: false),
              child: Text('End ${_label(_end)}'),
            ),
          ],
        ),
        if (_saveError != null) ...[
          const SizedBox(height: 12),
          Text(_saveError!, style: const TextStyle(color: Color(0xFFC62828))),
        ],
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: AppPrimaryButton(
            text: 'Save',
            width: 160,
            isLoading: _saving,
            onPressed: _saving ? null : _save,
          ),
        ),
        const SizedBox(height: 20),
        const Text('Saved hours', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        if (_employeeId == null)
          const Text('Choose an employee to see saved hours.', style: TextStyle(color: Colors.grey))
        else if (saved.isEmpty)
          const Text('No hours saved for this employee.', style: TextStyle(color: Colors.grey))
        else
          for (final item in saved)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '${staffScheduleDayNames[item.dayOfWeek]} · ${item.segmentType} · ${item.clockRange}',
              ),
            ),
      ],
    );
  }
}
