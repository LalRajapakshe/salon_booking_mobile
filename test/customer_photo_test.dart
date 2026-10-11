import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:salon_booking_mobile/core/api/api_client.dart';
import 'package:salon_booking_mobile/core/api/api_exception.dart';
import 'package:salon_booking_mobile/core/auth/auth_session.dart';
import 'package:salon_booking_mobile/features/customers/data/customer_repository.dart';
import 'package:salon_booking_mobile/features/customers/models/customer_model.dart';
import 'package:salon_booking_mobile/features/customers/photos/customer_photo_store.dart';
import 'package:salon_booking_mobile/features/customers/screens/create_customer_screen.dart';
import 'package:salon_booking_mobile/features/customers/widgets/customer_avatar.dart';
import 'package:salon_booking_mobile/features/customers/widgets/customer_photo_field.dart';

void main() {
  tearDown(AuthSession.instance.clear);

  final jpeg = Uint8List.fromList(const [0xFF, 0xD8, 0xFF, 0xD9]);
  final png = Uint8List.fromList(
    base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=='),
  );

  test('photo bytes are accepted only for jpeg, png, and webp within 2 MB', () {
    expect(validateCustomerPhoto(jpeg), isNull);
    expect(
      validateCustomerPhoto(const [0x89, 0x50, 0x4E, 0x47, 0, 0, 0, 0]),
      isNull,
    );
    expect(
      validateCustomerPhoto(const [0x52, 0x49, 0x46, 0x46, 0, 0, 0, 0, 0x57, 0x45, 0x42, 0x50]),
      isNull,
    );
    expect(validateCustomerPhoto(utf8.encode('not-an-image')), 'The photo must be a JPEG, PNG, or WebP image.');
    expect(validateCustomerPhoto(Uint8List(customerPhotoMaxBytes + 1)), 'The photo is larger than 2 MB.');
  });

  testWidgets('photo field previews a chosen image and can remove it', (tester) async {
    Uint8List? selected;
    String? error;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return CustomerPhotoField(
                bytes: selected,
                errorText: error,
                choosePhoto: () async => png,
                takePhoto: () async => png,
                onSelected: (bytes) => setState(() {
                  selected = bytes;
                  error = null;
                }),
                onInvalid: (message) => setState(() => error = message),
                onRemove: () => setState(() => selected = null),
              );
            },
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.person_outline), findsOneWidget);
    expect(find.text('Take Photo'), findsOneWidget);
    expect(find.text('Choose Photo'), findsOneWidget);

    await tester.tap(find.text('Choose Photo'));
    await tester.pump();

    expect(find.text('Preview — not saved'), findsOneWidget);
    expect(find.text('Replace'), findsOneWidget);
    expect(find.byIcon(Icons.person_outline), findsNothing);

    await tester.tap(find.text('Remove'));
    await tester.pump();
    expect(find.byIcon(Icons.person_outline), findsOneWidget);
    expect(find.text('Preview — not saved'), findsNothing);

    await tester.tap(find.text('Take Photo'));
    await tester.pump();
    expect(find.text('Preview — not saved'), findsOneWidget);
  });

  testWidgets('photo field shows an error for a file that is not an image', (tester) async {
    String? error;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return CustomerPhotoField(
                bytes: null,
                errorText: error,
                choosePhoto: () async => Uint8List.fromList(const [1, 2, 3, 4]),
                onSelected: (_) {},
                onInvalid: (message) => setState(() => error = message),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Choose Photo'));
    await tester.pump();
    expect(find.text('The photo must be a JPEG, PNG, or WebP image.'), findsOneWidget);
  });

  testWidgets('signed-in registration saves without a photo', (tester) async {
    AuthSession.instance.save(
      accessToken: 'token',
      username: 'tester',
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
    );
    final repository = _RecordingRepository();
    await _openCreate(tester, repository);

    await _fillRequired(tester);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(repository.creates, 1);
    expect(repository.uploads, 0);
    expect(find.text('Nimal Perera was saved.'), findsOneWidget);
  });

  testWidgets('a failed photo upload stays on the form and retries without a second customer', (tester) async {
    AuthSession.instance.save(
      accessToken: 'token',
      username: 'tester',
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
    );
    final repository = _RecordingRepository()
      ..uploadError = const ApiException('The photo must be a JPEG, PNG, or WebP image.');
    await _openCreate(tester, repository, choosePhoto: () async => png);

    await _fillRequired(tester);
    await tester.tap(find.text('Choose Photo'));
    await tester.pump();
    expect(find.text('Preview — not saved'), findsOneWidget);

    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(repository.creates, 1);
    expect(repository.uploads, 1);
    expect(find.textContaining('was saved, but the photo was not stored'), findsOneWidget);
    expect(find.text('Create Customer'), findsWidgets);

    repository.uploadError = null;
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(repository.creates, 1);
    expect(repository.uploads, 2);
    expect(find.text('Nimal Perera was saved.'), findsOneWidget);
  });

  testWidgets('saved customer photo is shown from the cache', (tester) async {
    AuthSession.instance.save(
      accessToken: 'token',
      username: 'tester',
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
    );
    final repository = CustomerRepository(session: AuthSession.instance);
    final customer = Customer(
      id: 4,
      customerCode: 'CUS000004',
      firstName: 'Nimal',
      lastName: 'Perera',
      mobileNumber: '0771234567',
      photoPath: 'photo.jpg',
      createdDate: DateTime(2026, 10, 11),
    );
    repository.photos.write(4, 'photo.jpg', png);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: CustomerAvatar(customer: customer, repository: repository)),
      ),
    );
    await tester.pump();

    final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
    expect(avatar.backgroundImage, isA<MemoryImage>());
    expect(find.text('NP'), findsNothing);
  });

  test('upload sends the photo bytes and keeps the returned storage key', () async {
    AuthSession.instance.save(
      accessToken: 'token',
      username: 'tester',
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
    );
    final capture = _CaptureClient(
      jsonEncode({
        'customerId': 8,
        'customerCode': 'CUS000008',
        'firstName': 'Nimal',
        'lastName': 'Perera',
        'mobileNo': '0771234567',
        'photoPath': '8f1c2a7e-4b36-49d1-a805-2c7e91f64a10.jpg',
        'isActive': true,
        'createdDate': '2026-10-09T10:00:00',
      }),
    );
    final repository = CustomerRepository(
      client: ApiClient(httpClient: capture, session: AuthSession.instance),
      session: AuthSession.instance,
    );

    final saved = await repository.uploadPhoto(8, png);
    expect(saved.photoPath, '8f1c2a7e-4b36-49d1-a805-2c7e91f64a10.jpg');
    expect(capture.request, isA<http.MultipartRequest>());
    final multipart = capture.request! as http.MultipartRequest;
    expect(multipart.headers['authorization'], 'Bearer token');
    expect(multipart.files.single.field, 'file');
    expect(multipart.url.path, '/api/Customers/8/photo');
  });
}

