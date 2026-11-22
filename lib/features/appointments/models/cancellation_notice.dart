class CancellationNotice {
  final String notificationType;
  final int appointmentId;
  final String customerName;
  final List<String> serviceNames;
  final String serviceName;
  final DateTime appointmentDate;
  final DateTime? appointmentTime;
  final int branchId;
  final String branchName;
  final DateTime? requestedAt;
  final String requestState;
  final String? preferredStylistName;
  final String allocationState;

  const CancellationNotice({
    required this.notificationType,
    required this.appointmentId,
    required this.customerName,
    required this.serviceNames,
    required this.serviceName,
    required this.appointmentDate,
    required this.appointmentTime,
    required this.branchId,
    required this.branchName,
    required this.requestedAt,
    required this.requestState,
    this.preferredStylistName,
    this.allocationState = '',
  });

  bool get isCancellation => notificationType == 'CancellationRequest';

  bool get isNewBooking => notificationType == 'NewBooking';

  bool get isPending => isNewBooking || requestState == 'Requested' || requestState == 'AwaitingApproval';

  factory CancellationNotice.fromJson(Map<String, dynamic> json) {
    final names = json['serviceNames'];
    return CancellationNotice(
      notificationType: json['notificationType'] as String? ?? 'CancellationRequest',
      appointmentId: (json['appointmentId'] as num?)?.toInt() ?? 0,
      customerName: json['customerName'] as String? ?? '',
      serviceNames: names is List ? [for (final name in names) '$name'] : const [],
      serviceName: json['serviceName'] as String? ?? '',
      appointmentDate: DateTime.parse(json['appointmentDate'] as String),
      appointmentTime: json['appointmentTime'] == null
          ? null
          : DateTime.parse(json['appointmentTime'] as String),
      branchId: (json['branchId'] as num?)?.toInt() ?? 0,
      branchName: json['branchName'] as String? ?? '',
      requestedAt: json['requestedAt'] == null ? null : DateTime.parse(json['requestedAt'] as String),
      requestState: json['requestState'] as String? ?? 'Requested',
      preferredStylistName: json['preferredStylistName'] as String?,
      allocationState: json['allocationState'] as String? ?? '',
    );
  }
}
