import 'package:flutter/material.dart';

import '../../../shared/utils/currency_formatter.dart';
import '../../../shared/widgets/app_dropdown.dart';
import '../../../shared/widgets/app_primary_button.dart';
import '../../../shared/widgets/app_secondary_button.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../models/appointment.dart';
import '../models/appointment_service_line.dart';
import '../models/appointment_status.dart';
import '../models/appointment_time.dart';
import '../models/salon_lookups.dart';
import '../services/appointment_catalog.dart';
import '../widgets/appointment_date_field.dart';
import '../widgets/selected_service_list.dart';

class CreateAppointmentScreen extends StatefulWidget {
  const CreateAppointmentScreen({super.key});

  @override
  State<CreateAppointmentScreen> createState() => _CreateAppointmentScreenState();
}

class _CreateAppointmentScreenState extends State<CreateAppointmentScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();

  int? _branchId;
  int? _customerId;
  int? _employeeId;
  DateTime? _appointmentDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  AppointmentStatus _status = AppointmentStatus.scheduled;
  int? _serviceToAdd;
  final List<AppointmentServiceLine> _services = [];
  String? _serviceError;
  bool _validateOnInteraction = false;

  static const double _formMaxWidth = 1040;
  static const double _twoColumnBreakpoint = 640;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<CustomerLookup> get _customers {
    final branchId = _branchId;
    if (branchId == null) return const [];
    return AppointmentCatalog.customersForBranch(branchId);
  }

  List<EmployeeLookup> get _employees {
    final branchId = _branchId;
    if (branchId == null) return const [];
    return AppointmentCatalog.employeesForBranch(branchId);
  }

  List<ServiceLookup> get _availableServices {
    final branchId = _branchId;
    if (branchId == null) return const [];
    final selected = _services.map((line) => line.serviceId).toSet();
    return AppointmentCatalog.servicesForBranch(branchId)
        .where((service) => !selected.contains(service.serviceId))
        .toList();
  }

  void _cancel() {
    Navigator.of(context).pop();
  }

  void _onBranchChanged(int? value) {
    setState(() {
      _branchId = value;
      _customerId = null;
      _employeeId = null;
      _serviceToAdd = null;
      _services.clear();
      _serviceError = null;
    });
  }

  void _addService() {
    final serviceId = _serviceToAdd;
    if (serviceId == null) return;
    if (_services.any((line) => line.serviceId == serviceId)) return;

    setState(() {
      _services.add(
        AppointmentServiceLine(
          appointmentServiceId: 0,
          appointmentId: 0,
          serviceId: serviceId,
        ),
      );
      _serviceToAdd = null;
      _serviceError = null;
    });
  }

  void _removeService(int serviceId) {
    setState(() {
      _services.removeWhere((line) => line.serviceId == serviceId);
    });
  }

  void _save() {
    final form = _formKey.currentState;
    final servicesMissing = _services.isEmpty;
    setState(() {
      _serviceError = servicesMissing ? 'Service is required' : null;
    });

    if (form == null || !form.validate() || servicesMissing) {
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

    final appointment = Appointment(
      appointmentId: 0,
      branchId: _branchId!,
      customerId: _customerId!,
      appointmentDate: _appointmentDate!,
      startTime: _startTime!,
      endTime: _endTime!,
      employeeId: _employeeId!,
      status: _status,
      appointmentServices: List<AppointmentServiceLine>.unmodifiable(_services),
    );

    final customer = AppointmentCatalog.customer(appointment.customerId);
    AppSnackBar.success(context, '${customer.fullName} was saved.');
    Navigator.of(context).pop();
  }

  String? _requiredSelection(Object? value, String label) {
    if (value == null) return '$label is required';
    return null;
  }

  String? _dateValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Appointment date is required';
    }
    return null;
  }

  String? _endTimeValidator(TimeOfDay? value) {
    if (value == null) return 'End time is required';
    final start = _startTime;
    if (start != null && appointmentMinutes(value) <= appointmentMinutes(start)) {
      return 'End time must be after start time';
    }
    return null;
  }

  void _revalidateIfNeeded() {
    if (!_validateOnInteraction) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _formKey.currentState?.validate();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F6FA),
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Create Appointment',
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
                      _buildAppointmentCard(),
                      const SizedBox(height: 24),
                      _buildServicesCard(),
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
          'Create Appointment',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 6),
        Text(
          'Record the booking, then add the services it includes',
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
      ],
    );
  }

  Widget _sectionCard({required Widget child}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: child,
      ),
    );
  }

  Widget _sectionHeading(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(color: Colors.grey, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildAppointmentCard() {
    return _sectionCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final twoColumns = constraints.maxWidth >= _twoColumnBreakpoint;
          final branchReady = _branchId != null;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _sectionHeading(
                'Appointment',
                'Branch, customer, employee, date, times, and status',
              ),
              const SizedBox(height: 16),
              _pair(
                twoColumns: twoColumns,
                first: AppDropdown<int>(
                  labelText: 'Branch',
                  hintText: 'Select branch',
                  value: _branchId,
                  items: [
                    for (final branch in AppointmentCatalog.branches)
                      DropdownMenuItem<int>(
                        value: branch.branchId,
                        child: Text(branch.label, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: _onBranchChanged,
                  validator: (value) => _requiredSelection(value, 'Branch'),
                ),
                second: AppDropdown<int>(
                  labelText: 'Customer',
                  hintText: branchReady ? 'Select customer' : 'Select a branch first',
                  value: _customerId,
                  enabled: branchReady,
                  items: [
                    for (final customer in _customers)
                      DropdownMenuItem<int>(
                        value: customer.customerId,
                        child: Text(customer.label, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (value) => setState(() => _customerId = value),
                  validator: (value) => _requiredSelection(value, 'Customer'),
                ),
              ),
              const SizedBox(height: 16),
              _pair(
                twoColumns: twoColumns,
                first: AppDropdown<int>(
                  labelText: 'Employee',
                  hintText: branchReady ? 'Select employee' : 'Select a branch first',
                  value: _employeeId,
                  enabled: branchReady,
                  items: [
                    for (final employee in _employees)
                      DropdownMenuItem<int>(
                        value: employee.employeeId,
                        child: Text(employee.label, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (value) => setState(() => _employeeId = value),
                  validator: (value) => _requiredSelection(value, 'Employee'),
                ),
                second: AppDropdown<AppointmentStatus>(
                  labelText: 'Status',
                  value: _status,
                  items: [
                    for (final status in AppointmentStatus.values)
                      DropdownMenuItem<AppointmentStatus>(
                        value: status,
                        child: Text(status.label),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _status = value);
                  },
                ),
              ),
              const SizedBox(height: 16),
              AppointmentDateField(
                value: _appointmentDate,
                onChanged: (date) => setState(() => _appointmentDate = date),
                validator: _dateValidator,
              ),
              const SizedBox(height: 16),
              _pair(
                twoColumns: twoColumns,
                first: _timeDropdown(
                  label: 'Start Time',
                  hint: 'Select start time',
                  value: _startTime,
                  onChanged: (value) {
                    setState(() => _startTime = value);
                    _revalidateIfNeeded();
                  },
                  validator: (value) => _requiredSelection(value, 'Start time'),
                ),
                second: _timeDropdown(
                  label: 'End Time',
                  hint: 'Select end time',
                  value: _endTime,
                  onChanged: (value) => setState(() => _endTime = value),
                  validator: _endTimeValidator,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildServicesCard() {
    return _sectionCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final twoColumns = constraints.maxWidth >= _twoColumnBreakpoint;
          final branchReady = _branchId != null;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildServices(twoColumns, branchReady),
              const SizedBox(height: 8),
              _buildActions(constraints.maxWidth),
            ],
          );
        },
      ),
    );
  }

  Widget _timeDropdown({
    required String label,
    required String hint,
    required TimeOfDay? value,
    required ValueChanged<TimeOfDay?> onChanged,
    required FormFieldValidator<TimeOfDay> validator,
  }) {
    return AppDropdown<TimeOfDay>(
      labelText: label,
      hintText: hint,
      value: value,
      items: [
        for (final time in appointmentTimeOptions())
          DropdownMenuItem<TimeOfDay>(
            value: time,
            child: Text(formatAppointmentTime(time)),
          ),
      ],
      onChanged: onChanged,
      validator: validator,
    );
  }

  Widget _buildServices(bool twoColumns, bool branchReady) {
    final addButton = OutlinedButton.icon(
      onPressed: _serviceToAdd == null ? null : _addService,
      icon: const Icon(Icons.add),
      label: const Text('Add'),
    );

    final serviceDropdown = AppDropdown<int>(
      labelText: 'Service',
      hintText: branchReady ? 'Select service' : 'Select a branch first',
      value: _serviceToAdd,
      enabled: branchReady && _availableServices.isNotEmpty,
      items: [
        for (final service in _availableServices)
          DropdownMenuItem<int>(
            value: service.serviceId,
            child: Text(
              '${service.serviceName} · ${service.durationMinutes} min · ${CurrencyFormatter.formatWithSymbol(service.price)}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: (value) => setState(() => _serviceToAdd = value),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionHeading(
          'Appointment Services',
          'Add every service included in this appointment',
        ),
        const SizedBox(height: 12),
        if (twoColumns)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: serviceDropdown),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: addButton,
              ),
            ],
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              serviceDropdown,
              const SizedBox(height: 12),
              addButton,
            ],
          ),
        SelectedServiceList(
          lines: _services,
          onRemove: _removeService,
        ),
        if (_serviceError != null) ...[
          const SizedBox(height: 8),
          Text(
            _serviceError!,
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontSize: 12,
            ),
          ),
        ],
      ],
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