Future<void> _openCreate(
  WidgetTester tester,
  CustomerRepository repository, {
  Future<Uint8List?> Function()? choosePhoto,
}) async {
  await tester.binding.setSurfaceSize(const Size(1280, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => CreateCustomerScreen(
                    repository: repository,
                    choosePhoto: choosePhoto ?? () async => null,
                    takePhoto: () async => null,
                  ),
                ),
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

Future<void> _fillRequired(WidgetTester tester) async {
  await tester.enterText(find.widgetWithText(TextFormField, 'First Name'), 'Nimal');
  await tester.enterText(find.widgetWithText(TextFormField, 'Last Name'), 'Perera');
  await tester.enterText(find.widgetWithText(TextFormField, 'Mobile Number'), '0771234567');
}

class _RecordingRepository extends CustomerRepository {
  _RecordingRepository() : super(session: AuthSession.instance);

  int creates = 0;
  int uploads = 0;
  ApiException? uploadError;

  @override
  Future<Customer> create({
    required String firstName,
    required String lastName,
    required String mobileNo,
    String? email,
    String? gender,
    DateTime? dateOfBirth,
    String? remarks,
  }) async {
    creates++;
    return Customer(
      id: 9,
      customerCode: 'CUS000009',
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      mobileNumber: mobileNo.trim(),
      createdDate: DateTime(2026, 10, 11),
    );
  }

  @override
  Future<Customer> uploadPhoto(int customerId, List<int> bytes) async {
    uploads++;
    final error = uploadError;
    if (error != null) throw error;
    return Customer(
      id: customerId,
      customerCode: 'CUS000009',
      firstName: 'Nimal',
      lastName: 'Perera',
      mobileNumber: '0771234567',
      photoPath: 'stored.jpg',
      createdDate: DateTime(2026, 10, 11),
    );
  }
}

class _CaptureClient extends http.BaseClient {
  _CaptureClient(this.body);

  final String body;
  http.BaseRequest? request;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    this.request = request;
    await request.finalize().toBytes();
    return http.StreamedResponse(
      Stream<List<int>>.value(utf8.encode(body)),
      200,
      headers: const {'content-type': 'application/json'},
    );
  }
}
