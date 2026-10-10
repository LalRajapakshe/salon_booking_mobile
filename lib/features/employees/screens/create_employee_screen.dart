import 'package:flutter/material.dart';

import '../../../core/api/api_exception.dart';
import '../../../shared/utils/validators.dart';
import '../../../shared/widgets/app_date_picker.dart';
import '../../../shared/widgets/app_dropdown.dart';
import '../../../shared/widgets/app_primary_button.dart';
import '../../../shared/widgets/app_secondary_button.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../data/employee_repository.dart';

class CreateEmployeeScreen extends StatefulWidget {
  final EmployeeRepository? repository;

  const CreateEmployeeScreen({super.key, this.repository});

  @override
  State<CreateEmployeeScreen> createState() => _CreateEmployeeScreenState();
}

class _CreateEmployeeScreenState extends State<CreateEmployeeScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _designationController = TextEditingController();
  final TextEditingController _salaryController = TextEditingController();

  late final EmployeeRepository _repository;
  String? _gender;
  DateTime? _dateOfBirth;
  DateTime? _hireDate;
  bool _saving = false;
  bool _validateOnInteraction = false;
  String? _saveError;

  static const List<String> _genders = ['Female', 'Male', 'Other'];

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? EmployeeRepository();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _designationController.dispose();
    _salaryController.dispose();
    super.dispose();
  }

  String? _required(String? value, String label) {
    if (Validators.required(value) != null) return '$label is required';
    return Validators.maxLength(value, 100);
  }

  String? _mobile(String? value) {
    if (value == null || !RegExp(r'^0\d{9}$').hasMatch(value.trim())) {
      return 'Enter a 10-digit mobile number starting with 0';
    }
    return null;
  }

  String? _optionalEmail(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return Validators.email(value.trim());
  }

  String? _salary(String? value) {
    final parsed = double.tryParse((value ?? '').trim().replaceAll(',', ''));
    if (parsed == null || parsed < 0) return 'Enter a salary of 0 or more';
    return null;
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<void> _save() async {
    final form = _formKey.currentState;
    final hireMissing = _hireDate == null;
    if (form == null || !form.validate() || hireMissing) {
      setState(() {
        _validateOnInteraction = true;
        _saveError = hireMissing ? 'Hire date is required' : null;
      });
      return;
    }
    if (!_repository.isApiBacked) {
      setState(() => _saveError = 'Sign in is required.');
      return;
    }

    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      final created = await _repository.create(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        mobileNo: _mobileController.text,
        designation: _designationController.text,
        hireDate: _hireDate!,
        salary: double.parse(_salaryController.text.trim().replaceAll(',', '')),
        email: _emptyToNull(_emailController.text),
        gender: _gender,
        dateOfBirth: _dateOfBirth,
        address: _emptyToNull(_addressController.text),
      );
      if (!mounted) return;
      AppSnackBar.success(context, '${created.fullName} was saved.');
      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveError = error.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F6FA),
      appBar: AppBar(
        elevation: 0,
        title: const Text('Create Employee', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Form(
        key: _formKey,
        autovalidateMode: _validateOnInteraction
            ? AutovalidateMode.onUserInteraction
            : AutovalidateMode.disabled,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              'Create Employee',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'The employee code is assigned when the record is saved',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 24),
            AppTextField(
              controller: _firstNameController,
              labelText: 'First Name',
              prefixIcon: Icons.person_outline,
              validator: (value) => _required(value, 'First name'),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _lastNameController,
              labelText: 'Last Name',
              prefixIcon: Icons.person_outline,
              validator: (value) => _required(value, 'Last name'),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _mobileController,
              labelText: 'Mobile Number',
              hintText: '0771234567',
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: _mobile,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _emailController,
              labelText: 'Email',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: _optionalEmail,
            ),
            const SizedBox(height: 16),
            AppDropdown<String>(
              labelText: 'Gender',
              hintText: 'Select gender',
              value: _gender,
              items: [
                for (final gender in _genders)
                  DropdownMenuItem<String>(value: gender, child: Text(gender)),
              ],
              onChanged: (value) => setState(() => _gender = value),
            ),
            const SizedBox(height: 16),
            AppDatePicker(
              labelText: 'Date of Birth',
              hintText: 'Select date of birth',
              selectedDate: _dateOfBirth,
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
              onDateSelected: (date) => setState(() => _dateOfBirth = date),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _addressController,
              labelText: 'Address',
              prefixIcon: Icons.location_on_outlined,
              maxLines: 3,
              validator: (value) => Validators.maxLength(value, 250),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _designationController,
              labelText: 'Designation',
              hintText: 'Stylist',
              prefixIcon: Icons.badge_outlined,
              validator: (value) => _required(value, 'Designation'),
            ),
            const SizedBox(height: 16),
            AppDatePicker(
              labelText: 'Hire Date',
              hintText: 'Select hire date',
              selectedDate: _hireDate,
              firstDate: DateTime(1990),
              lastDate: DateTime.now().add(const Duration(days: 365)),
              onDateSelected: (date) => setState(() => _hireDate = date),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _salaryController,
              labelText: 'Salary',
              hintText: '0',
              prefixIcon: Icons.payments_outlined,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: _salary,
            ),
            if (_saveError != null) ...[
              const SizedBox(height: 12),
              Text(_saveError!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AppSecondaryButton(
                  text: 'Cancel',
                  icon: Icons.close,
                  width: 160,
                  onPressed: _saving ? null : () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 12),
                AppPrimaryButton(
                  text: 'Save',
                  icon: Icons.check,
                  width: 160,
                  isLoading: _saving,
                  onPressed: _saving ? null : _save,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
