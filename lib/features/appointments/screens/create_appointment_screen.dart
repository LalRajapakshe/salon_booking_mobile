import 'package:flutter/material.dart';

import '../../../core/api/api_exception.dart';
import '../../../shared/utils/currency_formatter.dart';
import '../../../shared/widgets/app_dropdown.dart';
import '../../../shared/widgets/app_primary_button.dart';
import '../../../shared/widgets/app_secondary_button.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../customers/data/customer_repository.dart';
import '../../services/data/service_repository.dart';
import '../data/appointment_repository.dart';
import '../data/availability_repository.dart';
import '../models/appointment_service_draft.dart';
import '../models/appointment_service_line.dart';
import '../models/appointment_status.dart';
import '../models/employee_availability.dart';
import '../models/salon_lookups.dart';
import '../services/appointment_catalog.dart';
import '../widgets/appointment_date_field.dart';
import '../widgets/selected_service_list.dart';

class CreateAppointmentScreen extends StatefulWidget {
  const CreateAppointmentScreen({
    super.key,
    this.repository,
    this.availabilityRepository,
    this.customers,
    this.services,
    this.liveLookups = false,
  });

  final AppointmentRepository? repository;
  final AvailabilityRepository? availabilityRepository;
  final CustomerRepository? customers;
  final ServiceRepository? services;

  /// Uses customers and services stored for the signed-in branch.
  final bool liveLookups;

  @override
  State<CreateAppointmentScreen> createState() => _CreateAppointmentScreenState();
}

