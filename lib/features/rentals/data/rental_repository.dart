import '../../../core/api/api_client.dart';

class RentalBranchChoice {
  const RentalBranchChoice({required this.id, required this.name});

  final int id;
  final String name;
}

class RentalCustomerChoice {
  const RentalCustomerChoice({required this.id, required this.name, required this.branchId});

  final int id;
  final String name;
  final int branchId;
}

class RentalAsset {
  RentalAsset({
    required this.id,
    required this.branchId,
    required this.code,
    required this.name,
    required this.category,
    required this.chargePerUse,
    required this.cleaningBufferMinutes,
    required this.isActive,
    required this.availability,
  });

  final int id;
  final int branchId;
  final String code;
  final String name;
  final String category;
  final double chargePerUse;
  final int cleaningBufferMinutes;
  final bool isActive;
  final String availability;

  factory RentalAsset.fromJson(Map<String, dynamic> json) => RentalAsset(
        id: (json['rentalAssetId'] as num).toInt(),
        branchId: (json['branchId'] as num?)?.toInt() ?? 0,
        code: json['assetCode'] as String? ?? '',
        name: json['assetName'] as String? ?? '',
        category: json['category'] as String? ?? '',
        chargePerUse: (json['chargePerUse'] as num?)?.toDouble() ?? 0,
        cleaningBufferMinutes: (json['cleaningBufferMinutes'] as num?)?.toInt() ?? 0,
        isActive: json['isActive'] == true,
        availability: json['availability'] as String? ?? '',
      );
}

class RentalReservation {
  RentalReservation({
    required this.id,
    required this.branchId,
    required this.customerId,
    required this.customerName,
    required this.assetName,
    required this.status,
    required this.isOverdue,
    required this.chargePerUse,
    required this.isBillable,
    required this.conditionDiscrepancy,
    this.notes,
    this.issueCondition,
    this.returnCondition,
  });

  final int id;
  final int branchId;
  final int customerId;
  final String customerName;
  final String assetName;
  final String status;
  final bool isOverdue;
  final double chargePerUse;
  final bool isBillable;
  final bool conditionDiscrepancy;
  final String? notes;
  final String? issueCondition;
  final String? returnCondition;

  factory RentalReservation.fromJson(Map<String, dynamic> json) => RentalReservation(
        id: (json['rentalReservationId'] as num).toInt(),
        branchId: (json['branchId'] as num?)?.toInt() ?? 0,
        customerId: (json['customerId'] as num?)?.toInt() ?? 0,
        customerName: json['customerName'] as String? ?? '',
        assetName: json['assetName'] as String? ?? '',
        status: json['status'] as String? ?? '',
        isOverdue: json['isOverdue'] == true,
        chargePerUse: (json['chargePerUse'] as num?)?.toDouble() ?? 0,
        isBillable: json['isBillable'] == true,
        conditionDiscrepancy: json['conditionDiscrepancy'] == true,
        notes: json['notes'] as String?,
        issueCondition: json['issueCondition'] as String?,
        returnCondition: json['returnCondition'] as String?,
      );
}

class RentalRepository {
  RentalRepository({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<List<RentalAsset>> assets({bool includeInactive = true}) async {
    final rows = await _client.getJsonList('/api/Rentals/assets?includeInactive=$includeInactive');
    return rows.whereType<Map<String, dynamic>>().map(RentalAsset.fromJson).toList();
  }

  Future<void> saveAsset({
    int? id,
    required int branchId,
    required String code,
    required String name,
    required String category,
    required double chargePerUse,
    required int cleaningBufferMinutes,
    bool isActive = true,
  }) async {
    await _client.postJson('/api/Rentals/assets', {
      if (id != null && id > 0) 'rentalAssetId': id,
      'branchId': branchId,
      'assetCode': code,
      'assetName': name,
      'category': category,
      'chargePerUse': chargePerUse,
      'cleaningBufferMinutes': cleaningBufferMinutes,
      'isActive': isActive,
    });
  }

  Future<List<RentalReservation>> reservations() async {
    final rows = await _client.getJsonList('/api/Rentals/reservations');
    return rows.whereType<Map<String, dynamic>>().map(RentalReservation.fromJson).toList();
  }

  Future<void> reserve({
    required int customerId,
    required int assetId,
    required DateTime issueAt,
    required DateTime returnAt,
    String? notes,
  }) async {
    await _client.postJson('/api/Rentals/reservations', {
      'customerId': customerId,
      'rentalAssetId': assetId,
      'plannedIssueAt': issueAt.toUtc().toIso8601String(),
      'plannedReturnAt': returnAt.toUtc().toIso8601String(),
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
    });
  }

  Future<void> cancel(int id) => _client.postJson('/api/Rentals/reservations/$id/cancel', {});

  Future<void> issue(int id, String condition, {String? notes}) =>
      _client.postJson('/api/Rentals/reservations/$id/issue', {
        'condition': condition,
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      });

  Future<void> returned(int id, String condition, {String? notes}) =>
      _client.postJson('/api/Rentals/reservations/$id/return', {
        'condition': condition,
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      });
}
