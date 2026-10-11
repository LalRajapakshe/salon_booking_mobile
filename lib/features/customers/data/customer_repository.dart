import 'dart:typed_data';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/auth/auth_session.dart';
import '../api/customer_api_mapper.dart';
import '../models/customer_model.dart';
import '../photos/customer_photo_store.dart';

class CustomerRepository {
  CustomerRepository({ApiClient? client, AuthSession? session})
      : _client = client ?? ApiClient(),
        _session = session ?? AuthSession.instance;

  final ApiClient _client;
  final AuthSession _session;
  final CustomerPhotoCache photos = CustomerPhotoCache();

  bool get isApiBacked => _session.isSignedIn;

  /// Signed-in sessions read `GET /api/Customers`.
  /// Tenant and branch stay on the authenticated user.
  Future<List<Customer>> list() async {
    final customers = <Customer>[];
    var page = 1;
    while (page <= 50) {
      final body = await _client.getJson('/api/Customers?page=$page&pageSize=100');
      customers.addAll(CustomerApiMapper.page(body));
      if (page >= CustomerApiMapper.totalPages(body)) break;
      page++;
    }
    return customers;
  }

  /// `POST /api/Customers`. The server assigns the customer code, tenant, and branch.
  Future<Customer> create({
    required String firstName,
    required String lastName,
    required String mobileNo,
    String? email,
    String? gender,
    DateTime? dateOfBirth,
    String? remarks,
  }) async {
    final body = <String, dynamic>{
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'mobileNo': mobileNo.trim(),
    };
    final trimmedEmail = email?.trim();
    if (trimmedEmail != null && trimmedEmail.isNotEmpty) body['email'] = trimmedEmail;
    final trimmedGender = gender?.trim();
    if (trimmedGender != null && trimmedGender.isNotEmpty) body['gender'] = trimmedGender;
    if (dateOfBirth != null) body['dateOfBirth'] = _dateOnly(dateOfBirth);
    final trimmedRemarks = remarks?.trim();
    if (trimmedRemarks != null && trimmedRemarks.isNotEmpty) body['remarks'] = trimmedRemarks;

    final created = CustomerApiMapper.customer(await _client.postJson('/api/Customers', body));
    if (created.id <= 0) {
      throw const ApiException('The server returned an unexpected response.');
    }
    return created;
  }

  /// `POST /api/Customers/{id}/photo`. The server stores the file and returns the customer.
  Future<Customer> uploadPhoto(int customerId, List<int> bytes) async {
    final saved = CustomerApiMapper.customer(
      await _client.postMultipart(
        '/api/Customers/$customerId/photo',
        field: 'file',
        bytes: bytes,
        filename: 'photo.jpg',
      ),
    );
    if (saved.photoPath != null) {
      photos.write(customerId, saved.photoPath!, Uint8List.fromList(bytes));
    }
    return saved;
  }

  /// `DELETE /api/Customers/{id}/photo`.
  Future<Customer> removePhoto(int customerId) async {
    final saved = CustomerApiMapper.customer(
      await _client.deleteJson('/api/Customers/$customerId/photo'),
    );
    photos.forget(customerId);
    return saved;
  }

  /// `GET /api/Customers/{id}/photo`. A missing photo is null.
  Future<Uint8List?> fetchPhoto(int customerId, String photoPath) async {
    final cached = photos.read(customerId, photoPath);
    if (cached != null) return cached;
    try {
      final bytes = Uint8List.fromList(
        await _client.getBytes('/api/Customers/$customerId/photo'),
      );
      photos.write(customerId, photoPath, bytes);
      return bytes;
    } on ApiException catch (error) {
      if (error.statusCode == 404) return null;
      rethrow;
    }
  }

  static String _dateOnly(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
