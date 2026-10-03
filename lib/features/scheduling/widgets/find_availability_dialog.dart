import 'package:flutter/material.dart';

import '../../../shared/widgets/app_dropdown.dart';
import '../../../shared/widgets/app_primary_button.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../data/mock_scheduling_data.dart';
import '../models/scheduling_models.dart';

Future<void> showFindAvailabilityDialog({
  required BuildContext context,
  required DateTime date,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return FindAvailabilityDialog(
        date: date,
        onClose: () => Navigator.of(dialogContext).pop(),
        onSelect: (customerName, windowLabel) {
          Navigator.of(dialogContext).pop();
          AppSnackBar.success(
            context,
            '$windowLabel selected for $customerName.',
          );
        },
      );
    },
  );
}

class FindAvailabilityDialog extends StatefulWidget {
  final DateTime date;
  final VoidCallback onClose;
  final void Function(String customerName, String windowLabel) onSelect;

  const FindAvailabilityDialog({
    super.key,
    required this.date,
    required this.onClose,
    required this.onSelect,
  });

  @override
  State<FindAvailabilityDialog> createState() => _FindAvailabilityDialogState();
}

class _FindAvailabilityDialogState extends State<FindAvailabilityDialog> {
  late String _customerName = mockAvailabilitySuggestions.first.customerName;

  AvailabilitySuggestion get _suggestion {
    return mockAvailabilitySuggestions.firstWhere(
      (item) => item.customerName == _customerName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final suggestion = _suggestion;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 12, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Find availability',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: widget.onClose,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Sample recommendations for this day',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 16),
              AppDropdown<String>(
                labelText: 'Customer',
                value: _customerName,
                items: [
                  for (final item in mockAvailabilitySuggestions)
                    DropdownMenuItem<String>(
                      value: item.customerName,
                      child: Text(
                        item.customerName,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _customerName = value);
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Services',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              for (final service in suggestion.services)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 18,
                        color: Color(0xFF2E7D32),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${service.name} — ${service.durationMinutes} min',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                'Preferred date',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                formatScheduleDate(widget.date),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Available schedules',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              for (
                var index = 0;
                index < suggestion.options.length;
                index++
              ) ...[
                _optionCard(index, suggestion.options[index]),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _optionCard(int index, SuggestedSchedule option) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6E8EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Option ${index + 1}',
            style: const TextStyle(
              color: Color(0xFF673AB7),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            option.windowLabel,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          for (final assignment in option.assignments)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    assignment.serviceName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${assignment.staffName} · ${formatScheduleRange(assignment.startMinute, assignment.endMinute)}',
                    style: const TextStyle(
                      color: Color(0xFF616161),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          Align(
            alignment: Alignment.centerRight,
            child: AppPrimaryButton(
              text: 'Select',
              width: 120,
              onPressed: () =>
                  widget.onSelect(_customerName, option.windowLabel),
            ),
          ),
        ],
      ),
    );
  }
}
