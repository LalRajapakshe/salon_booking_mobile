import 'package:flutter/material.dart';

import '../../../core/api/api_exception.dart';
import '../../../shared/widgets/app_dropdown.dart';
import '../../../shared/widgets/app_primary_button.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../services/data/service_repository.dart';
import '../../services/models/service_management_models.dart';
import '../data/employee_capability_repository.dart';
import '../data/employee_repository.dart';
import '../models/employee_capability_record.dart';
import '../models/employee_record.dart';

class AssignEmployeeServiceScreen extends StatefulWidget {
  final EmployeeRepository? employees;
  final ServiceRepository? services;
  final EmployeeCapabilityRepository? capabilities;

  const AssignEmployeeServiceScreen({
    super.key,
    this.employees,
    this.services,
    this.capabilities,
  });

  @override
  State<AssignEmployeeServiceScreen> createState() => _AssignEmployeeServiceScreenState();
}

class _AssignEmployeeServiceScreenState extends State<AssignEmployeeServiceScreen> {
  late final EmployeeRepository _employees;
  late final ServiceRepository _services;
  late final EmployeeCapabilityRepository _capabilities;

  List<EmployeeRecord> _employeeOptions = const [];
  List<SalonService> _serviceOptions = const [];
  List<EmployeeCapabilityRecord> _links = const [];
  int? _employeeId;
  int? _serviceId;
  bool _loading = false;
  bool _saving = false;
  String? _loadError;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _employees = widget.employees ?? EmployeeRepository();
    _services = widget.services ?? ServiceRepository();
    _capabilities = widget.capabilities ?? EmployeeCapabilityRepository();
    if (_capabilities.isApiBacked) {
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
      final employees = await _employees.list();
      final services = await _services.list();
      final links = await _capabilities.list();
      if (!mounted) return;
      setState(() {
        _employeeOptions = employees;
        _serviceOptions = services;
        _links = links;
        _employeeId = _kept(_employeeId, employees.map((item) => item.id));
        _serviceId = _kept(_serviceId, services.map((item) => item.serviceId));
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

  int? _kept(int? selected, Iterable<int> ids) {
    if (selected == null || !ids.contains(selected)) return null;
    return selected;
  }

  Future<void> _save() async {
    final employeeId = _employeeId;
    final serviceId = _serviceId;
    if (employeeId == null || serviceId == null) {
      setState(() => _saveError = 'Choose an employee and a service.');
      return;
    }

    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      await _capabilities.assign(employeeId: employeeId, serviceId: serviceId);
      if (!mounted) return;
      final employeeName = _employeeName(employeeId);
      final serviceName = _serviceName(serviceId);
      AppSnackBar.success(context, '$serviceName was assigned to $employeeName.');
      setState(() {
        _saving = false;
        _employeeId = null;
        _serviceId = null;
      });
      await _load();
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveError = error.message;
      });
    }
  }

  String _employeeName(int id) {
    for (final employee in _employeeOptions) {
      if (employee.id == id) return employee.fullName;
    }
    return 'Employee $id';
  }

  String _serviceName(int id) {
    for (final service in _serviceOptions) {
      if (service.serviceId == id) return service.serviceName;
    }
    return 'Service $id';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F6FA),
      appBar: AppBar(
        elevation: 0,
        title: const Text('Assign Service', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Assign Service',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Choose a saved employee and a saved service they can perform. Working hours stay separate.',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 24),
          _buildBody(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (!_capabilities.isApiBacked) {
      return const _Message(text: 'Sign in to assign services.');
    }
    if (_loading && _employeeOptions.isEmpty && _links.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_loadError != null && _employeeOptions.isEmpty && _links.isEmpty) {
      return _Message(
        text: _loadError!,
        action: OutlinedButton(onPressed: _load, child: const Text('Retry')),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_loadError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(_loadError!, style: const TextStyle(color: Colors.red)),
          ),
        if (_employeeOptions.isEmpty || _serviceOptions.isEmpty)
          _Message(
            text: _employeeOptions.isEmpty
                ? 'Save an employee before assigning a service.'
                : 'Save a service before assigning it.',
          )
        else
          _form(),
        const SizedBox(height: 24),
        _linksTable(),
      ],
    );
  }

  Widget _form() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppDropdown<int>(
          labelText: 'Employee',
          value: _employeeId,
          items: [
            for (final employee in _employeeOptions)
              DropdownMenuItem(
                value: employee.id,
                child: Text('${employee.fullName} · ${employee.employeeCode}'),
              ),
          ],
          onChanged: _saving ? null : (value) => setState(() => _employeeId = value),
        ),
        const SizedBox(height: 16),
        AppDropdown<int>(
          labelText: 'Service',
          value: _serviceId,
          items: [
            for (final service in _serviceOptions)
              DropdownMenuItem(
                value: service.serviceId,
                child: Text(service.serviceName),
              ),
          ],
          onChanged: _saving ? null : (value) => setState(() => _serviceId = value),
        ),
        if (_saveError != null) ...[
          const SizedBox(height: 12),
          Text(_saveError!, style: const TextStyle(color: Colors.red)),
        ],
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: AppPrimaryButton(
            text: 'Save',
            width: 160,
            isLoading: _saving,
            onPressed: _saving ? null : _save,
          ),
        ),
      ],
    );
  }

  Widget _linksTable() {
    if (_links.isEmpty) {
      return const _Message(text: 'No services are assigned yet.');
    }
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: const WidgetStatePropertyAll(Color(0xffF7F8FC)),
          columns: const [
            DataColumn(label: Text('Employee')),
            DataColumn(label: Text('Service')),
            DataColumn(label: Text('Active')),
          ],
          rows: [
            for (final link in _links)
              DataRow(
                cells: [
                  DataCell(Text(_employeeName(link.employeeId))),
                  DataCell(Text(_serviceName(link.serviceId))),
                  DataCell(Text(link.isActive ? 'Yes' : 'No')),
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
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
          if (action != null) ...[const SizedBox(height: 12), action!],
        ],
      ),
    );
  }
}
