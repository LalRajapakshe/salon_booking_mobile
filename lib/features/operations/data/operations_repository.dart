import '../../../core/api/api_client.dart';

class OperationsSummary {
  OperationsSummary({
    required this.scope,
    required this.todayAppointments,
    required this.pending,
    required this.checkedIn,
    required this.inProgress,
    required this.completed,
    required this.cancelled,
    required this.noShow,
    required this.openServiceLines,
    required this.myAssignedLines,
    this.activeRentals,
    this.overdueRentals,
    this.unpaidBills,
    this.outstandingAmount,
  });

  final String scope;
  final int todayAppointments;
  final int pending;
  final int checkedIn;
  final int inProgress;
  final int completed;
  final int cancelled;
  final int noShow;
  final int openServiceLines;
  final int myAssignedLines;
  final int? activeRentals;
  final int? overdueRentals;
  final int? unpaidBills;
  final double? outstandingAmount;

  factory OperationsSummary.fromJson(Map<String, dynamic> json) => OperationsSummary(
        scope: json['scope'] as String? ?? '',
        todayAppointments: (json['todayAppointments'] as num?)?.toInt() ?? 0,
        pending: (json['pending'] as num?)?.toInt() ?? 0,
        checkedIn: (json['checkedIn'] as num?)?.toInt() ?? 0,
        inProgress: (json['inProgress'] as num?)?.toInt() ?? 0,
        completed: (json['completed'] as num?)?.toInt() ?? 0,
        cancelled: (json['cancelled'] as num?)?.toInt() ?? 0,
        noShow: (json['noShow'] as num?)?.toInt() ?? 0,
        openServiceLines: (json['openServiceLines'] as num?)?.toInt() ?? 0,
        myAssignedLines: (json['myAssignedLines'] as num?)?.toInt() ?? 0,
        activeRentals: (json['activeRentals'] as num?)?.toInt(),
        overdueRentals: (json['overdueRentals'] as num?)?.toInt(),
        unpaidBills: (json['unpaidBills'] as num?)?.toInt(),
        outstandingAmount: (json['outstandingAmount'] as num?)?.toDouble(),
      );
}

class OperationsRepository {
  OperationsRepository({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<OperationsSummary> dashboard() async {
    return OperationsSummary.fromJson(await _client.getJson('/api/Operations/dashboard'));
  }
}
