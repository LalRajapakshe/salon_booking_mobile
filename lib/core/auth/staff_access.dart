import 'auth_session.dart';

/// Screen gates for the tenant-local roles. The server still enforces them.
class StaffAccess {
  const StaffAccess._();

  static bool seesNotificationQueue(AuthSession session) =>
      session.can('notifications.bookings.read') ||
      session.can('notifications.cancellations.read') ||
      session.can('notifications.confirmation.read');

  static bool seesFrontDesk(AuthSession session) => session.can('appointments.read');

  static bool canManageAppointments(AuthSession session) => session.can('appointments.manage');

  static bool seesEmployees(AuthSession session) => session.can('employees.read');

  static bool seesUsers(AuthSession session) =>
      session.can('users.read') || session.can('users.manage');

  static bool seesOwnAppointments(AuthSession session) => session.can('appointments.own.read');

  /// Official start and finish belong to the front desk or a supervisor.
  /// The unused employee id is kept so callers stay explicit about the line.
  static bool canProgressLine(AuthSession session, int? employeeId) {
    return session.can('appointments.lines.progress') && employeeId != null;
  }

  static bool canReadLineHistory(AuthSession session, int? employeeId) {
    if (session.can('appointments.read') || session.can('appointments.lines.progress')) {
      return true;
    }
    return session.employeeId != null &&
        session.employeeId == employeeId &&
        session.can('appointments.own.read');
  }

  static bool seesAppointmentBook(AuthSession session) => session.can('appointments.read');

  static bool seesBills(AuthSession session) =>
      session.can('bills.read') || session.can('bills.manage');

  static bool canManageBills(AuthSession session) => session.can('bills.manage');

  static bool canCollectPayments(AuthSession session) => session.can('payments.collect');

  static bool seesProducts(AuthSession session) =>
      session.can('products.read') || session.can('products.manage');

  static bool canManageProducts(AuthSession session) => session.can('products.manage');

  static bool seesTax(AuthSession session) =>
      session.can('tax.read') || session.can('tax.manage');

  static bool canManageTax(AuthSession session) => session.can('tax.manage');

  static bool seesRentals(AuthSession session) =>
      session.can('rentals.read') || session.can('rentals.manage') || session.can('rentals.issue');

  static bool canManageRentals(AuthSession session) => session.can('rentals.manage');

  static bool canIssueRentals(AuthSession session) => session.can('rentals.issue');
}
