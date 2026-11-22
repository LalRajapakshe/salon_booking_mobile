class AllocationRecommendation {
  final int appointmentId;
  final DateTime requestedDate;
  final DateTime? requestedTime;
  final String? preferredStylistName;
  final List<String> serviceNames;
  final List<AllocationOption> options;

  const AllocationRecommendation({
    required this.appointmentId,
    required this.requestedDate,
    required this.requestedTime,
    required this.preferredStylistName,
    required this.serviceNames,
    required this.options,
  });

  factory AllocationRecommendation.fromJson(Map<String, dynamic> json) {
    final names = json['serviceNames'];
    final options = json['options'];
    return AllocationRecommendation(
      appointmentId: (json['appointmentId'] as num?)?.toInt() ?? 0,
      requestedDate: DateTime.parse(json['requestedDate'] as String),
      requestedTime: json['requestedTime'] == null ? null : DateTime.parse(json['requestedTime'] as String),
      preferredStylistName: json['preferredStylistName'] as String?,
      serviceNames: names is List ? [for (final name in names) '$name'] : const [],
      options: options is List
          ? [
              for (final item in options)
                if (item is Map) AllocationOption.fromJson(Map<String, dynamic>.from(item)),
            ]
          : const [],
    );
  }
}

class AllocationOption {
  final int rank;
  final bool exactMatch;
  final bool usesPreferredStylist;
  final int minuteDifference;
  final int dayDifference;
  final String reason;
  final List<AllocationLine> lines;

  const AllocationOption({
    required this.rank,
    required this.exactMatch,
    required this.usesPreferredStylist,
    required this.minuteDifference,
    required this.dayDifference,
    required this.reason,
    required this.lines,
  });

  factory AllocationOption.fromJson(Map<String, dynamic> json) {
    final lines = json['lines'];
    return AllocationOption(
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      exactMatch: json['exactMatch'] as bool? ?? false,
      usesPreferredStylist: json['usesPreferredStylist'] as bool? ?? false,
      minuteDifference: (json['minuteDifference'] as num?)?.toInt() ?? 0,
      dayDifference: (json['dayDifference'] as num?)?.toInt() ?? 0,
      reason: json['reason'] as String? ?? '',
      lines: lines is List
          ? [
              for (final item in lines)
                if (item is Map) AllocationLine.fromJson(Map<String, dynamic>.from(item)),
            ]
          : const [],
    );
  }
}

class AllocationLine {
  final int appointmentServiceId;
  final String serviceName;
  final int durationMinutes;
  final int employeeId;
  final String stylistName;
  final DateTime startTime;
  final DateTime endTime;
  final String rowVersion;

  const AllocationLine({
    required this.appointmentServiceId,
    required this.serviceName,
    required this.durationMinutes,
    required this.employeeId,
    required this.stylistName,
    required this.startTime,
    required this.endTime,
    required this.rowVersion,
  });

  factory AllocationLine.fromJson(Map<String, dynamic> json) {
    return AllocationLine(
      appointmentServiceId: (json['appointmentServiceId'] as num?)?.toInt() ?? 0,
      serviceName: json['serviceName'] as String? ?? '',
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 0,
      employeeId: (json['employeeId'] as num?)?.toInt() ?? 0,
      stylistName: json['stylistName'] as String? ?? '',
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      rowVersion: json['rowVersion'] as String? ?? '',
    );
  }
}
