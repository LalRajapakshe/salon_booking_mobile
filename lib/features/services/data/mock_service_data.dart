import '../../appointments/data/mock_appointment_data.dart';
import '../models/service_management_models.dart';

/// Branch label for a service. Branches come from the appointment lookups.
String branchNameForService(int branchId) {
  for (final branch in mockBranches) {
    if (branch.branchId == branchId) return branch.branchName;
  }
  return 'Branch $branchId';
}

SalonService _fromCatalog({
  required int serviceId,
  required String categoryName,
  required String description,
  required DateTime createdDate,
  bool isActive = true,
}) {
  final lookup = mockServices.firstWhere((item) => item.serviceId == serviceId);
  return SalonService(
    serviceId: lookup.serviceId,
    serviceCode: lookup.serviceCode,
    serviceName: lookup.serviceName,
    durationMinutes: lookup.durationMinutes,
    price: lookup.price,
    branchId: lookup.branchId,
    categoryName: categoryName,
    description: description,
    isActive: isActive,
    createdDate: createdDate,
  );
}

SalonService _extra({
  required int serviceId,
  required String serviceName,
  required String categoryName,
  required int durationMinutes,
  required double price,
  required String description,
  required DateTime createdDate,
  int branchId = 1,
  bool isActive = true,
}) {
  return SalonService(
    serviceId: serviceId,
    serviceCode: 'SRV-${serviceId.toString().padLeft(3, '0')}',
    serviceName: serviceName,
    durationMinutes: durationMinutes,
    price: price,
    branchId: branchId,
    categoryName: categoryName,
    description: description,
    isActive: isActive,
    createdDate: createdDate,
  );
}

