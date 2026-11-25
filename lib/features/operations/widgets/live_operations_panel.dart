import 'package:flutter/material.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/auth/auth_session.dart';
import '../data/operations_repository.dart';

class LiveOperationsPanel extends StatefulWidget {
  const LiveOperationsPanel({super.key, this.repository});

  final OperationsRepository? repository;

  @override
  State<LiveOperationsPanel> createState() => _LiveOperationsPanelState();
}

class _LiveOperationsPanelState extends State<LiveOperationsPanel> with WidgetsBindingObserver {
  late final OperationsRepository _repository = widget.repository ?? OperationsRepository();
  OperationsSummary? _summary;
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  Future<void> _load() async {
    if (!AuthSession.instance.isSignedIn) {
      setState(() {
        _summary = null;
        _error = null;
        _loading = false;
      });
      return;
    }
    setState(() => _loading = true);
    try {
      final summary = await _repository.dashboard();
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _error = null;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _summary = null;
        _error = error is ApiException ? error.message : 'Live operations could not be loaded.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!AuthSession.instance.isSignedIn) {
      return const Text('Sign in to see today\'s operations.');
    }
    if (_loading && _summary == null) {
      return const Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_error!),
          TextButton(onPressed: _load, child: const Text('Retry')),
        ],
      );
    }
    final summary = _summary;
    if (summary == null) return const SizedBox.shrink();
    final tiles = <(String, String)>[
      ('Today', '${summary.todayAppointments}'),
      ('Pending', '${summary.pending}'),
      ('Checked in', '${summary.checkedIn}'),
      ('In progress', '${summary.inProgress}'),
      ('Completed', '${summary.completed}'),
      ('Cancelled', '${summary.cancelled}'),
      ('No show', '${summary.noShow}'),
      ('Open lines', '${summary.openServiceLines}'),
      ('My lines', '${summary.myAssignedLines}'),
      if (summary.activeRentals != null) ('Issued rentals', '${summary.activeRentals}'),
      if (summary.overdueRentals != null) ('Overdue rentals', '${summary.overdueRentals}'),
      if (summary.unpaidBills != null) ('Unpaid bills', '${summary.unpaidBills}'),
      if (summary.outstandingAmount != null) ('Outstanding', summary.outstandingAmount!.toStringAsFixed(2)),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('Live · ${summary.scope}', style: const TextStyle(fontWeight: FontWeight.w600))),
            TextButton(onPressed: _load, child: const Text('Refresh')),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final tile in tiles)
              SizedBox(
                width: 150,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tile.$2, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        Text(tile.$1),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
