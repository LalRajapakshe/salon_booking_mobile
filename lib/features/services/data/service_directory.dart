import 'package:flutter/foundation.dart';

import '../models/service_management_models.dart';
import 'mock_service_data.dart';

/// In-memory service list for the prototype.
///
/// Nothing here calls an API. [session] keeps changes while the app is open.
/// Tests should pass their own [ServiceDirectory] and leave [session] alone.
class ServiceDirectory {
  ServiceDirectory({List<SalonService>? services})
    : _services = List<SalonService>.of(services ?? mockManagedServices);

  static ServiceDirectory? _session;

  static ServiceDirectory get session => _session ??= ServiceDirectory();

  @visibleForTesting
  static void resetSession() {
    _session = null;
  }

  final List<SalonService> _services;

  List<SalonService> get services => List<SalonService>.unmodifiable(_services);

  int get totalCount => _services.length;

  int get activeCount => _services.where((item) => item.isActive).length;

  int get categoryCount =>
      _services.map((item) => item.categoryName).toSet().length;

  double get averagePrice {
    if (_services.isEmpty) return 0;
    final total = _services.fold<double>(0, (sum, item) => sum + item.price);
    return total / _services.length;
  }

  SalonService? findById(int serviceId) {
    for (final service in _services) {
      if (service.serviceId == serviceId) return service;
    }
    return null;
  }

  SalonService add(SalonService draft) {
    final saved = draft.copyWith(
      serviceId: _nextId(),
      serviceCode: _nextCode(),
      createdDate: DateTime.now(),
    );
    _services.add(saved);
    return saved;
  }

  void update(SalonService service) {
    final index = _services.indexWhere(
      (item) => item.serviceId == service.serviceId,
    );
    if (index < 0) return;
    _services[index] = service;
  }

  void delete(int serviceId) {
    _services.removeWhere((item) => item.serviceId == serviceId);
  }

  int _nextId() {
    var maxId = 0;
    for (final service in _services) {
      if (service.serviceId > maxId) maxId = service.serviceId;
    }
    return maxId + 1;
  }

  String _nextCode() {
    var maxCode = 0;
    final pattern = RegExp(r'(\d+)$');
    for (final service in _services) {
      final match = pattern.firstMatch(service.serviceCode);
      final value = int.tryParse(match?.group(1) ?? '');
      if (value != null && value > maxCode) maxCode = value;
    }
    return 'SRV-${(maxCode + 1).toString().padLeft(3, '0')}';
  }
}
