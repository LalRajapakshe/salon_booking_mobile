import 'package:flutter/material.dart';

import '../../../shared/widgets/app_dropdown.dart';
import '../models/scheduling_models.dart';

class SchedulingToolbar extends StatelessWidget {
  final DateTime date;
  final String summary;
  final String staffFilter;
  final String serviceFilter;
  final String statusFilter;
  final List<String> staffNames;
  final List<String> serviceNames;
  final List<String> statuses;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToday;
  final ValueChanged<String?> onStaffChanged;
  final ValueChanged<String?> onServiceChanged;
  final ValueChanged<String?> onStatusChanged;
  final VoidCallback onFindAvailability;

  const SchedulingToolbar({
    super.key,
    required this.date,
    required this.summary,
    required this.staffFilter,
    required this.serviceFilter,
    required this.statusFilter,
    required this.staffNames,
    required this.serviceNames,
    required this.statuses,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
    required this.onStaffChanged,
    required this.onServiceChanged,
    required this.onStatusChanged,
    required this.onFindAvailability,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 860;
        final compact = constraints.maxWidth < 520;
        final findButton = ElevatedButton.icon(
          onPressed: onFindAvailability,
          icon: const Icon(Icons.manage_search),
          label: const Text('Find Availability'),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _title(compact: false)),
                  const SizedBox(width: 16),
                  findButton,
                ],
              )
            else ...[
              _title(compact: compact),
              SizedBox(height: compact ? 8 : 12),
              findButton,
            ],
            SizedBox(height: compact ? 8 : 16),
            _dateRow(wide),
            SizedBox(height: compact ? 8 : 14),
            _filters(wide, compact),
          ],
        );
      },
    );
  }

  Widget _title({required bool compact}) {
    final summaryText = Text(
      summary,
      style: const TextStyle(color: Color(0xFF616161), fontSize: 13),
    );
    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Staff availability and appointments for the day',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 2),
          summaryText,
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Schedule',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Text(
          'Staff availability and appointments for the day',
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
        const SizedBox(height: 4),
        summaryText,
      ],
    );
  }

  Widget _dateRow(bool wide) {
    final dateLabel = Text(
      formatScheduleDate(date),
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
    );
    final today = OutlinedButton(
      onPressed: onToday,
      child: const Text('Today'),
    );

    return Row(
      children: [
        IconButton(
          tooltip: 'Previous day',
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left),
        ),
        Expanded(child: dateLabel),
        IconButton(
          tooltip: 'Next day',
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right),
        ),
        if (wide) const SizedBox(width: 8),
        today,
      ],
    );
  }

  Widget _filters(bool wide, bool compact) {
    final staff = _filter(
      label: 'Staff',
      value: staffFilter,
      options: ['All', ...staffNames],
      onChanged: onStaffChanged,
      compact: compact,
    );
    final service = _filter(
      label: 'Service',
      value: serviceFilter,
      options: ['All', ...serviceNames],
      onChanged: onServiceChanged,
      compact: compact,
    );
    final status = _filter(
      label: 'Status',
      value: statusFilter,
      options: ['All', ...statuses],
      onChanged: onStatusChanged,
      compact: compact,
    );

    if (!wide) {
      final gap = compact ? 8.0 : 12.0;
      return Column(
        children: [
          staff,
          SizedBox(height: gap),
          service,
          SizedBox(height: gap),
          status,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: staff),
        const SizedBox(width: 12),
        Expanded(child: service),
        const SizedBox(width: 12),
        Expanded(child: status),
      ],
    );
  }

  Widget _filter({
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
    required bool compact,
  }) {
    final items = [
      for (final option in options)
        DropdownMenuItem<String>(
          value: option,
          child: Text(option, overflow: TextOverflow.ellipsis),
        ),
    ];
    if (compact) {
      return DropdownButtonFormField<String>(
        value: value,
        isDense: true,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
        ),
        items: items,
        onChanged: onChanged,
      );
    }

    return AppDropdown<String>(
      labelText: label,
      value: value,
      items: items,
      onChanged: onChanged,
    );
  }
}
