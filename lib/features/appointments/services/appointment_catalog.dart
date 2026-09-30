import '../data/mock_appointment_data.dart';
import '../models/appointment.dart';
import '../models/salon_lookups.dart';

/// In-memory lookup for the appointment screens.
/// This does not call the API or the database.
class AppointmentCatalog {
  const AppointmentCatalog._();

  static List<Appointment> get appointments =>
      List<Appointment>.unmodifiable(mockAppointments);

  static List<BranchLookup> get branches =>
      List<BranchLookup>.unmodifiable(mockBranches);

  static List<CustomerLookup> customersForBranch(int branchId) {
    return mockCustomers.where((item) => item.branchId == branchId).toList();
  }

  static List<EmployeeLookup> employeesForBranch(int branchId) {
    return mockEmployees.where((item) => item.branchId == branchId).toList();
  }

  static List<ServiceLookup> servicesForBranch(int branchId) {
    return mockServices.where((item) => item.branchId == branchId).toList();
  }

  static BranchLookup branch(int branchId) {
    return mockBranches.firstWhere((item) => item.branchId == branchId);
  }

  static CustomerLookup customer(int customerId) {
    return mockCustomers.firstWhere((item) => item.customerId == customerId);
  }

  static EmployeeLookup employee(int employeeId) {
    return mockEmployees.firstWhere((item) => item.employeeId == employeeId);
  }

  static ServiceLookup service(int serviceId) {
    return mockServices.firstWhere((item) => item.serviceId == serviceId);
  }

  static String serviceSummary(Appointment appointment) {
    return appointment.appointmentServices
        .map((line) => service(line.serviceId).serviceName)
        .join(', ');
  }
}