/// Management catalog.
///
/// Services 1–6 are copied from [mockServices] so appointment booking and
/// this screen agree on code, name, duration, price, and branch. Later
/// services exist only here until a shared catalog is connected.
final List<SalonService> mockManagedServices = [
  _fromCatalog(
    serviceId: 1,
    categoryName: 'Hair',
    description:
        'Precision cut and finish tailored to the client\'s hair type.',
    createdDate: DateTime(2025, 8, 1),
  ),
  _fromCatalog(
    serviceId: 2,
    categoryName: 'Hair',
    description:
        'Professional colour service with a consultation, application, and styled finish.',
    createdDate: DateTime(2025, 8, 12),
  ),
  _fromCatalog(
    serviceId: 3,
    categoryName: 'Facial',
    description: 'Classic facial with cleanse, massage, and a hydrating mask.',
    createdDate: DateTime(2025, 9, 1),
  ),
  _fromCatalog(
    serviceId: 4,
    categoryName: 'Spa',
    description: 'Scalp and hair spa treatment to restore moisture and shine.',
    createdDate: DateTime(2025, 9, 18),
  ),
  _fromCatalog(
    serviceId: 5,
    categoryName: 'Hair',
    description: 'Kandy branch haircut with a wash and simple finish.',
    createdDate: DateTime(2025, 10, 2),
  ),
  _fromCatalog(
    serviceId: 6,
    categoryName: 'Makeup',
    description:
        'Bridal makeup with a trial-ready look, lashes, and long-wear finish.',
    createdDate: DateTime(2025, 10, 20),
  ),
  _extra(
    serviceId: 7,
    serviceName: 'Hair Wash',
    categoryName: 'Hair',
    durationMinutes: 20,
    price: 800,
    description: 'Gentle wash and condition before a cut or style.',
    createdDate: DateTime(2025, 11, 4),
  ),
  _extra(
    serviceId: 8,
    serviceName: 'Blow Dry',
    categoryName: 'Hair',
    durationMinutes: 30,
    price: 1800,
    description: 'Smooth blow dry with volume and a polished finish.',
    createdDate: DateTime(2025, 11, 15),
  ),
  _extra(
    serviceId: 9,
    serviceName: 'Hair Treatment',
    categoryName: 'Hair',
    durationMinutes: 60,
    price: 4800,
    description: 'Repair treatment for dry, coloured, or damaged hair.',
    createdDate: DateTime(2025, 12, 1),
  ),
  _extra(
    serviceId: 10,
    serviceName: 'Hair Styling',
    categoryName: 'Hair',
    durationMinutes: 45,
    price: 2800,
    description: 'Event styling, from soft waves to an updo.',
    createdDate: DateTime(2025, 12, 12),
  ),
  _extra(
    serviceId: 11,
    serviceName: 'Manicure',
    categoryName: 'Nails',
    durationMinutes: 45,
    price: 2200,
    description: 'Nail shape, cuticle care, and a classic polish.',
    createdDate: DateTime(2026, 1, 8),
  ),
  _extra(
    serviceId: 12,
    serviceName: 'Pedicure',
    categoryName: 'Nails',
    durationMinutes: 60,
    price: 2800,
    description: 'Foot soak, nail care, and polish.',
    createdDate: DateTime(2026, 1, 20),
  ),
  _extra(
    serviceId: 13,
    serviceName: 'Gel Polish',
    categoryName: 'Nails',
    durationMinutes: 40,
    price: 2500,
    description: 'Long-wear gel colour with a high-shine finish.',
    createdDate: DateTime(2026, 2, 3),
  ),
  _extra(
    serviceId: 14,
    serviceName: 'Nail Art',
    categoryName: 'Nails',
    durationMinutes: 50,
    price: 3500,
    description: 'Custom nail art on a gel or classic base.',
    createdDate: DateTime(2026, 2, 14),
    isActive: false,
  ),
  _extra(
    serviceId: 15,
    serviceName: 'Basic Facial',
    categoryName: 'Facial',
    durationMinutes: 45,
    price: 3500,
    description: 'A shorter facial for a fresh, even complexion.',
    createdDate: DateTime(2026, 3, 1),
  ),
  _extra(
    serviceId: 16,
    serviceName: 'Deep Cleansing Facial',
    categoryName: 'Facial',
    durationMinutes: 75,
    price: 5500,
    description:
        'Deep cleanse for congested skin, with extraction and a calming mask.',
    createdDate: DateTime(2026, 3, 12),
  ),
  _extra(
    serviceId: 17,
    serviceName: 'Anti-Aging Facial',
    categoryName: 'Facial',
    durationMinutes: 90,
    price: 7500,
    description: 'Firming facial focused on hydration and fine lines.',
    createdDate: DateTime(2026, 3, 28),
  ),
  _extra(
    serviceId: 18,
    serviceName: 'Head Massage',
    categoryName: 'Spa',
    durationMinutes: 30,
    price: 1800,
    description: 'Scalp and temple massage to ease tension.',
    createdDate: DateTime(2026, 4, 6),
  ),
  _extra(
    serviceId: 19,
    serviceName: 'Full Body Massage',
    categoryName: 'Spa',
    durationMinutes: 90,
    price: 6500,
    description: 'Full body massage using a light, unscented oil.',
    createdDate: DateTime(2026, 4, 18),
  ),
  _extra(
    serviceId: 20,
    serviceName: 'Relaxation Massage',
    categoryName: 'Spa',
    durationMinutes: 60,
    price: 4200,
    description: 'Slow, calming massage for the back, neck, and shoulders.',
    createdDate: DateTime(2026, 5, 2),
    isActive: false,
  ),
  _extra(
    serviceId: 21,
    serviceName: 'Cleanup',
    categoryName: 'Skin',
    durationMinutes: 30,
    price: 2000,
    description: 'Quick skin cleanup with cleanse, scrub, and tone.',
    createdDate: DateTime(2026, 5, 16),
  ),
  _extra(
    serviceId: 22,
    serviceName: 'Threading',
    categoryName: 'Skin',
    durationMinutes: 15,
    price: 600,
    description: 'Brow shaping and upper-lip threading.',
    createdDate: DateTime(2026, 6, 1),
  ),
];
