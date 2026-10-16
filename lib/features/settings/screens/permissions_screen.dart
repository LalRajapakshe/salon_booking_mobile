import 'package:flutter/material.dart';

import '../../../core/api/api_exception.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../shared/widgets/app_page.dart';
import '../data/access_repository.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  final AccessRepository _access = AccessRepository();
  bool _loading = true;
  String? _error;
  List<AccessPermission> _permissions = [];

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

  @override
  Widget build(BuildContext context) {
    final areas = <String, List<AccessPermission>>{};
    for (final permission in _permissions) {
      areas.putIfAbsent(permission.area, () => []).add(permission);
    }

    return AppPage(
      title: 'Permissions',
      subtitle: 'Catalog of what a role can allow. Permissions are defined by the system.',
      child: _loading
          ? const AppLoading(message: 'Loading permissions')
          : _error != null
              ? AppEmptyState(
                  icon: Icons.error_outline,
                  title: 'Permissions could not be loaded',
                  message: _error!,
                  buttonText: 'Try again',
                  onPressed: _load,
                )
              : _permissions.isEmpty
                  ? const AppEmptyState(
                      title: 'No permissions',
                      message: 'The permission catalog is empty.',
                    )
                  : ListView(
                      children: [
                        for (final area in areas.entries) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Text(area.key, style: Theme.of(context).textTheme.titleMedium),
                          ),
                          ...area.value.map(
                            (permission) => ListTile(
                              title: Text(permission.name),
                              subtitle: Text(permission.description ?? permission.code),
                              trailing: Text(permission.code, style: Theme.of(context).textTheme.labelSmall),
                            ),
                          ),
                        ],
                      ],
                    ),
    );
  }
}
