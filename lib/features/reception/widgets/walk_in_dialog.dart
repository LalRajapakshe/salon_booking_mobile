import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/api/api_exception.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/utils/validators.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../appointments/models/salon_lookups.dart';
import '../../appointments/services/appointment_catalog.dart';
import '../../customers/data/customer_repository.dart';
import '../../customers/widgets/customer_photo_field.dart';

class WalkInChoice {
  final int customerId;
  final String customerName;
  final bool createdNow;

  const WalkInChoice({
    required this.customerId,
    required this.customerName,
    this.createdNow = false,
  });
}

/// Searches or creates a customer, then optionally continues to an appointment.
/// It does not check the customer in.
Future<WalkInChoice?> showWalkInDialog({
  required BuildContext context,
  required CustomerRepository customers,
}) {
  return showDialog<WalkInChoice>(
    context: context,
    builder: (context) => _WalkInDialog(customers: customers),
  );
}

class _WalkInDialog extends StatefulWidget {
  final CustomerRepository customers;

  const _WalkInDialog({required this.customers});

  @override
  State<_WalkInDialog> createState() => _WalkInDialogState();
}

class _WalkInDialogState extends State<_WalkInDialog> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _newCustomer = false;
  bool _loading = false;
  bool _saving = false;
  String? _error;
  String? _gender;
  Uint8List? _photoBytes;
  int? _savedCustomerId;
  String? _savedName;
  List<CustomerLookup> _customers = const [];
  int? _selectedId;

  bool get _canCreate => widget.customers.isApiBacked;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!_canCreate) {
      setState(() => _customers = AppointmentCatalog.customers);
      return;
    }
    setState(() => _loading = true);
    try {
      final customers = await widget.customers.list();
      if (!mounted) return;
      setState(() {
        _customers = [
          for (final customer in customers)
            CustomerLookup(
              customerId: customer.id,
              customerCode: customer.customerCode,
              firstName: customer.firstName,
              lastName: customer.lastName,
              mobileNo: customer.mobileNumber,
              branchId: 0,
            ),
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

  List<CustomerLookup> get _matches {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _customers;
    return _customers.where((customer) {
      return customer.fullName.toLowerCase().contains(query) ||
          customer.mobileNo.contains(query);
    }).toList();
  }

  Future<void> _saveCustomer() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    if (_savedCustomerId != null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final created = await widget.customers.create(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        mobileNo: _mobileController.text,
        email: _empty(_emailController.text),
        gender: _gender,
        remarks: _empty(_notesController.text),
      );
      final photo = _photoBytes;
      if (photo != null) {
        try {
          await widget.customers.uploadPhoto(created.id, photo);
        } on ApiException catch (error) {
          if (!mounted) return;
          setState(() {
            _saving = false;
            _savedCustomerId = created.id;
            _savedName = created.fullName;
            _error = '${created.fullName} was saved, but the photo was not stored. ${error.message}';
          });
          return;
        }
      }
      if (!mounted) return;
      setState(() {
        _saving = false;
        _savedCustomerId = created.id;
        _savedName = created.fullName;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = error.message;
      });
    }
  }

  void _continueAppointment(int customerId, String name, {bool createdNow = false}) {
    Navigator.of(context).pop(
      WalkInChoice(customerId: customerId, customerName: name, createdNow: createdNow),
    );
  }

  String? _empty(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Walk-in registration'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This registers a customer or opens a new appointment. It does not check anyone in.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 12),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Existing customer')),
                ButtonSegment(value: true, label: Text('New customer')),
              ],
              selected: {_newCustomer},
              onSelectionChanged: (value) => setState(() => _newCustomer = value.first),
            ),
            const SizedBox(height: 16),
            if (_newCustomer) _newForm() else _searchList(),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: AppColors.error)),
            ],
          ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        if (!_newCustomer)
          FilledButton(
            onPressed: _selectedId == null
                ? null
                : () {
                    final selected = _customers.firstWhere((item) => item.customerId == _selectedId);
                    _continueAppointment(selected.customerId, selected.fullName);
                  },
            child: const Text('Create appointment'),
          ),
        if (_newCustomer && _savedCustomerId == null)
          FilledButton(
            onPressed: !_canCreate || _saving ? null : _saveCustomer,
            child: Text(_saving ? 'Saving' : 'Save customer'),
          ),
        if (_newCustomer && _savedCustomerId != null)
          FilledButton(
            onPressed: () => _continueAppointment(
              _savedCustomerId!,
              _savedName ?? 'Customer',
              createdNow: true,
            ),
            child: const Text('Create appointment'),
          ),
      ],
    );
  }

  Widget _searchList() {
    final matches = _matches;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            labelText: 'Search name or mobile',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (matches.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('No matching customer. Use New customer to register one.'),
          )
        else
          SizedBox(
            height: 220,
            child: ListView(
              children: [
                for (final customer in matches)
                  ListTile(
                    selected: customer.customerId == _selectedId,
                    title: Text(customer.fullName),
                    subtitle: Text(customer.mobileNo),
                    onTap: () => setState(() => _selectedId = customer.customerId),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _newForm() {
    if (!_canCreate) {
      return const Text('Sign in to register a new customer. You can still select an existing sample customer.');
    }
    if (_savedCustomerId != null) {
      return Text('${_savedName ?? 'The customer'} was saved. Create an appointment only if you want one.');
    }
    return Form(
      key: _formKey,
      child: Column(
        children: [
          CustomerPhotoField(
            bytes: _photoBytes,
            enabled: !_saving,
            onSelected: (bytes) => setState(() => _photoBytes = bytes),
            onInvalid: (message) => setState(() => _error = message),
            onRemove: () => setState(() => _photoBytes = null),
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: _firstNameController,
            labelText: 'First name',
            validator: (value) => Validators.required(value) == null ? null : 'First name is required',
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: _lastNameController,
            labelText: 'Last name',
            validator: (value) => Validators.required(value) == null ? null : 'Last name is required',
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: _mobileController,
            labelText: 'Mobile number',
            keyboardType: TextInputType.phone,
            validator: Validators.phone,
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: _emailController,
            labelText: 'Email',
            validator: (value) {
              if (value == null || value.trim().isEmpty) return null;
              return Validators.email(value);
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _gender,
            decoration: const InputDecoration(labelText: 'Gender'),
            items: const [
              DropdownMenuItem(value: 'Male', child: Text('Male')),
              DropdownMenuItem(value: 'Female', child: Text('Female')),
              DropdownMenuItem(value: 'Other', child: Text('Other')),
            ],
            onChanged: _saving ? null : (value) => setState(() => _gender = value),
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: _notesController,
            labelText: 'Notes',
          ),
        ],
      ),
    );
  }
}
