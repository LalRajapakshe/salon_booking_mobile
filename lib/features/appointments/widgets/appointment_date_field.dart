import 'package:flutter/material.dart';

import '../../../shared/utils/date_formatter.dart';

class AppointmentDateField extends StatelessWidget {
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final String? Function(String?)? validator;

  const AppointmentDateField({
    super.key,
    required this.value,
    required this.onChanged,
    this.validator,
  });

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: value ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      onChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = DateFormatter.format(value);

    return TextFormField(
      key: ValueKey(text),
      readOnly: true,
      initialValue: text.isEmpty ? null : text,
      validator: validator,
      decoration: const InputDecoration(
        labelText: 'Appointment Date',
        hintText: 'Select appointment date',
        suffixIcon: Icon(Icons.calendar_today_outlined),
      ),
      onTap: () => _pickDate(context),
    );
  }
}
