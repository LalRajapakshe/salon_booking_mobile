import 'package:flutter/material.dart';

import '../../../core/api/api_exception.dart';
import '../../../shared/utils/validators.dart';
import '../../../shared/widgets/app_primary_button.dart';
import '../../../shared/widgets/app_secondary_button.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../data/branch_repository.dart';
import '../models/branch_record.dart';

class BranchFormScreen extends StatefulWidget {
  final BranchRepository repository;
  final BranchRecord? branch;

  const BranchFormScreen({super.key, required this.repository, this.branch});

  bool get isEditing => branch != null;

  @override
  State<BranchFormScreen> createState() => _BranchFormScreenState();
}

class _BranchFormScreenState extends State<BranchFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _address1Controller = TextEditingController();
  final TextEditingController _address2Controller = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _managerController = TextEditingController();

  bool _isHeadOffice = false;
  bool _isActive = true;
  bool _saving = false;
  bool _validateOnInteraction = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    final branch = widget.branch;
    if (branch == null) return;
    _nameController.text = branch.branchName;
    _address1Controller.text = branch.addressLine1 ?? '';
    _address2Controller.text = branch.addressLine2 ?? '';
    _cityController.text = branch.city ?? '';
    _phoneController.text = branch.phoneNo ?? '';
    _emailController.text = branch.email ?? '';
    _managerController.text = branch.managerName ?? '';
    _isHeadOffice = branch.isHeadOffice;
    _isActive = branch.isActive;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _address1Controller.dispose();
    _address2Controller.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _managerController.dispose();
    super.dispose();
  }

  String? _empty(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String? _phone(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    if (!RegExp(r'^\d{10}$').hasMatch(trimmed)) {
      return 'Phone number must contain exactly 10 digits';
    }
    return null;
  }

  String? _email(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return Validators.email(value.trim());
  }

  Future<void> _save() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      setState(() => _validateOnInteraction = true);
      return;
    }
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      final existing = widget.branch;
      if (existing == null) {
        await widget.repository.create(
          branchName: _nameController.text,
          addressLine1: _empty(_address1Controller.text),
          addressLine2: _empty(_address2Controller.text),
          city: _empty(_cityController.text),
          phoneNo: _empty(_phoneController.text),
          email: _empty(_emailController.text),
          managerName: _empty(_managerController.text),
          isHeadOffice: _isHeadOffice,
        );
      } else {
        await widget.repository.update(
          BranchRecord(
            id: existing.id,
            tenantId: existing.tenantId,
            branchCode: existing.branchCode,
            branchName: _nameController.text.trim(),
            addressLine1: _empty(_address1Controller.text),
            addressLine2: _empty(_address2Controller.text),
            city: _empty(_cityController.text),
            phoneNo: _empty(_phoneController.text),
            email: _empty(_emailController.text),
            managerName: _empty(_managerController.text),
            isHeadOffice: _isHeadOffice,
            isActive: _isActive,
          ),
        );
      }
      if (!mounted) return;
      AppSnackBar.success(
        context,
        existing == null ? 'Branch was saved.' : 'Branch was updated.',
      );
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
    final editing = widget.isEditing;
    return Scaffold(
      backgroundColor: const Color(0xffF4F6FA),
      appBar: AppBar(
        elevation: 0,
        title: Text(
          editing ? 'Edit Branch' : 'Create Branch',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Form(
        key: _formKey,
        autovalidateMode: _validateOnInteraction
            ? AutovalidateMode.onUserInteraction
            : AutovalidateMode.disabled,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              editing
                  ? 'Code ${widget.branch!.branchCode} stays the same'
                  : 'The branch code is assigned when the record is saved',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            AppTextField(
              controller: _nameController,
              labelText: 'Branch Name',
              prefixIcon: Icons.store_outlined,
              validator: (value) {
                if (Validators.required(value) != null) return 'Branch name is required';
                return Validators.maxLength(value, 100);
              },
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _cityController,
              labelText: 'City',
              prefixIcon: Icons.location_city_outlined,
              validator: (value) => Validators.maxLength(value, 100),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _address1Controller,
              labelText: 'Address line 1',
              prefixIcon: Icons.location_on_outlined,
              validator: (value) => Validators.maxLength(value, 200),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _address2Controller,
              labelText: 'Address line 2',
              prefixIcon: Icons.location_on_outlined,
              validator: (value) => Validators.maxLength(value, 200),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _phoneController,
              labelText: 'Phone',
              hintText: '0112345678',
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: _phone,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _emailController,
              labelText: 'Email',
              prefixIcon: Icons.email_outlined,
              validator: _email,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _managerController,
              labelText: 'Manager',
              prefixIcon: Icons.badge_outlined,
              validator: (value) => Validators.maxLength(value, 100),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Head office'),
              value: _isHeadOffice,
              onChanged: (value) => setState(() => _isHeadOffice = value),
            ),
            if (editing)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active'),
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
              ),
            if (_saveError != null)
              Text(_saveError!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
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
