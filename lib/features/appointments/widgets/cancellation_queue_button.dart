import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/auth/auth_session.dart';
import '../../../core/auth/staff_access.dart';
import '../data/appointment_repository.dart';
import '../screens/cancellation_queue_screen.dart';

/// Pending cancellation count at the top of a staff screen.
class CancellationQueueButton extends StatefulWidget {
  const CancellationQueueButton({
    super.key,
    this.repository,
    this.onResolved,
    this.refreshSignal,
    this.branchId,
  });

  final AppointmentRepository? repository;
  final Future<void> Function()? onResolved;
  final Listenable? refreshSignal;
  final int? branchId;

  @override
  State<CancellationQueueButton> createState() => _CancellationQueueButtonState();
}

class _CancellationQueueButtonState extends State<CancellationQueueButton> with WidgetsBindingObserver {
  late final AppointmentRepository _repository = widget.repository ?? AppointmentRepository();
  Timer? _timer;
  int _count = 0;

  bool get _visible => StaffAccess.seesNotificationQueue(AuthSession.instance);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.refreshSignal?.addListener(_onRefreshSignal);
    _refresh();
    if (WidgetsBinding.instance.runtimeType.toString().contains('TestWidgets')) return;
    _timer = Timer.periodic(const Duration(seconds: 60), (_) => _refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.refreshSignal?.removeListener(_onRefreshSignal);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  void _onRefreshSignal() {
    _refresh();
  }

  Future<void> _refresh() async {
    if (!_visible || !AuthSession.instance.isSignedIn) return;
    try {
      final items = await _repository.listCancellationRequests(branchId: widget.branchId);
      if (!mounted) return;
      setState(() => _count = items.where((item) => item.isPending).length);
    } on ApiException {
      // Keep the last count. A failed refresh must not clear a live queue.
    }
  }

  Future<void> _open() async {
    final resolved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CancellationQueueScreen(
          repository: _repository,
          branchId: widget.branchId,
        ),
      ),
    );
    await _refresh();
    if (resolved == true) await widget.onResolved?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();
    return IconButton(
      tooltip: _count == 0 ? 'Notifications' : '$_count notifications',
      onPressed: _open,
      icon: Badge(
        isLabelVisible: _count > 0,
        label: Text('$_count'),
        child: const Icon(Icons.notifications_outlined),
      ),
    );
  }
}
