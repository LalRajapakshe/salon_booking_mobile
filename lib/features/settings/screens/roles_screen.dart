import 'package:flutter/material.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/auth/auth_session.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../shared/widgets/app_page.dart';
import '../../../shared/widgets/app_primary_button.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../data/access_repository.dart';

class RolesScreen extends StatefulWidget {
  const RolesScreen({super.key, this.assignPermissions = false});

  final bool assignPermissions;

  @override
  State<RolesScreen> createState() => _RolesScreenState();
}

class _RolesScreenState extends State<RolesScreen> {
  final AccessRepository _access = AccessRepository();
  bool _loading = true;
  String? _error;
  List<AccessRole> _roles = [];

  bool get _canManage => AuthSession.instance.can('roles.manage');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final roles = await _access.listRoles();
      if (!mounted) return;
      setState(() {
        _roles = roles;
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

  Future<void> _edit(AccessRole? role) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _RoleFormScreen(role: role, assignPermissions: widget.assignPermissions || role != null),
      ),
    );
    if (saved == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: widget.assignPermissions ? 'Role Permissions' : 'Roles',
      subtitle: 'A stylist and a receptionist are both employee users. Their roles decide what they can do.',
      floatingActionButton: _canManage && !widget.assignPermissions
          ? FloatingActionButton.extended(
              onPressed: () => _edit(null),
              icon: const Icon(Icons.add),
              label: const Text('New role'),
            )
          : null,
      child: _loading
          ? const AppLoading(message: 'Loading roles')
          : _error != null
              ? AppEmptyState(
                  icon: Icons.error_outline,
                  title: 'Roles could not be loaded',
                  message: _error!,
                  buttonText: 'Try again',
                  onPressed: _load,
                )
              : _roles.isEmpty
                  ? const AppEmptyState(
                      title: 'No roles',
                      message: 'Create a role, then assign permissions to it.',
                    )
                  : ListView.separated(
                      itemCount: _roles.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final role = _roles[index];
                        return ListTile(
                          title: Text(role.name),
                          subtitle: Text('${role.code} · ${role.permissionIds.length} permissions'),
                          trailing: Icon(role.isActive ? Icons.check_circle_outline : Icons.pause_circle_outline),
                          onTap: _canManage ? () => _edit(role) : null,
                        );
                      },
                    ),
    );
  }
}

class _RoleFormScreen extends StatefulWidget {
  const _RoleFormScreen({required this.role, required this.assignPermissions});

  final AccessRole? role;
  final bool assignPermissions;

  @override
  State<_RoleFormScreen> createState() => _RoleFormScreenState();
}

class _RoleFormScreenState extends State<_RoleFormScreen> {
  final AccessRepository _access = AccessRepository();
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _code;
  late final TextEditingController _name;
  late final TextEditingController _description;
  late bool _isActive;
  final Set<int> _permissionIds = {};
  List<AccessPermission> _permissions = [];
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final role = widget.role;
    _code = TextEditingController(text: role?.code ?? '');
    _name = TextEditingController(text: role?.name ?? '');
    _description = TextEditingController(text: role?.description ?? '');
    _isActive = role?.isActive ?? true;
    _permissionIds.addAll(role?.permissionIds ?? const []);
    _load();
  }

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!widget.assignPermissions && widget.role == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final permissions = await _access.listPermissions();
      if (!mounted) return;
      setState(() {
        _permissions = permissions;
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
    setState(() => _saving = true);
    try {
      final saved = await _access.saveRole(
        id: widget.role?.id,
        code: _code.text,
        name: _name.text,
        description: _description.text,
        isActive: _isActive,
      );
      if (widget.role != null || _permissionIds.isNotEmpty) {
        await _access.setRolePermissions(saved.id, _permissionIds.toList());
      }
      if (!mounted) return;
      AppSnackBar.success(context, 'Role saved.');
      Navigator.pop(context, true);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppSnackBar.error(context, error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final areas = <String, List<AccessPermission>>{};
    for (final permission in _permissions) {
      areas.putIfAbsent(permission.area, () => []).add(permission);
    }

    return AppPage(
      title: widget.role == null ? 'New role' : widget.role!.name,
      child: _loading
          ? const AppLoading(message: 'Loading permissions')
          : _error != null
              ? Center(child: Text(_error!))
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      AppTextField(
                        controller: _code,
                        labelText: 'Role code',
                        validator: (value) => value == null || value.trim().isEmpty ? 'Role code is required' : null,
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: _name,
                        labelText: 'Role name',
                        validator: (value) => value == null || value.trim().isEmpty ? 'Role name is required' : null,
                      ),
                      const SizedBox(height: 12),
                      AppTextField(controller: _description, labelText: 'Description'),
                      SwitchListTile(
                        value: _isActive,
                        title: const Text('Active'),
                        onChanged: (value) => setState(() => _isActive = value),
                      ),
                      if (_permissions.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text('Permissions', style: Theme.of(context).textTheme.titleMedium),
                        for (final area in areas.entries) ...[
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(area.key, style: Theme.of(context).textTheme.titleSmall),
                          ),
                          ...area.value.map(
                            (permission) => CheckboxListTile(
                              value: _permissionIds.contains(permission.id),
                              title: Text(permission.name),
                              subtitle: Text(permission.description ?? permission.code),
                              onChanged: (checked) {
                                setState(() {
                                  if (checked == true) {
                                    _permissionIds.add(permission.id);
                                  } else {
                                    _permissionIds.remove(permission.id);
                                  }
                                });
                              },
                            ),
                          ),
                        ],
                      ],
                      const SizedBox(height: 16),
                      AppPrimaryButton(
                        text: 'Save role',
                        isLoading: _saving,
                        onPressed: _saving ? null : _save,
                      ),
                    ],
                  ),
                ),
    );
  }
}
