import 'package:flutter/material.dart';

import '../../../core/api/api_exception.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../shared/widgets/app_page.dart';
import '../../../shared/widgets/app_primary_button.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../data/access_repository.dart';

class UserFormScreen extends StatefulWidget {
  const UserFormScreen({super.key, this.user, this.focusRoles = false});

  final AccessUser? user;
  final bool focusRoles;

  @override
  State<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends State<UserFormScreen> {
  final AccessRepository _access = AccessRepository();
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _username;
  late final TextEditingController _password;
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _email;
  late final TextEditingController _mobile;
  String _category = 'General';
  int? _branchId;
  int? _employeeId;
  int? _customerId;
  final Set<int> _roleIds = {};
  List<AccessRole> _roles = [];
  List<DirectoryOption> _branches = [];
  List<DirectoryOption> _employees = [];
  List<DirectoryOption> _customers = [];
  bool _loading = true;
  bool _saving = false;
  String? _error;

  bool get _editing => widget.user != null;

  @override
  void initState() {
    super.initState();
    final user = widget.user;
    _username = TextEditingController(text: user?.username ?? '');
    _password = TextEditingController();
    _firstName = TextEditingController(text: user?.firstName ?? '');
    _lastName = TextEditingController(text: user?.lastName ?? '');
    _email = TextEditingController(text: user?.email ?? '');
    _mobile = TextEditingController(text: user?.mobileNo ?? '');
    _category = user?.category ?? 'General';
    _branchId = user?.branchId;
    _employeeId = user?.employeeId;
    _customerId = user?.customerId;
    _roleIds.addAll(user?.roleIds ?? const []);
    _load();
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _mobile.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _access.listRoles(),
        _access.listBranches(),
        _access.listEmployees(),
        _access.listCustomers(),
      ]);
      if (!mounted) return;
      setState(() {
        _roles = results[0] as List<AccessRole>;
        _branches = results[1] as List<DirectoryOption>;
        _employees = results[2] as List<DirectoryOption>;
        _customers = results[3] as List<DirectoryOption>;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_category == 'Employee' && _employeeId == null) {
      AppSnackBar.error(context, 'Select the employee this account belongs to.');
      return;
    }
    if (_category == 'Customer' && _customerId == null) {
      AppSnackBar.error(context, 'Select the customer this account belongs to.');
      return;
    }
    setState(() => _saving = true);
    try {
      await _access.saveUser(
        id: widget.user?.id,
        username: _username.text,
        password: _password.text,
        firstName: _firstName.text,
        lastName: _lastName.text,
        email: _email.text,
        mobileNo: _mobile.text,
        category: _category,
        branchId: _category == 'General' ? _branchId : null,
        employeeId: _category == 'Employee' ? _employeeId : null,
        customerId: _category == 'Customer' ? _customerId : null,
        roleIds: _roleIds.toList(),
      );
      if (!mounted) return;
      AppSnackBar.success(context, _editing ? 'User updated.' : 'User created.');
      Navigator.pop(context, true);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppSnackBar.error(context, error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: _editing ? 'Edit user' : 'New user',
      subtitle: widget.focusRoles ? 'Assign roles for this account.' : 'The salon, branch, and link are checked on the server.',
      child: _loading
          ? const AppLoading(message: 'Loading account choices')
          : _error != null
              ? Center(child: Text(_error!))
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      AppTextField(
                        controller: _username,
                        labelText: 'Username',
                        validator: (value) => value == null || value.trim().isEmpty ? 'Username is required' : null,
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: _password,
                        labelText: _editing ? 'New password' : 'Password',
                        hintText: _editing ? 'Leave blank to keep the current password' : 'At least 8 characters',
                        obscureText: true,
                        validator: (value) {
                          if (!_editing && (value == null || value.length < 8)) {
                            return 'Password must be at least 8 characters';
                          }
                          if (_editing && value != null && value.isNotEmpty && value.length < 8) {
                            return 'Password must be at least 8 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: _firstName,
                        labelText: 'First name',
                        validator: (value) => value == null || value.trim().isEmpty ? 'First name is required' : null,
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: _lastName,
                        labelText: 'Last name',
                        validator: (value) => value == null || value.trim().isEmpty ? 'Last name is required' : null,
                      ),
                      const SizedBox(height: 12),
                      AppTextField(controller: _email, labelText: 'Email'),
                      const SizedBox(height: 12),
                      AppTextField(controller: _mobile, labelText: 'Mobile number'),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _category,
                        decoration: const InputDecoration(labelText: 'User category'),
                        items: const [
                          DropdownMenuItem(value: 'General', child: Text('General user')),
                          DropdownMenuItem(value: 'Employee', child: Text('Employee user')),
                          DropdownMenuItem(value: 'Customer', child: Text('Customer user')),
                        ],
                        onChanged: (value) => setState(() => _category = value ?? 'General'),
                      ),
                      const SizedBox(height: 12),
                      if (_category == 'General')
                        DropdownButtonFormField<int?>(
                          value: _branches.any((item) => item.id == _branchId) ? _branchId : null,
                          decoration: const InputDecoration(labelText: 'Branch'),
                          items: [
                            const DropdownMenuItem<int?>(value: null, child: Text('All branches in this salon')),
                            ..._branches.map((item) => DropdownMenuItem(value: item.id, child: Text(item.label))),
                          ],
                          onChanged: (value) => setState(() => _branchId = value),
                        ),
                      if (_category == 'Employee')
                        DropdownButtonFormField<int>(
                          value: _employees.any((item) => item.id == _employeeId) ? _employeeId : null,
                          decoration: const InputDecoration(labelText: 'Employee'),
                          items: _employees
                              .map((item) => DropdownMenuItem(value: item.id, child: Text(item.label)))
                              .toList(),
                          onChanged: (value) => setState(() => _employeeId = value),
                        ),
                      if (_category == 'Customer')
                        DropdownButtonFormField<int>(
                          value: _customers.any((item) => item.id == _customerId) ? _customerId : null,
                          decoration: const InputDecoration(labelText: 'Customer'),
                          items: _customers
                              .map((item) => DropdownMenuItem(value: item.id, child: Text(item.label)))
                              .toList(),
                          onChanged: (value) => setState(() => _customerId = value),
                        ),
                      const SizedBox(height: 16),
                      Text('Roles', style: Theme.of(context).textTheme.titleMedium),
                      if (_roles.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text('No roles are available yet.'),
                        ),
                      ..._roles.map(
                        (role) => CheckboxListTile(
                          value: _roleIds.contains(role.id),
                          title: Text(role.name),
                          subtitle: Text(role.code),
                          onChanged: (checked) {
                            setState(() {
                              if (checked == true) {
                                _roleIds.add(role.id);
                              } else {
                                _roleIds.remove(role.id);
                              }
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      AppPrimaryButton(
                        text: _editing ? 'Save user' : 'Create user',
                        isLoading: _saving,
                        onPressed: _saving ? null : _save,
                      ),
                    ],
                  ),
                ),
    );
  }
}
