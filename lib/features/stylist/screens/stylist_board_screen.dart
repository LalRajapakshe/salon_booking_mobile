import 'package:flutter/material.dart';

import '../../appointments/data/appointment_repository.dart';
import '../../appointments/models/appointment.dart';

/// Assigned work for the signed-in stylist. Progress stays with the existing permission.
class StylistBoardScreen extends StatefulWidget {
  const StylistBoardScreen({super.key, this.repository});

  final AppointmentRepository? repository;

  @override
  State<StylistBoardScreen> createState() => _StylistBoardScreenState();
}

class _StylistBoardScreenState extends State<StylistBoardScreen> {
  late final AppointmentRepository _repository = widget.repository ?? AppointmentRepository();
  List<Appointment> _appointments = [];
  String? _error;
  bool _loading = true;

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
      final rows = await _repository.list();
      if (!mounted) return;
      setState(() {
        _appointments = rows;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My work'),
        actions: [
          IconButton(tooltip: 'Refresh', onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!),
                      TextButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _appointments.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [ListTile(title: Text('No assigned appointments.'))],
                        )
                      : ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            for (final appointment in _appointments)
                              for (final line in appointment.appointmentServices)
                                ListTile(
                                  title: Text(line.serviceName ?? 'Service'),
                                  subtitle: Text(
                                    '${appointment.customerName ?? 'Customer'} · ${appointment.appointmentDate.toIso8601String().split('T').first}'
                                    ' · ${appointment.status.name} · ${line.lineStatus}'
                                    '${line.startTime == null ? '' : ' · ${line.startTime}'}',
                                  ),
                                ),
                          ],
                        ),
                ),
    );
  }
}
