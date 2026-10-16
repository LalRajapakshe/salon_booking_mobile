import 'package:flutter/material.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/auth/auth_session.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../shared/widgets/app_page.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../data/access_repository.dart';
import 'user_form_screen.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key, this.assignRoles = false});

  final bool assignRoles;

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final AccessRepository _access = AccessRepository();
  bool _loading = true;
  String? _error;
  List<AccessUser> _users = [];

  bool get _canManage => AuthSession.instance.can('users.manage');

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
      final users = await _access.listUsers();
      if (!mounted) return;
      setState(() {
        _users = users;
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

  Future<void> _openForm([AccessUser? user]) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => UserFormScreen(user: user, focusRoles: widget.assignRoles)),
    );
    if (saved == true) _load();
  }

  Future<void> _toggle(AccessUser user, bool active) async {
    try {
      await _access.setActive(user.id, active);
      if (!mounted) return;
      AppSnackBar.success(context, active ? '${user.username} is active.' : '${user.username} is inactive.');
      _load();
    } on ApiException catch (error) {
      if (!mounted) return;
      AppSnackBar.error(context, error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: widget.assignRoles ? 'User Roles' : 'Users',
      subtitle: widget.assignRoles
          ? 'Choose which roles each user has.'
          : 'General, employee, and customer accounts.',
      floatingActionButton: _canManage
          ? FloatingActionButton.extended(
              onPressed: () => _openForm(),
              icon: const Icon(Icons.person_add_alt),
              label: const Text('New user'),
            )
          : null,
      child: _loading
          ? const AppLoading(message: 'Loading users')
          : _error != null
              ? AppEmptyState(
                  icon: Icons.error_outline,
                  title: 'Users could not be loaded',
                  message: _error!,
                  buttonText: 'Try again',
                  onPressed: _load,
                )
              : _users.isEmpty
                  ? const AppEmptyState(
                      icon: Icons.group_outlined,
                      title: 'No users',
                      message: 'Create a user and link an employee or customer when needed.',
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        itemCount: _users.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final user = _users[index];
                          return ListTile(
                            title: Text(user.fullName.isEmpty ? user.username : user.fullName),
                            subtitle: Text(
                              '${user.username} · ${user.category}'
                              '${user.roleNames.isEmpty ? '' : ' · ${user.roleNames.join(', ')}'}',
                            ),
                            trailing: _canManage
                                ? Switch(
                                    value: user.isActive,
                                    onChanged: (value) => _toggle(user, value),
                                  )
                                : Icon(user.isActive ? Icons.check_circle_outline : Icons.pause_circle_outline),
                            onTap: _canManage ? () => _openForm(user) : null,
                          );
                        },
                      ),
                    ),
    );
  }
}
