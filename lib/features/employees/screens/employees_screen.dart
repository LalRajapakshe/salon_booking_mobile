import 'package:flutter/material.dart';

import '../../../core/api/api_exception.dart';
import '../../services/data/service_repository.dart';
import '../data/employee_capability_repository.dart';
import '../data/employee_repository.dart';
import '../models/employee_record.dart';
import 'assign_employee_service_screen.dart';
import 'create_employee_screen.dart';

class EmployeesScreen extends StatefulWidget {
  final EmployeeRepository? repository;
  final ServiceRepository? services;
  final EmployeeCapabilityRepository? capabilities;

  const EmployeesScreen({
    super.key,
    this.repository,
    this.services,
    this.capabilities,
  });

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  final TextEditingController _searchController = TextEditingController();
  late final EmployeeRepository _repository;
  List<EmployeeRecord> _employees = const [];
  bool _loading = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? EmployeeRepository();
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
      final employees = await _repository.list();
      if (!mounted) return;
      setState(() {
        _employees = employees;
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<EmployeeRecord> get _visible {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _employees;
    return _employees.where((employee) {
      return employee.fullName.toLowerCase().contains(query) ||
          employee.employeeCode.toLowerCase().contains(query) ||
          employee.mobileNo.toLowerCase().contains(query) ||
          (employee.designation?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  Future<void> _openCreate() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateEmployeeScreen(repository: _repository),
      ),
    );
    if (saved == true && _repository.isApiBacked) await _load();
  }

  Future<void> _openAssign() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => AssignEmployeeServiceScreen(
          employees: _repository,
          services: widget.services,
          capabilities: widget.capabilities,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final employees = _visible;
    return Scaffold(
      backgroundColor: const Color(0xffF4F6FA),
      appBar: AppBar(
        elevation: 0,
        title: const Text('Employees', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Employees',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Manage staff records for this branch',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  OutlinedButton.icon(
                    onPressed: _openAssign,
                    icon: const Icon(Icons.design_services_outlined),
                    label: const Text('Assign Service'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _openCreate,
                    icon: const Icon(Icons.person_add_alt_1),
                    label: const Text('Add Employee'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search name, code, mobile, or designation',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          _buildBody(employees),
        ],
      ),
    );
  }

  Widget _buildBody(List<EmployeeRecord> employees) {
    if (!_repository.isApiBacked) {
      return const _Message(text: 'Sign in to manage employees.');
    }
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_loadError != null) {
      return _Message(
        text: _loadError!,
        action: OutlinedButton(onPressed: _load, child: const Text('Retry')),
      );
    }
    if (employees.isEmpty) {
      return const _Message(text: 'No employees yet.');
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
            DataColumn(label: Text('Mobile')),
            DataColumn(label: Text('Designation')),
          ],
          rows: [
            for (final employee in employees)
              DataRow(
                cells: [
                  DataCell(Text(employee.employeeCode)),
                  DataCell(Text(employee.fullName)),
                  DataCell(Text(employee.mobileNo)),
                  DataCell(Text(employee.designation ?? '')),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final String text;
  final Widget? action;

  const _Message({required this.text, this.action});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Column(
        children: [
          Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
          if (action != null) ...[const SizedBox(height: 12), action!],
        ],
      ),
    );
  }
}
