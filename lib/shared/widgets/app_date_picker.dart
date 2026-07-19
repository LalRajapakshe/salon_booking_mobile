import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/app_dimensions.dart';

class AppDatePicker extends StatelessWidget {
  final String? labelText;
  final String? hintText;
  final DateTime? selectedDate;
  final ValueChanged<DateTime>? onDateSelected;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool enabled;

  const AppDatePicker({
    super.key,
    this.labelText,
    this.hintText,
    this.selectedDate,
    this.onDateSelected,
    this.firstDate,
    this.lastDate,
    this.enabled = true,
  });

  Future<void> _pickDate(BuildContext context) async {
    if (!enabled) return;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: firstDate ?? DateTime(2000),
      lastDate: lastDate ?? DateTime(2100),
    );

    if (pickedDate != null) {
      onDateSelected?.call(pickedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(
      text: selectedDate == null
          ? ''
          : DateFormat('dd/MM/yyyy').format(selectedDate!),
    );

    return TextFormField(
      controller: controller,
      readOnly: true,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        suffixIcon: const Icon(Icons.calendar_today_outlined),
      ),
      onTap: () => _pickDate(context),
    );
  }
}