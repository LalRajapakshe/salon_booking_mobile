import '../../appointments/models/salon_lookups.dart';

/// Categories a service can belong to.
///
/// There is no ServiceCategory entity in the app yet, so this is a fixed
/// list used by the service form and the category filter.
const List<String> serviceCategoryNames = [
  'Hair',
  'Nails',
  'Facial',
  'Skin',
  'Spa',
  'Makeup',
];

enum ServiceMenuAction { view, edit, delete }

/// Service record for Service Management.
///
/// Appointment booking still reads [ServiceLookup]. This record keeps those
/// same identity fields (`serviceId`, `serviceCode`, `serviceName`,
/// `durationMinutes`, `price`, `branchId`) and adds the management fields
/// this screen needs. [toLookup] is the bridge for a later shared catalog.
class SalonService {
  final int serviceId;
  final String serviceCode;
  final String serviceName;
  final int durationMinutes;
  final double price;
  final int branchId;
  final String categoryName;
  final String description;
  final bool isActive;
  final DateTime createdDate;

  const SalonService({
    required this.serviceId,
    required this.serviceCode,
    required this.serviceName,
    required this.durationMinutes,
    required this.price,
    required this.branchId,
    required this.categoryName,
    required this.description,
    required this.isActive,
    required this.createdDate,
  });

  String get statusLabel => isActive ? 'Active' : 'Inactive';

  String get durationLabel =>
      durationMinutes == 1 ? '1 minute' : '$durationMinutes minutes';

  String get durationCompact => '$durationMinutes min';

  ServiceLookup toLookup() {
    return ServiceLookup(
      serviceId: serviceId,
      serviceCode: serviceCode,
      serviceName: serviceName,
      durationMinutes: durationMinutes,
      price: price,
      branchId: branchId,
    );
  }

  SalonService copyWith({
    int? serviceId,
    String? serviceCode,
    String? serviceName,
    int? durationMinutes,
    double? price,
    int? branchId,
    String? categoryName,
    String? description,
    bool? isActive,
    DateTime? createdDate,
  }) {
    return SalonService(
      serviceId: serviceId ?? this.serviceId,
      serviceCode: serviceCode ?? this.serviceCode,
      serviceName: serviceName ?? this.serviceName,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      price: price ?? this.price,
      branchId: branchId ?? this.branchId,
      categoryName: categoryName ?? this.categoryName,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      createdDate: createdDate ?? this.createdDate,
    );
  }
}
