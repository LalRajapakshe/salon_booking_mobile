import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_exception.dart';
import '../../../shared/theme/app_colors.dart';
import '../models/reception_visit.dart';

/// Confirms a pending appointment. This does not check the customer in.
Future<bool> showConfirmAppointmentDialog({
  required BuildContext context,
  required ReceptionVisit visit,
  required Future<void> Function() onConfirm,
}) async {
  final saved = await showDialog<bool>(
    context: context,
    builder: (context) => _ConfirmAppointmentDialog(visit: visit, onConfirm: onConfirm),
  );
  return saved == true;
}

class _ConfirmAppointmentDialog extends StatefulWidget {
  final ReceptionVisit visit;
  final Future<void> Function() onConfirm;

  const _ConfirmAppointmentDialog({required this.visit, required this.onConfirm});

  @override
  State<_ConfirmAppointmentDialog> createState() => _ConfirmAppointmentDialogState();
}

class _ConfirmAppointmentDialogState extends State<_ConfirmAppointmentDialog> {
  bool _saving = false;
  String? _error;

  Future<void> _confirm() async {
    if (_saving || !widget.visit.canConfirm) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onConfirm();
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = error.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final visit = widget.visit;
    final date = DateFormat('EEE, d MMM yyyy').format(visit.date);
    return AlertDialog(
      title: const Text('Confirm appointment'),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(visit.customerName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            _line('Appointment', '$date · ${visit.timeLabel}'),
            _line('Services', visit.services),
            _line('Employee', visit.employee),
            _line('Status', visit.status.label),
            const Text(
              'This sets the appointment to Confirmed. It does not check the customer in.',
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
          onPressed: !visit.canConfirm || _saving ? null : _confirm,
          child: Text(_saving ? 'Confirming' : 'Confirm appointment'),
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
