import '../../../core/api/api_client.dart';
import '../models/billing_models.dart';

class BillingRepository {
  BillingRepository({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<List<SalonBill>> listBills() async {
    final bills = <SalonBill>[];
    var page = 1;
    while (page <= 50) {
      final body = await _client.getJson('/api/Bills?page=$page&pageSize=50');
      final items = body['items'];
      if (items is List) {
        bills.addAll(items.whereType<Map<String, dynamic>>().map(SalonBill.fromJson));
      }
      final pages = body['totalPages'];
      final totalPages = pages is num ? pages.toInt() : 1;
      if (page >= totalPages) break;
      page++;
    }
    return bills;
  }

  Future<SalonBill> getBill(int id) async {
    return SalonBill.fromJson(await _client.getJson('/api/Bills/$id'));
  }

  Future<List<EligibleServiceLine>> eligibleServices(int appointmentId) async {
    final rows = await _client.getJsonList('/api/Bills/eligible-services/$appointmentId');
    return rows.whereType<Map<String, dynamic>>().map(EligibleServiceLine.fromJson).toList();
  }

  Future<SalonBill> createBill({
    required int customerId,
    int? branchId,
    int? appointmentId,
    List<int> appointmentServiceIds = const [],
    List<Map<String, dynamic>> products = const [],
    String? notes,
  }) async {
    final body = <String, dynamic>{
      'customerId': customerId,
      'appointmentId': appointmentId,
      'appointmentServiceIds': appointmentServiceIds,
      'products': products,
      'notes': notes,
    };
    if (branchId != null && branchId > 0) body['branchId'] = branchId;
    return SalonBill.fromJson(await _client.postJson('/api/Bills', body));
  }

  Future<SalonBill> addRental({
    required int billId,
    required String rowVersion,
    required int reservationId,
  }) async {
    return SalonBill.fromJson(await _client.postJson('/api/Bills/$billId/rentals', {
      'rowVersion': rowVersion,
      'rentalReservationId': reservationId,
    }));
  }

  Future<SalonBill> addProduct({
    required int billId,
    required String rowVersion,
    required int productId,
    required int quantity,
  }) async {
    return SalonBill.fromJson(await _client.postJson('/api/Bills/$billId/product-lines', {
      'rowVersion': rowVersion,
      'retailProductId': productId,
      'quantity': quantity,
    }));
  }

  Future<SalonBill> removeLine({
    required int billId,
    required int lineId,
    required String rowVersion,
  }) async {
    return SalonBill.fromJson(
      await _client.deleteJson('/api/Bills/$billId/lines/$lineId?rowVersion=${Uri.encodeQueryComponent(rowVersion)}'),
    );
  }

  Future<SalonBill> finalize(int billId, String rowVersion) async {
    return SalonBill.fromJson(await _client.postJson('/api/Bills/$billId/finalize', {
      'rowVersion': rowVersion,
    }));
  }

  Future<SalonBill> pay({
    required int billId,
    required String rowVersion,
    required String method,
    required double amount,
  }) async {
    return SalonBill.fromJson(await _client.postJson('/api/Bills/$billId/payments', {
      'rowVersion': rowVersion,
      'method': method,
      'amount': amount,
    }));
  }

  Future<SalonBill> refund({
    required int billId,
    required String rowVersion,
    required String method,
    required double amount,
  }) async {
    return SalonBill.fromJson(await _client.postJson('/api/Bills/$billId/refunds', {
      'rowVersion': rowVersion,
      'method': method,
      'amount': amount,
    }));
  }

  Future<SalonBill> voidBill({
    required int billId,
    required String rowVersion,
    required String reason,
  }) async {
    return SalonBill.fromJson(await _client.postJson('/api/Bills/$billId/void', {
      'rowVersion': rowVersion,
      'reason': reason,
    }));
  }

  Future<TaxSetting> getTax(int branchId) async {
    return TaxSetting.fromJson(await _client.getJson('/api/TaxSettings?branchId=$branchId'));
  }

  Future<TaxSetting> saveTax({
    required int branchId,
    required String name,
    required double ratePercent,
  }) async {
    return TaxSetting.fromJson(await _client.putJson('/api/TaxSettings', {
      'branchId': branchId,
      'name': name,
      'ratePercent': ratePercent,
    }));
  }

  Future<List<RetailProduct>> listProducts({String? search, bool includeInactive = false}) async {
    final products = <RetailProduct>[];
    var page = 1;
    final query = StringBuffer();
    if (search != null && search.trim().isNotEmpty) {
      query.write('&search=${Uri.encodeQueryComponent(search.trim())}');
    }
    if (includeInactive) query.write('&includeInactive=true');
    while (page <= 50) {
      final body = await _client.getJson('/api/RetailProducts?page=$page&pageSize=50$query');
      final items = body['items'];
      if (items is List) {
        products.addAll(items.whereType<Map<String, dynamic>>().map(RetailProduct.fromJson));
      }
      final pages = body['totalPages'];
      final totalPages = pages is num ? pages.toInt() : 1;
      if (page >= totalPages) break;
      page++;
    }
    return products;
  }

  Future<RetailProduct> saveProduct({
    int? id,
    required String code,
    required String name,
    required double sellingPrice,
    String? description,
    bool isActive = true,
  }) async {
    final body = {
      'productCode': code,
      'productName': name,
      'description': description,
      'sellingPrice': sellingPrice,
      'isActive': isActive,
    };
    if (id == null) {
      return RetailProduct.fromJson(await _client.postJson('/api/RetailProducts', body));
    }
    return RetailProduct.fromJson(await _client.putJson('/api/RetailProducts/$id', body));
  }
}
