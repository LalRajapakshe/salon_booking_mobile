import 'package:flutter/material.dart';

import '../../../core/api/api_exception.dart';
import '../../../shared/widgets/app_dialog.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../data/branch_repository.dart';
import '../models/branch_record.dart';
import 'branch_form_screen.dart';

class BranchesScreen extends StatefulWidget {
  final BranchRepository? repository;

  const BranchesScreen({super.key, this.repository});

  @override
  State<BranchesScreen> createState() => _BranchesScreenState();
}

class _BranchesScreenState extends State<BranchesScreen> {
  late final BranchRepository _repository;
  List<BranchRecord> _branches = const [];
  bool _loading = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? BranchRepository();
    if (_repository.isApiBacked) {
      _loading = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _load();
      });
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final branches = await _repository.list();
      if (!mounted) return;
      setState(() {
        _branches = branches;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error.message;
        _loading = false;
      });
    }
  }

  Future<void> _openForm([BranchRecord? branch]) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => BranchFormScreen(repository: _repository, branch: branch),
      ),
    );
    if (saved == true) await _load();
  }

  Future<void> _view(BranchRecord branch) {
    return AppDialog.showDetails(
      context: context,
      title: branch.branchName,
      rows: [
        (label: 'Code', value: branch.branchCode),
        (label: 'City', value: branch.city ?? '—'),
        (label: 'Address', value: branch.addressLine1 ?? '—'),
        (label: 'Phone', value: branch.phoneNo ?? '—'),
        (label: 'Email', value: branch.email ?? '—'),
        (label: 'Manager', value: branch.managerName ?? '—'),
        (label: 'Head office', value: branch.isHeadOffice ? 'Yes' : 'No'),
        (label: 'Status', value: branch.isActive ? 'Active' : 'Inactive'),
      ],
    );
  }

  Future<void> _confirmDelete(BranchRecord branch) async {
    final confirmed = await AppDialog.show(
      context: context,
      title: 'Delete Branch?',
      message: 'Hide ${branch.branchName} from the list?\n\nThe record stays stored.',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      icon: Icons.delete_outline,
      iconColor: Colors.red,
    );
    if (!mounted || confirmed != true) return;
    try {
      await _repository.delete(branch.id);
      if (!mounted) return;
      AppSnackBar.success(context, '${branch.branchName} was deleted.');
      await _load();
    } on ApiException catch (error) {
      if (!mounted) return;
      AppSnackBar.error(context, error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F6FA),
      appBar: AppBar(
        elevation: 0,
        title: const Text('Branches', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Studios for this salon',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _repository.isApiBacked ? () => _openForm() : null,
                icon: const Icon(Icons.add_business_outlined),
                label: const Text('Add Branch'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _body(),
        ],
      ),
    );
  }

  Widget _body() {
    if (!_repository.isApiBacked) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 36),
        child: Text('Sign in to manage branches.', textAlign: TextAlign.center),
      );
    }
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_loadError != null) {
      return Column(
        children: [
          Text(_loadError!, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: _load, child: const Text('Retry')),
        ],
      );
    }
    if (_branches.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 36),
        child: Text('No branches yet.', textAlign: TextAlign.center),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: const WidgetStatePropertyAll(Color(0xffF7F8FC)),
          columns: const [
            DataColumn(label: Text('Code')),
            DataColumn(label: Text('Name')),
            DataColumn(label: Text('City')),
            DataColumn(label: Text('')),
          ],
          rows: [
            for (final branch in _branches)
              DataRow(
                cells: [
                  DataCell(Text(branch.branchCode)),
                  DataCell(Text(branch.branchName)),
                  DataCell(Text(branch.city ?? '')),
                  DataCell(
                    PopupMenuButton<String>(
                      key: ValueKey('branch-actions-${branch.id}'),
                      onSelected: (action) {
                        switch (action) {
                          case 'view':
                            _view(branch);
                          case 'edit':
                            _openForm(branch);
                          case 'delete':
                            _confirmDelete(branch);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'view', child: Text('View')),
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
