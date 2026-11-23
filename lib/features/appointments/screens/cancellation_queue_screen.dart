import 'package:flutter/material.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/auth/auth_session.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../data/appointment_repository.dart';
import '../models/appointment_status.dart';
import '../models/cancellation_notice.dart';
import 'allocation_screen.dart';

class CancellationQueueScreen extends StatefulWidget {
  const CancellationQueueScreen({super.key, required this.repository, this.branchId});

  final AppointmentRepository repository;
  final int? branchId;

  @override
  State<CancellationQueueScreen> createState() => _CancellationQueueScreenState();
}

class _CancellationQueueScreenState extends State<CancellationQueueScreen> {
  List<CancellationNotice> _items = const [];
  String? _error;
  bool _loading = true;
  bool _changed = false;

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
      final items = await widget.repository.listCancellationRequests(branchId: widget.branchId);
      if (!mounted) return;
      setState(() {
        _items = [
          for (final item in items)
            if (item.isPending && !(item.isPast && (item.isNewBooking || item.isAwaitingConfirmation))) item,
        ];
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

  Future<void> _confirm(CancellationNotice notice) async {
    if (!_canManage) return;
    try {
      await widget.repository.changeStatus(
        appointmentId: notice.appointmentId,
        status: AppointmentStatus.confirmed,
      );
      if (!mounted) return;
      _changed = true;
      AppSnackBar.success(context, 'Appointment confirmed.');
      await _load();
    } on ApiException catch (error) {
      if (!mounted) return;
      AppSnackBar.error(context, error.message);
      await _load();
    }
  }

  Future<void> _decide(CancellationNotice notice, {required bool approve}) async {
    if (!_canManage) return;
    try {
      if (approve) {
        await widget.repository.approveCancellation(appointmentId: notice.appointmentId);
      } else {
        await widget.repository.declineCancellation(appointmentId: notice.appointmentId);
      }
      if (!mounted) return;
      _changed = true;
      AppSnackBar.success(
        context,
        approve ? 'Cancellation approved.' : 'Cancellation request declined.',
      );
      await _load();
    } on ApiException catch (error) {
      if (!mounted) return;
      AppSnackBar.error(context, error.message);
      await _load();
    }
  }

  Future<void> _open(CancellationNotice notice) async {
    if (notice.isNewBooking) {
      final saved = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => AllocationScreen(
            repository: widget.repository,
            appointmentId: notice.appointmentId,
          ),
        ),
      );
      if (saved == true) {
        _changed = true;
        await _load();
      }
      return;
    }
    final when = notice.appointmentTime;
    final time = when == null
        ? 'Time not set'
        : '${when.hour.toString().padLeft(2, '0')}:${when.minute.toString().padLeft(2, '0')}';
    final requested = notice.requestedAt;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Appointment #${notice.appointmentId}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notice.notificationType),
            const SizedBox(height: 8),
            Text(notice.customerName),
            Text(notice.serviceName.isEmpty ? 'No services' : notice.serviceName),
            Text('${_date(notice.appointmentDate)} · $time'),
            Text(notice.branchName),
            Text(notice.requestState),
            if (requested != null) Text('Requested ${_date(requested)} ${_clock(requested)}'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Close')),
          if (notice.isAwaitingConfirmation && _canManage && !notice.isPast)
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _confirm(notice);
              },
              child: const Text('Confirm Appointment'),
            ),
          if (notice.isCancellation && _canManage) ...[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _decide(notice, approve: false);
              },
              child: const Text('Decline cancellation'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _decide(notice, approve: true);
              },
              child: const Text('Approve cancellation'),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pop(_changed);
      },
      child: Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      FilledButton(onPressed: _load, child: const Text('Try again')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _items.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 80),
                            Center(child: Text('No notifications are waiting.')),
                          ],
                        )
                      : ListView(
                          children: [
                            _countBar(),
                            for (final notice in _items) _tile(notice),
                          ],
                        ),
                ),
    ),
    );
  }

  Widget _countBar() {
    final bookings = _items.where((item) => item.isNewBooking).length;
    final waiting = _items.where((item) => item.isAwaitingConfirmation).length;
    final cancellations = _items.where((item) => item.isCancellation).length;
    String label(int count, String one, String many) => '$count ${count == 1 ? one : many}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        '${label(bookings, 'new booking', 'new bookings')} · ${label(waiting, 'awaiting confirmation', 'awaiting confirmation')} · ${label(cancellations, 'cancellation request', 'cancellation requests')}',
      ),
    );
  }

  Widget _tile(CancellationNotice notice) {
    final booking = notice.isNewBooking;
    final waiting = notice.isAwaitingConfirmation;
    final color = booking
        ? const Color(0xFF1565C0)
        : waiting
            ? const Color(0xFFF9A825)
            : const Color(0xFFC62828);
    final background = booking
        ? const Color(0xFFE3F2FD)
        : waiting
            ? const Color(0xFFFFF8E1)
            : const Color(0xFFFFEBEE);
    final chip = booking
        ? 'New Booking'
        : waiting
            ? 'Awaiting Confirmation'
            : 'Cancellation Request';
    final when = notice.appointmentTime;
    final time = when == null
        ? 'Time not set'
        : '${when.hour.toString().padLeft(2, '0')}:${when.minute.toString().padLeft(2, '0')}';
    return ListTile(
      key: ValueKey('${notice.notificationType}-${notice.appointmentId}'),
      onTap: () => _open(notice),
      title: Text(notice.customerName),
      subtitle: Text(
        '${notice.serviceName} · ${_date(notice.appointmentDate)} $time · ${notice.branchName}',
      ),
      leading: Chip(
        label: Text(chip),
        backgroundColor: background,
        labelStyle: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 11),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  String _date(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  String _clock(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
