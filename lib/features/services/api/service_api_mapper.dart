import '../../../core/api/api_exception.dart';
import '../models/service_management_models.dart';

class ServiceCategoryRecord {
  final int serviceCategoryId;
  final String categoryName;

  const ServiceCategoryRecord({
    required this.serviceCategoryId,
    required this.categoryName,
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

  static List<ServiceCategoryRecord> categories(Map<String, dynamic> json) {
    final items = json['items'];
    if (items is! List) return const [];
    return [
      for (final item in items)
        if (item is Map<String, dynamic>)
          ServiceCategoryRecord(
            serviceCategoryId: _int(item['serviceCategoryId']),
            categoryName: item['categoryName'] as String? ?? '',
          ),
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
      price: json['price'] is num ? (json['price'] as num).toDouble() : 0,
      branchId: _int(json['branchId']),
      serviceCategoryId: categoryId,
      categoryName: categoryNames[categoryId] ?? 'Category $categoryId',
      description: json['description'] as String? ?? '',
      isActive: json['isActive'] == true,
      createdDate: created,
    );
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
