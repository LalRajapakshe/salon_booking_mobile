class ServiceLineProgressEntry {
  final int appointmentServiceStatusHistoryId;
  final String? oldStatus;
  final String newStatus;
  final String action;
  final String? reason;
  final DateTime? changedAt;

  const ServiceLineProgressEntry({
    required this.appointmentServiceStatusHistoryId,
    required this.newStatus,
    required this.action,
    this.oldStatus,
    this.reason,
    this.changedAt,
  });

  factory ServiceLineProgressEntry.fromJson(Map<String, dynamic> json) {
    return ServiceLineProgressEntry(
      appointmentServiceStatusHistoryId: json['appointmentServiceStatusHistoryId'] is num
          ? (json['appointmentServiceStatusHistoryId'] as num).toInt()
          : 0,
      oldStatus: json['oldStatus'] as String?,
      newStatus: json['newStatus'] as String? ?? '',
      action: json['action'] as String? ?? '',
      reason: json['reason'] as String?,
      changedAt: json['changedAt'] is String ? DateTime.tryParse(json['changedAt'] as String) : null,
    );
  }
}
