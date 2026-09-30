import 'package:flutter/material.dart';

import '../../../shared/utils/app_constants.dart';
import '../../../shared/utils/validators.dart';
import '../../../shared/widgets/app_date_picker.dart';
import '../../../shared/widgets/app_dropdown.dart';
import '../../../shared/widgets/app_primary_button.dart';
import '../../../shared/widgets/app_secondary_button.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../models/customer_model.dart';

class CreateCustomerScreen extends StatefulWidget {
  const CreateCustomerScreen({super.key});

  @override
  State<CreateCustomerScreen> createState() => _CreateCustomerScreenState();
}

class _CreateCustomerScreenState extends State<CreateCustomerScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();

  final TextEditingController _customerCodeController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _mobileNumberController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String? _gender;
  DateTime? _dateOfBirth;
  bool _isActive = true;
  bool _validateOnInteraction = false;

  /// Gender values already stored on existing customer records.
  static const List<String> _genderOptions = ['Female', 'Male'];

  static const double _formMaxWidth = 840;
  static const double _twoColumnBreakpoint = 640;

  @override
  void dispose() {
    _scrollController.dispose();
    _customerCodeController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _mobileNumberController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _cancel() {
    Navigator.of(context).pop();
  }

  void _save() {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      setState(() => _validateOnInteraction = true);
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
      return;
    }

    // id and createdDate are required by Customer but are not entered
    // on this form. They are assigned locally until persistence exists.
    final customer = Customer(
      id: 0,
      customerCode: _customerCodeController.text.trim(),
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      mobileNumber: _mobileNumberController.text.trim(),
      email: _emptyToNull(_emailController.text),
      gender: _gender,
      dateOfBirth: _dateOfBirth,
      address: _emptyToNull(_addressController.text),
      notes: _emptyToNull(_notesController.text),
      isActive: _isActive,
      createdDate: DateTime.now(),
    );

    AppSnackBar.success(context, '${customer.fullName} was saved.');
    Navigator.of(context).pop();
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String? _requiredText(String? value, String label) {
    if (Validators.required(value) != null) {
      return '$label is required';
    }
    return Validators.maxLength(value, AppConstants.maxNameLength);
  }

  String? _optionalEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return Validators.email(value.trim());
  }

  String? _optionalLongText(String? value) {
    return Validators.maxLength(value, AppConstants.maxDescriptionLength);
  }

  DateTime get _latestBirthDate {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, 23, 59, 59);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F6FA),
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Create Customer',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final padding = constraints.maxWidth < 520 ? 16.0 : 24.0;

          return SingleChildScrollView(
            controller: _scrollController,
            padding: EdgeInsets.all(padding),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _formMaxWidth),
                child: Form(
                  key: _formKey,
                  autovalidateMode: _validateOnInteraction
                      ? AutovalidateMode.onUserInteraction
                      : AutovalidateMode.disabled,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 24),
                      _buildFormCard(),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Create Customer',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 6),
        Text(
          'Enter customer details and save the record',
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildFormCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final twoColumns = constraints.maxWidth >= _twoColumnBreakpoint;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  controller: _customerCodeController,
                  labelText: 'Customer Code',
                  hintText: 'Enter customer code',
                  prefixIcon: Icons.badge_outlined,
                  textInputAction: TextInputAction.next,
                  validator: (value) => _requiredText(value, 'Customer code'),
                ),
                const SizedBox(height: 16),
                _pair(
                  twoColumns: twoColumns,
                  first: AppTextField(
                    controller: _firstNameController,
                    labelText: 'First Name',
                    hintText: 'Enter first name',
                    prefixIcon: Icons.person_outline,
                    textInputAction: TextInputAction.next,
                    validator: (value) => _requiredText(value, 'First name'),
                  ),
                  second: AppTextField(
                    controller: _lastNameController,
                    labelText: 'Last Name',
                    hintText: 'Enter last name',
                    prefixIcon: Icons.person_outline,
                    textInputAction: TextInputAction.next,
                    validator: (value) => _requiredText(value, 'Last name'),
                  ),
                ),
                const SizedBox(height: 16),
                _pair(
                  twoColumns: twoColumns,
                  first: AppTextField(
                    controller: _mobileNumberController,
                    labelText: 'Mobile Number',
                    hintText: '10-digit mobile number',
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    validator: Validators.phone,
                  ),
                  second: AppTextField(
                    controller: _emailController,
                    labelText: 'Email',
                    hintText: 'name@example.com',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: _optionalEmail,
                  ),
                ),
                const SizedBox(height: 16),
                _pair(
                  twoColumns: twoColumns,
                  first: AppDropdown<String>(
                    labelText: 'Gender',
                    hintText: 'Select gender',
                    value: _gender,
                    items: [
                      for (final gender in _genderOptions)
                        DropdownMenuItem<String>(
                          value: gender,
                          child: Text(gender),
                        ),
                    ],
                    onChanged: (value) => setState(() => _gender = value),
                  ),
                  second: AppDatePicker(
                    labelText: 'Date of Birth',
                    hintText: 'Select date of birth',
                    selectedDate: _dateOfBirth,
                    firstDate: DateTime(1900),
                    lastDate: _latestBirthDate,
                    onDateSelected: (date) {
                      setState(() => _dateOfBirth = date);
                    },
                  ),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _addressController,
                  labelText: 'Address',
                  hintText: 'Enter address',
                  prefixIcon: Icons.location_on_outlined,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  maxLines: 3,
                  validator: _optionalLongText,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _notesController,
                  labelText: 'Notes',
                  hintText: 'Enter notes',
                  prefixIcon: Icons.notes_outlined,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  maxLines: 4,
                  validator: _optionalLongText,
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active'),
                  subtitle: const Text('Customer is active'),
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
                ),
                const SizedBox(height: 8),
                _buildActions(constraints.maxWidth),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _pair({
    required bool twoColumns,
    required Widget first,
    required Widget second,
  }) {
    if (!twoColumns) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          first,
          const SizedBox(height: 16),
          second,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: first),
        const SizedBox(width: 16),
        Expanded(child: second),
      ],
    );
  }

  Widget _buildActions(double maxWidth) {
    final cancel = AppSecondaryButton(
      text: 'Cancel',
      icon: Icons.close,
      width: maxWidth < 520 ? double.infinity : 160,
      onPressed: _cancel,
    );
    final save = AppPrimaryButton(
      text: 'Save',
      icon: Icons.check,
      width: maxWidth < 520 ? double.infinity : 160,
      onPressed: _save,
    );

    if (maxWidth < 520) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          save,
          const SizedBox(height: 12),
          cancel,
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        cancel,
        const SizedBox(width: 12),
        save,
      ],
    );
  }
}
