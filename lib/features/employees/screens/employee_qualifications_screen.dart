import 'package:flutter/material.dart';

import '../../../core/api/api_exception.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../data/qualification_repository.dart';
import '../models/employee_record.dart';

class EmployeeQualificationsScreen extends StatefulWidget {
  final EmployeeRecord employee;
  final QualificationRepository? repository;

  const EmployeeQualificationsScreen({super.key, required this.employee, this.repository});

  @override
  State<EmployeeQualificationsScreen> createState() => _EmployeeQualificationsScreenState();
}

class _EmployeeQualificationsScreenState extends State<EmployeeQualificationsScreen> {
  late final QualificationRepository _repository;
  List<QualificationRecord> _masters = const [];
  List<EmployeeQualificationRecord> _links = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? QualificationRepository();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final masters = await _repository.list();
      final links = await _repository.forEmployee(widget.employee.id);
      if (!mounted) return;
      setState(() {
        _masters = masters;
        _links = links;
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

  Future<void> _addMaster() async {
    final name = TextEditingController();
    final level = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Qualification'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(controller: name, labelText: 'Name'),
            const SizedBox(height: 12),
            AppTextField(controller: level, labelText: 'Level'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );
    if (saved != true || name.text.trim().isEmpty) {
      name.dispose();
      level.dispose();
      return;
    }
    try {
      await _repository.create(name: name.text, level: level.text);
      if (!mounted) return;
      await _load();
    } on ApiException catch (error) {
      if (!mounted) return;
      AppSnackBar.error(context, error.message);
    }
    name.dispose();
    level.dispose();
  }

  Future<void> _link(QualificationRecord master) async {
    final institution = TextEditingController();
    final year = TextEditingController();
    var visible = false;
    var status = 'Pending';
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: Text(master.name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(controller: institution, labelText: 'Awarding institution'),
              const SizedBox(height: 12),
              AppTextField(controller: year, labelText: 'Completion year', keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: status,
                decoration: const InputDecoration(labelText: 'Verification'),
                items: const [
                  DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                  DropdownMenuItem(value: 'Verified', child: Text('Verified')),
                  DropdownMenuItem(value: 'Rejected', child: Text('Rejected')),
                ],
                onChanged: (value) => setLocal(() => status = value ?? 'Pending'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Show to customers'),
                value: visible,
                onChanged: (value) => setLocal(() => visible = value),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
          ],
        ),
      ),
    );
    if (saved != true) {
      institution.dispose();
      year.dispose();
      return;
    }
    try {
      await _repository.saveLink(
        employeeId: widget.employee.id,
        qualificationId: master.id,
        institution: institution.text,
        year: int.tryParse(year.text.trim()),
        verificationStatus: status,
        isCustomerVisible: visible,
      );
      if (!mounted) return;
      await _load();
    } on ApiException catch (error) {
      if (!mounted) return;
      AppSnackBar.error(context, error.message);
    }
    institution.dispose();
    year.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F6FA),
      appBar: AppBar(
        title: Text('${widget.employee.fullName} qualifications'),
        actions: [
          IconButton(onPressed: _addMaster, icon: const Icon(Icons.add), tooltip: 'Add qualification'),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      OutlinedButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    const Text(
                      'Only qualifications marked verified are shown to customers as verified.',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    if (_links.isEmpty) const Text('No qualifications recorded for this stylist.'),
                    for (final link in _links)
                      Card(
                        child: ListTile(
                          title: Text(link.name),
                          subtitle: Text(
                            '${link.verificationStatus}'
                            '${link.institution == null ? '' : ' · ${link.institution}'}'
                            '${link.year == null ? '' : ' · ${link.year}'}'
                            '${link.isCustomerVisible ? ' · Customer visible' : ' · Hidden'}',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              try {
                                await _repository.removeLink(link.id);
                                await _load();
                              } on ApiException catch (error) {
                                if (!mounted) return;
                                AppSnackBar.error(context, error.message);
                              }
                            },
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    const Text('Assign a qualification', style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    for (final master in _masters.where((item) => item.isActive))
                      ListTile(
                        title: Text(master.name),
                        subtitle: Text(master.level ?? ''),
                        trailing: const Icon(Icons.add_link),
                        onTap: () => _link(master),
                      ),
                  ],
                ),
    );
  }
}
