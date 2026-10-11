import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_exception.dart';
import '../../../shared/theme/app_colors.dart';
import '../models/reception_visit.dart';

/// Confirms arrival. The displayed clock time is not sent to the server.
Future<bool> showCheckInDialog({
  required BuildContext context,
  required ReceptionVisit visit,
  required Future<void> Function() onConfirm,
}) async {
  final saved = await showDialog<bool>(
    context: context,
    builder: (context) => _CheckInDialog(visit: visit, onConfirm: onConfirm),
  );
  return saved == true;
}

class _CheckInDialog extends StatefulWidget {
  final ReceptionVisit visit;
  final Future<void> Function() onConfirm;

  const _CheckInDialog({required this.visit, required this.onConfirm});

  @override
  State<_CheckInDialog> createState() => _CheckInDialogState();
}

class _CheckInDialogState extends State<_CheckInDialog> {
  bool _saving = false;
  String? _error;
  late final DateTime _shownAt = DateTime.now();

  Future<void> _confirm() async {
    if (_saving || !widget.visit.canCheckIn) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onConfirm();
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = error is ApiException ? error.message : 'The customer could not be checked in.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final visit = widget.visit;
    final date = DateFormat('EEE, d MMM yyyy').format(visit.date);
    final shown = DateFormat('d MMM yyyy, HH:mm').format(_shownAt);
    return AlertDialog(
      title: const Text('Check in customer'),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(visit.customerName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            if (visit.mobile.isNotEmpty)
              Text(visit.mobile, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            _line('Appointment', '$date · ${visit.timeLabel}'),
            _line('Services', visit.services),
            _line('Employee', visit.employee),
            _line('Status', visit.status.label),
            if (visit.priceLabel != null) _line('Price', visit.priceLabel!),
            const SizedBox(height: 8),
            _line('Check-in time', shown),
            const Text(
              'This time is shown for confirmation. Only the checked-in status is saved.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppColors.error)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: !visit.canCheckIn || _saving ? null : _confirm,
          child: Text(
            _saving
                ? 'Checking in'
                : visit.canCheckIn
                    ? 'Check in customer'
                    : 'Already checked in',
          ),
        ),
      ],
    );
  }

  Widget _line(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
