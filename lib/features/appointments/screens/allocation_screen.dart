import 'package:flutter/material.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/auth/auth_session.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../data/appointment_repository.dart';
import '../models/allocation_recommendation.dart';

class AllocationScreen extends StatefulWidget {
  const AllocationScreen({
    super.key,
    required this.repository,
    required this.appointmentId,
  });

  final AppointmentRepository repository;
  final int appointmentId;

  @override
  State<AllocationScreen> createState() => _AllocationScreenState();
}

class _AllocationScreenState extends State<AllocationScreen> {
  AllocationRecommendation? _advice;
  AllocationOption? _selected;
  String? _error;
  bool _loading = true;
  bool _saving = false;

  bool get _canManage => AuthSession.instance.can('appointments.manage');

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
      final advice = await widget.repository.recommendAllocation(widget.appointmentId);
      if (!mounted) return;
      setState(() {
        _advice = advice;
        _selected = advice.options.isEmpty ? null : advice.options.first;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.message;
      });
    }
  }

  Future<void> _confirm() async {
    final selected = _selected;
    final advice = _advice;
    if (!_canManage || selected == null || advice == null || _saving) return;
    final exact = advice.options.where((option) => option.exactMatch);
    if (!selected.exactMatch && exact.isNotEmpty) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Requested time is available'),
          content: const Text(
            'The customer\'s requested slot is still free. Confirm a different time only if you mean to change it.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep requested time')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Use the other time')),
          ],
        ),
      );
      if (proceed != true || !mounted) return;
    }

    setState(() => _saving = true);
    try {
      await widget.repository.applyAllocation(appointmentId: widget.appointmentId, option: selected);
      if (!mounted) return;
      AppSnackBar.success(context, 'The visit was placed on the schedule.');
      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppSnackBar.error(context, error.message);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final advice = _advice;
    return Scaffold(
      appBar: AppBar(title: Text('Appointment #${widget.appointmentId}')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : advice == null
                  ? const SizedBox.shrink()
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        const Text('Customer\'s request', style: TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        Text(advice.serviceNames.isEmpty ? 'No services' : advice.serviceNames.join(', ')),
                        Text('Requested date ${_day(advice.requestedDate)}'),
                        Text('Requested time ${advice.requestedTime == null ? 'Not set' : _clock(advice.requestedTime!)}'),
                        Text('Requested stylist ${advice.preferredStylistName ?? 'No preference'}'),
                        const SizedBox(height: 20),
                        const Text('Recommended allocations', style: TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        if (advice.options.isEmpty)
                          const Text('No allocation is available on the requested date or the nearby days.')
                        else
                          for (final option in advice.options)
                            RadioListTile<int>(
                              value: option.rank,
                              groupValue: _selected?.rank,
                              onChanged: (_) => setState(() => _selected = option),
                              title: Text(option.rank == 1 ? 'Best match' : 'Alternative ${option.rank}'),
                              subtitle: Text(
                                '${option.reason}\n${_optionSummary(option)}',
                              ),
                            ),
                        const SizedBox(height: 12),
                        if (_canManage && _selected != null)
                          FilledButton(
                            onPressed: _saving ? null : _confirm,
                            child: const Text('Confirm allocation'),
                          ),
                      ],
                    ),
    );
  }

  String _optionSummary(AllocationOption option) {
    final difference = option.exactMatch
        ? 'Same as requested'
        : option.dayDifference == 0
            ? '${option.minuteDifference} min from the requested time'
            : '${option.dayDifference} day(s) from the requested date';
    final lines = [
      for (final line in option.lines)
        '${line.serviceName} · ${line.stylistName} · ${_clock(line.startTime)}–${_clock(line.endTime)}',
    ];
    return '$difference\n${lines.join('\n')}';
  }

  String _day(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  String _clock(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '${hour.toString().padLeft(2, '0')}:$minute';
  }
}
