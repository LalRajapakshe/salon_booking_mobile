import '../../../core/api/api_exception.dart';
import '../../../core/auth/auth_session.dart';
import '../../../shared/utils/currency_formatter.dart';
import '../../appointments/data/appointment_repository.dart';
import '../../appointments/models/appointment.dart';
import '../../appointments/models/appointment_service_line.dart';
import '../../appointments/models/appointment_status.dart';
import '../../appointments/services/appointment_catalog.dart';
import '../../customers/data/customer_repository.dart';
import '../../employees/data/employee_repository.dart';
import '../../services/data/service_repository.dart';
import '../models/reception_visit.dart';

class ReceptionRepository {
  ReceptionRepository({
    AppointmentRepository? appointments,
    CustomerRepository? customers,
    EmployeeRepository? employees,
    ServiceRepository? services,
    AuthSession? session,
    DateTime Function()? clock,
  })  : _appointments = appointments ?? AppointmentRepository(),
        _customers = customers ?? CustomerRepository(),
        _employees = employees ?? EmployeeRepository(),
        _services = services ?? ServiceRepository(),
        _session = session ?? AuthSession.instance,
        _clock = clock ?? DateTime.now;

  final AppointmentRepository _appointments;
  final CustomerRepository _customers;
  final EmployeeRepository _employees;
  final ServiceRepository _services;
  final AuthSession _session;
  final DateTime Function() _clock;

  bool get isApiBacked => _session.isSignedIn;

  AppointmentRepository get appointments => _appointments;

  CustomerRepository get customers => _customers;

  /// Today's appointments for the signed-in branch. A signed-out session
  /// shows the sample catalog day instead of inventing live records.
  Future<ReceptionDay> load({DateTime? date}) async {
    if (!_session.isSignedIn) return _sampleDay();

    final day = _dateOnly(date ?? _clock());
    final appointments = await _appointments.list(date: day);
    final names = await _lookups();
    return ReceptionDay(
      date: day,
      visits: [
        for (final appointment in appointments)
          _fromAppointment(
            appointment,
            customerName: names.customers[appointment.customerId] ?? 'Customer ${appointment.customerId}',
            mobile: names.mobiles[appointment.customerId] ?? '',
            employeeName: _employeeName(appointment, names.employees),
            serviceName: (line) => names.services[line.serviceId] ?? 'Service ${line.serviceId}',
          ),
      ],
    );
  }

  /// `POST /api/Appointments/{id}/status` with Confirmed.
  Future<void> confirm(int appointmentId) async {
    if (!_session.isSignedIn) {
      throw const ApiException('Sign in to confirm an appointment.');
    }
    await _appointments.changeStatus(
      appointmentId: appointmentId,
      status: AppointmentStatus.confirmed,
    );
  }

  /// `POST /api/Appointments/{id}/status` with CheckedIn. The clock time is not stored.
  Future<void> checkIn(int appointmentId) async {
    if (!_session.isSignedIn) {
      throw const ApiException('Sign in to check in a customer.');
    }
    await _appointments.changeStatus(
      appointmentId: appointmentId,
      status: AppointmentStatus.checkedIn,
    );
  }

  ReceptionDay _sampleDay() {
    final all = AppointmentCatalog.appointments;
    if (all.isEmpty) {
      return ReceptionDay(date: _dateOnly(_clock()), visits: const []);
    }
    final latest = all.map((item) => item.appointmentDate).reduce(
          (left, right) => left.isAfter(right) ? left : right,
        );
    final day = _dateOnly(latest);
    return ReceptionDay(
      date: day,
      sampleDay: true,
      visits: [
        for (final appointment in all)
          if (_dateOnly(appointment.appointmentDate) == day)
            _fromAppointment(
              appointment,
              customerName: _catalogCustomer(appointment.customerId),
              mobile: _catalogMobile(appointment.customerId),
              employeeName: appointment.employeeName ??
                  (appointment.employeeId <= 0
                      ? 'Unassigned'
                      : _catalogEmployee(appointment.employeeId)),
              serviceName: (line) {
                try {
                  return AppointmentCatalog.service(line.serviceId).serviceName;
                } catch (_) {
                  return line.serviceName ?? 'Service ${line.serviceId}';
                }
              },
            ),
      ],
    );
  }

  Future<({Map<int, String> customers, Map<int, String> mobiles, Map<int, String> employees, Map<int, String> services})>
      _lookups() async {
    final customers = <int, String>{};
    final mobiles = <int, String>{};
    final employees = <int, String>{};
    final services = <int, String>{};
    try {
      for (final customer in await _customers.list()) {
        customers[customer.id] = customer.fullName;
        mobiles[customer.id] = customer.mobileNumber;
      }
    } on ApiException {
      // Rows still show the customer id.
    }
    try {
      for (final employee in await _employees.list()) {
        employees[employee.id] = employee.fullName;
      }
    } on ApiException {
      // Rows still show the employee id.
    }
    try {
      for (final service in await _services.list()) {
        services[service.serviceId] = service.serviceName;
      }
    } on ApiException {
      // Rows still show the service id.
    }
    return (customers: customers, mobiles: mobiles, employees: employees, services: services);
  }

  ReceptionVisit _fromAppointment(
    Appointment appointment, {
    required String customerName,
    required String mobile,
    required String employeeName,
    required String Function(AppointmentServiceLine line) serviceName,
  }) {
    final lines = appointment.appointmentServices.where((line) => !line.isCancelled).toList();
    final labels = [
      for (final line in lines)
        _serviceLabel(serviceName(line), line.durationMinutes),
    ];
    double? total;
    for (final line in lines) {
      final price = line.unitPrice;
      if (price == null) continue;
      total = (total ?? 0) + price;
    }
    return ReceptionVisit(
      appointmentId: appointment.appointmentId,
      customerId: appointment.customerId,
      customerName: customerName,
      mobile: mobile,
      date: appointment.appointmentDate,
      start: appointment.hasScheduledTime ? appointment.startTime : null,
      services: labels.isEmpty ? 'No services' : labels.join(', '),
      employee: employeeName,
      status: appointment.status,
      priceLabel: total == null ? null : CurrencyFormatter.formatWithSymbol(total),
      notes: appointment.notes,
    );
  }

  String _employeeName(Appointment appointment, Map<int, String> names) {
    if (appointment.employeeName != null && appointment.employeeName!.isNotEmpty) {
      return appointment.employeeName!;
    }
    if (appointment.employeeId <= 0) return 'Unassigned';
    return names[appointment.employeeId] ?? 'Employee ${appointment.employeeId}';
  }

  String _serviceLabel(String name, int? minutes) {
    if (minutes == null || minutes <= 0) return name;
    return '$name (${minutes}m)';
  }

  String _catalogCustomer(int id) {
    try {
      return AppointmentCatalog.customer(id).fullName;
    } catch (_) {
      return 'Customer $id';
    }
  }

  String _catalogMobile(int id) {
    try {
      return AppointmentCatalog.customer(id).mobileNo;
    } catch (_) {
      return '';
    }
  }

  String _catalogEmployee(int id) {
    try {
      return AppointmentCatalog.employee(id).fullName;
    } catch (_) {
      return 'Employee $id';
    }
  }

  static DateTime _dateOnly(DateTime value) => DateTime(value.year, value.month, value.day);
}
