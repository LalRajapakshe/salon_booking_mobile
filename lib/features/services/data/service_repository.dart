import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/auth/access_token_claims.dart';
import '../../../core/auth/auth_session.dart';
import '../api/service_api_mapper.dart';
import '../models/service_management_models.dart';

class ServiceRepository {
  ServiceRepository({ApiClient? client, AuthSession? session})
      : _client = client ?? ApiClient(),
        _session = session ?? AuthSession.instance;

  final ApiClient _client;
  final AuthSession _session;

  bool get isApiBacked => _session.isSignedIn;

  Future<List<ServiceCategoryRecord>> categories() async {
    final categories = <ServiceCategoryRecord>[];
    var page = 1;
    while (page <= 50) {
      final body = await _client.getJson('/api/ServiceCategories?page=$page&pageSize=100');
      categories.addAll(ServiceApiMapper.categories(body));
      if (page >= ServiceApiMapper.totalPages(body)) break;
      page++;
    }
    return categories;
  }

  /// Signed-in sessions read `GET /api/Services` for the token branch.
  Future<List<SalonService>> list() async {
    final names = {
      for (final category in await categories())
        category.serviceCategoryId: category.categoryName,
    };
    final services = <SalonService>[];
    var page = 1;
    while (page <= 50) {
      final body = await _client.getJson('/api/Services?page=$page&pageSize=100');
      services.addAll(ServiceApiMapper.page(body, names));
      if (page >= ServiceApiMapper.totalPages(body)) break;
      page++;
    }
    return services;
  }

  /// `POST /api/Services`. Tenant comes from the token.
  ///
  /// `branchId` is the BranchId claim. The service validator requires a
  /// branch, and a different branch is rejected by the server.
  /// Cost and commission are omitted, so the server stores 0.
  Future<SalonService> create({
    required int serviceCategoryId,
    required String serviceName,
    required String description,
    required int durationMinutes,
    required double price,
    required String categoryName,
  }) async {
    final branchId = AccessTokenClaims.branchId(_session.accessToken);
    if (branchId == null) {
      throw const ApiException('A branch is required.');
    }

    final body = <String, dynamic>{
      'branchId': branchId,
      'serviceCategoryId': serviceCategoryId,
      'serviceName': serviceName.trim(),
      'description': description.trim(),
      'durationMinutes': durationMinutes,
      'price': price,
    };
    final created = ServiceApiMapper.service(
      await _client.postJson('/api/Services', body),
      {serviceCategoryId: categoryName},
    );
    if (created.serviceId <= 0) {
      throw const ApiException('The server returned an unexpected response.');
    }
    return created;
  }

  /// `PUT /api/Services/{id}`. The code stays as it was issued.
  Future<SalonService> update(SalonService service) async {
    final body = <String, dynamic>{
      'branchId': service.branchId,
      'serviceCategoryId': service.serviceCategoryId,
      'serviceName': service.serviceName.trim(),
      'description': service.description.trim(),
      'durationMinutes': service.durationMinutes,
      'price': service.price,
      'cost': service.cost,
      'commissionPercentage': service.commissionPercentage,
      'isActive': service.isActive,
    };
    return ServiceApiMapper.service(
      await _client.putJson('/api/Services/${service.serviceId}', body),
      {service.serviceCategoryId: service.categoryName},
    );
  }

  /// `DELETE /api/Services/{id}` marks the row deleted. It stays in the database.
  Future<void> delete(int serviceId) {
    return _client.deleteJson('/api/Services/$serviceId');
  }

  Future<ServiceCategoryRecord> createCategory({
    required String categoryName,
    required String description,
    required int displayOrder,
  }) async {
    final created = ServiceApiMapper.category(
      await _client.postJson('/api/ServiceCategories', {
        'categoryName': categoryName.trim(),
        'description': description.trim(),
        'displayOrder': displayOrder,
      }),
    );
    if (created.serviceCategoryId <= 0) {
      throw const ApiException('The server returned an unexpected response.');
    }
    return created;
  }

  Future<ServiceCategoryRecord> updateCategory(ServiceCategoryRecord category) async {
    return ServiceApiMapper.category(
      await _client.putJson('/api/ServiceCategories/${category.serviceCategoryId}', {
        'categoryName': category.categoryName.trim(),
        'description': category.description.trim(),
        'displayOrder': category.displayOrder,
        'isActive': category.isActive,
      }),
    );
  }

  /// `DELETE /api/ServiceCategories/{id}` marks the row deleted.
  Future<void> deleteCategory(int serviceCategoryId) {
    return _client.deleteJson('/api/ServiceCategories/$serviceCategoryId');
  }
}