class _CreateAppointmentScreenState extends State<CreateAppointmentScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();

  int? _customerId;
  DateTime? _appointmentDate;
  AppointmentStatus _status = AppointmentStatus.scheduled;
  int? _serviceToAdd;
  final List<AppointmentServiceDraft> _services = [];
  String? _serviceError;
  String? _saveError;
  bool _validateOnInteraction = false;
  bool _saving = false;
  int? _createdAppointmentId;
  final Map<int, ServiceLineAvailability> _availability = {};
  late final AppointmentRepository _repository = widget.repository ?? AppointmentRepository();
  late final AvailabilityRepository _availabilityRepository =
      widget.availabilityRepository ?? AvailabilityRepository();
  late final CustomerRepository _customersRepo = widget.customers ?? CustomerRepository();
  late final ServiceRepository _servicesRepo = widget.services ?? ServiceRepository();
  List<CustomerLookup> _apiCustomers = const [];
  List<ServiceLookup> _apiServices = const [];
  bool _loadingLookups = false;
  String? _lookupError;

  bool get _structureLocked => _saving || _createdAppointmentId != null;

  static const double _formMaxWidth = 1040;
  static const double _twoColumnBreakpoint = 640;

  @override
  void initState() {
    super.initState();
    if (widget.liveLookups) {
      _loadingLookups = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadLookups();
      });
    }
  }

  Future<void> _loadLookups() async {
    setState(() {
      _loadingLookups = true;
      _lookupError = null;
    });
    try {
      final customers = await _customersRepo.list();
      final services = await _servicesRepo.list();
      if (!mounted) return;
      setState(() {
        _apiCustomers = [
          for (final customer in customers)
            CustomerLookup(
              customerId: customer.id,
              customerCode: customer.customerCode,
              firstName: customer.firstName,
              lastName: customer.lastName,
              mobileNo: customer.mobileNumber,
              branchId: 0,
            ),
        ];
        _apiServices = [
          for (final service in services)
            ServiceLookup(
              serviceId: service.serviceId,
              serviceCode: service.serviceCode,
              serviceName: service.serviceName,
              durationMinutes: service.durationMinutes,
              price: service.price,
              branchId: service.branchId,
            ),
        ];
        _loadingLookups = false;
        if (_customerId != null &&
            !_apiCustomers.any((item) => item.customerId == _customerId)) {
          _customerId = null;
        }
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingLookups = false;
        _lookupError = error.message;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<CustomerLookup> get _customers =>
      widget.liveLookups ? _apiCustomers : AppointmentCatalog.customers;

  List<ServiceLookup> get _serviceChoices =>
      widget.liveLookups ? _apiServices : AppointmentCatalog.services;

  List<ServiceLookup> get _availableServices {
    final selected = _services.map((line) => line.serviceId).toSet();
    return _serviceChoices.where((service) => !selected.contains(service.serviceId)).toList();
  }

  ServiceLookup _serviceById(int serviceId) {
    for (final service in _serviceChoices) {
      if (service.serviceId == serviceId) return service;
    }
    return ServiceLookup(
      serviceId: serviceId,
      serviceCode: '',
      serviceName: 'Service $serviceId',
      durationMinutes: 0,
      price: 0,
      branchId: 0,
    );
  }

  void _cancel() {
    Navigator.of(context).pop();
  }

  void _addService() {
    if (_structureLocked) return;
    final serviceId = _serviceToAdd;
    if (serviceId == null) return;
    if (_services.any((line) => line.serviceId == serviceId)) return;

    setState(() {
      _services.add(AppointmentServiceDraft(serviceId: serviceId));
      _serviceToAdd = null;
      _serviceError = null;
    });
  }

  void _removeService(int serviceId) {
    if (_structureLocked) return;
    setState(() {
      _services.removeWhere((line) => line.serviceId == serviceId);
      _availability.remove(serviceId);
    });
  }

  Future<void> _findAvailability(int serviceId) async {
    final date = _appointmentDate;
    if (date == null) {
      setState(() {
        _availability[serviceId] = const ServiceLineAvailability(
          error: 'Appointment date is required',
        );
      });
      return;
    }

    if (!_availabilityRepository.isApiBacked) {
      setState(() {
        _availability[serviceId] = const ServiceLineAvailability(
          error: 'Sign in is required.',
        );
      });
      return;
    }

    setState(() {
      _availability[serviceId] = const ServiceLineAvailability(loading: true);
    });

    try {
      final options = await _availabilityRepository.find(serviceId: serviceId, date: date);
      if (!mounted) return;
      setState(() {
        _availability[serviceId] = ServiceLineAvailability(loaded: true, options: options);
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _availability[serviceId] = ServiceLineAvailability(error: error.message);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _availability[serviceId] = const ServiceLineAvailability(
          error: 'Availability could not be loaded.',
        );
      });
    }
  }

  void _selectSlot(int serviceId, EmployeeAvailability employee, AvailabilitySlot slot) {
    _updateService(
      serviceId,
      (line) => line.copyWith(
        employeeId: employee.employeeId,
        employeeName: employee.employeeName,
        startTime: TimeOfDay.fromDateTime(slot.startTime),
        endTime: TimeOfDay.fromDateTime(slot.endTime),
        scheduleSaved: false,
      ),
    );
  }

  void _clearSchedule(int serviceId) {
    _updateService(
      serviceId,
      (line) => line.copyWith(
        employeeId: null,
        employeeName: null,
        startTime: null,
        endTime: null,
      ),
    );
  }

  void _updateService(int serviceId, AppointmentServiceDraft Function(AppointmentServiceDraft line) update) {
    if (_saving) return;
    setState(() {
      final index = _services.indexWhere((line) => line.serviceId == serviceId);
      if (index < 0) return;
      _services[index] = update(_services[index]);
    });
    _revalidateIfNeeded();
  }

  Future<void> _scheduleLine(int index) async {
    final line = _services[index];
    final rowVersion = line.rowVersion;
    final lineId = line.appointmentServiceId;
    final employeeId = line.employeeId;
    final start = line.startTime;
    final end = line.endTime;
    final date = _appointmentDate;
    if (lineId == null ||
        rowVersion == null ||
        rowVersion.isEmpty ||
        employeeId == null ||
        start == null ||
        end == null ||
        date == null) {
      throw ApiException('${_serviceName(line.serviceId)} is missing its row version.');
    }

    try {
      final scheduled = await _repository.scheduleLine(
        appointmentId: _createdAppointmentId!,
        appointmentServiceId: lineId,
        employeeId: employeeId,
        startTime: DateTime(date.year, date.month, date.day, start.hour, start.minute),
        endTime: DateTime(date.year, date.month, date.day, end.hour, end.minute),
        rowVersion: rowVersion,
      );
      _services[index] = line.copyWith(
        rowVersion: scheduled.rowVersion,
        durationMinutes: scheduled.durationMinutes,
        unitPrice: scheduled.unitPrice,
        scheduleSaved: true,
      );
    } on ApiException catch (error) {
      if (_isConcurrency(error)) {
        await _refreshLineVersion(index);
      }
      throw ApiException('${_serviceName(line.serviceId)}: ${error.message}', statusCode: error.statusCode);
    }
  }

  Future<void> _refreshLineVersion(int index) async {
    final appointmentId = _createdAppointmentId;
    final line = _services[index];
    final lineId = line.appointmentServiceId;
    if (appointmentId == null || lineId == null) return;
    try {
      final appointment = await _repository.get(appointmentId);
      AppointmentServiceLine? serverLine;
      for (final item in appointment.appointmentServices) {
        if (item.appointmentServiceId == lineId) {
          serverLine = item;
          break;
        }
      }
      final version = serverLine?.rowVersion;
      if (version == null || version.isEmpty) return;
      _services[index] = _services[index].copyWith(
        rowVersion: version,
        durationMinutes: serverLine?.durationMinutes,
        unitPrice: serverLine?.unitPrice,
        scheduleSaved: serverLine?.isFullyScheduled ?? false,
      );
    } on ApiException {
      return;
    }
  }

  bool _isConcurrency(ApiException error) {
    return error.statusCode == 409 && error.message.contains('changed by someone else');
  }

  String _serviceName(int serviceId) {
    if (widget.liveLookups) return _serviceById(serviceId).serviceName;
    try {
      return AppointmentCatalog.service(serviceId).serviceName;
    } catch (_) {
      return 'Service $serviceId';
    }
  }

  Future<void> _save() async {
    final form = _formKey.currentState;
    final servicesMissing = _createdAppointmentId == null && _services.isEmpty;
    setState(() {
      _serviceError = servicesMissing ? 'Service is required' : null;
    });

    if (_createdAppointmentId == null &&
        (form == null || !form.validate() || servicesMissing)) {
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

    if (widget.liveLookups && (_loadingLookups || _lookupError != null)) return;

    if (!_repository.isApiBacked) {
      final customer = AppointmentCatalog.customer(_customerId!);
      AppSnackBar.success(context, '${customer.fullName} was saved.');
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _saving = true;
      _saveError = null;
    });

    var phase = 'create';
    try {
      if (_createdAppointmentId == null) {
        final created = await _repository.create(
          customerId: _customerId!,
          appointmentDate: _appointmentDate!,
          status: _status,
        );
        _createdAppointmentId = created.appointmentId;
      }

      phase = 'lines';
      for (var index = 0; index < _services.length; index++) {
        final line = _services[index];
        if (line.appointmentServiceId != null) continue;
        final createdLine = await _repository.addService(
          appointmentId: _createdAppointmentId!,
          serviceId: line.serviceId,
        );
        _services[index] = line.copyWith(
          appointmentServiceId: createdLine.appointmentServiceId,
          rowVersion: createdLine.rowVersion,
          durationMinutes: createdLine.durationMinutes,
          unitPrice: createdLine.unitPrice,
        );
      }

      phase = 'schedule';
      for (var index = 0; index < _services.length; index++) {
        final line = _services[index];
        if (!line.hasSchedule || line.scheduleSaved) continue;
        await _scheduleLine(index);
      }

      phase = 'refresh';
      if (_services.any((line) => line.scheduleSaved)) {
        await _repository.get(_createdAppointmentId!);
      }
    } on ApiException catch (error) {
      if (!mounted) return;
      final created = _createdAppointmentId != null;
      setState(() {
        _saving = false;
        _saveError = switch (phase) {
          'schedule' => '${error.message} Save again to retry the service that was not scheduled.',
          'refresh' => '${error.message} Save again to reload the appointment.',
          _ when created =>
            '${error.message} The appointment was created. Save again to add the remaining services.',
          _ => error.message,
        };
      });
      return;
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveError = 'The appointment could not be saved.';
      });
      return;
    }

    if (!mounted) return;
    AppSnackBar.success(context, '${_customerName(_customerId!)} was saved.');
    Navigator.of(context).pop(true);
  }

  String _customerName(int customerId) {
    for (final customer in _customers) {
      if (customer.customerId == customerId) return customer.fullName;
    }
    if (widget.liveLookups) return 'Customer $customerId';
    try {
      return AppointmentCatalog.customer(customerId).fullName;
    } catch (_) {
      return 'Customer $customerId';
    }
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

          if (widget.liveLookups && _loadingLookups) {
            return const Center(child: CircularProgressIndicator());
          }
          if (widget.liveLookups && _lookupError != null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_lookupError!, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  OutlinedButton(onPressed: _loadLookups, child: const Text('Retry')),
                ],
              ),
            );
          }
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
          'Record the customer and date, then add each service',
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

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _sectionHeading(
                'Appointment Details',
                'Customer, date, and status',
              ),
              const SizedBox(height: 16),
              _pair(
                twoColumns: twoColumns,
                first: AppDropdown<int>(
                  labelText: 'Customer',
                  hintText: 'Select customer',
                  value: _customerId,
                  items: [
                    for (final customer in _customers)
                      DropdownMenuItem<int>(
                        value: customer.customerId,
                        child: Text(customer.label, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (value) {
                    if (_structureLocked) return;
                    setState(() => _customerId = value);
                  },
                  validator: (value) => _requiredSelection(value, 'Customer'),
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
                    if (_structureLocked || value == null) return;
                    setState(() => _status = value);
                  },
                ),
              ),
              const SizedBox(height: 16),
              AppointmentDateField(
                value: _appointmentDate,
                onChanged: (date) {
                  if (_structureLocked) return;
                  setState(() {
                    _appointmentDate = date;
                    _availability.clear();
                    for (var index = 0; index < _services.length; index++) {
                      _services[index] = _services[index].copyWith(
                        employeeId: null,
                        employeeName: null,
                        startTime: null,
                        endTime: null,
                      );
                    }
                  });
                },
                validator: _dateValidator,
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

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildServices(twoColumns),
              const SizedBox(height: 8),
              _buildActions(constraints.maxWidth),
            ],
          );
        },
      ),
    );
  }

  Widget _buildServices(bool twoColumns) {
    final addButton = OutlinedButton.icon(
      onPressed: _structureLocked || _serviceToAdd == null ? null : _addService,
      icon: const Icon(Icons.add),
      label: const Text('Add'),
    );

    final serviceDropdown = AppDropdown<int>(
      labelText: 'Service',
      hintText: 'Select service',
      value: _serviceToAdd,
      enabled: _availableServices.isNotEmpty,
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
      onChanged: (value) {
        if (_structureLocked) return;
        setState(() => _serviceToAdd = value);
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionHeading(
          'Services',
          'Each service has its own stylist, duration, and time',
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
          availability: _availability,
          enabled: !_saving,
          onRemove: _removeService,
          onFindAvailability: _findAvailability,
          onSelectSlot: _selectSlot,
          onClearSchedule: _clearSchedule,
          serviceLookup: widget.liveLookups ? _serviceById : null,
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
        if (_saveError != null) ...[
          const SizedBox(height: 8),
          Text(
            _saveError!,
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontSize: 13,
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
      onPressed: _saving ? null : _cancel,
    );
    final save = AppPrimaryButton(
      text: 'Save',
      icon: Icons.check,
      width: maxWidth < 520 ? double.infinity : 160,
      isLoading: _saving,
      onPressed: _saving ? null : _save,
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
