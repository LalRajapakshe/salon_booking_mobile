import '../../../core/api/api_exception.dart';
import '../models/service_management_models.dart';

class ServiceCategoryRecord {
  final int serviceCategoryId;
  final String categoryCode;
  final String categoryName;
  final String description;
  final int displayOrder;
  final bool isActive;

  const ServiceCategoryRecord({
    required this.serviceCategoryId,
    this.categoryCode = '',
    required this.categoryName,
    this.description = '',
    this.displayOrder = 0,
    this.isActive = true,
  });
}

class ServiceApiMapper {
  const ServiceApiMapper._();

  static List<SalonService> page(
    Map<String, dynamic> json,
    Map<int, String> categoryNames,
  ) {
    final items = json['items'];
    if (items is! List) return const [];
    return [
      for (final item in items)
        if (item is Map<String, dynamic>) service(item, categoryNames),
    ];
  }

  static ServiceCategoryRecord category(Map<String, dynamic> json) {
    return ServiceCategoryRecord(
      serviceCategoryId: _int(json['serviceCategoryId']),
      categoryCode: json['categoryCode'] as String? ?? '',
      categoryName: json['categoryName'] as String? ?? '',
      description: json['description'] as String? ?? '',
      displayOrder: _int(json['displayOrder']),
      isActive: json['isActive'] != false,
    );
  }

  static List<ServiceCategoryRecord> categories(Map<String, dynamic> json) {
    final items = json['items'];
    if (items is! List) return const [];
    return [
      for (final item in items)
        if (item is Map<String, dynamic>)
          category(item),
    ].where((item) => item.serviceCategoryId > 0 && item.categoryName.isNotEmpty).toList();
  }

  static int totalPages(Map<String, dynamic> json) {
    final value = json['totalPages'];
    if (value is num && value > 0) return value.toInt();
    return 1;
  }

  static SalonService service(
    Map<String, dynamic> json,
    Map<int, String> categoryNames,
  ) {
    final created = _date(json['createdDate']);
    if (created == null) {
      throw const ApiException('The server returned an unexpected response.');
    }
    final categoryId = _int(json['serviceCategoryId']);
    return SalonService(
      serviceId: _int(json['serviceId']),
      serviceCode: json['serviceCode'] as String? ?? '',
      serviceName: json['serviceName'] as String? ?? '',
      durationMinutes: _int(json['durationMinutes']),
      price: _money(json['price']),
      cost: _money(json['cost']),
      commissionPercentage: _money(json['commissionPercentage']),
      branchId: _int(json['branchId']),
      serviceCategoryId: categoryId,
      categoryName: categoryNames[categoryId] ?? 'Category $categoryId',
      description: json['description'] as String? ?? '',
      isActive: json['isActive'] == true,
      createdDate: created,
    );
  }

  static double _money(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }

  static int _int(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  static DateTime? _date(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }
}
