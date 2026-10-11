import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'customer_photo_picker_stub.dart'
    if (dart.library.js_interop) 'customer_photo_picker_web.dart';

const int customerPhotoMaxBytes = 2097152;

class CustomerPhotoAccessException implements Exception {
  final String message;

  const CustomerPhotoAccessException(this.message);
}

/// Session cache so a customer list does not download the same photo again.
class CustomerPhotoCache {
  final Map<String, Uint8List> _bytes = {};

  Uint8List? read(int customerId, String photoPath) => _bytes[_key(customerId, photoPath)];

  void write(int customerId, String photoPath, Uint8List bytes) {
    _bytes[_key(customerId, photoPath)] = bytes;
  }

  void forget(int customerId) {
    _bytes.removeWhere((key, _) => key.startsWith('$customerId:'));
  }

  String _key(int customerId, String photoPath) => '$customerId:$photoPath';
}

/// Returns an error message when the bytes are not a JPEG, PNG, or WebP within the size limit.
String? validateCustomerPhoto(List<int> bytes) {
  if (bytes.isEmpty) return 'A photo file is required.';
  if (bytes.length > customerPhotoMaxBytes) {
    return 'The photo is larger than 2 MB.';
  }
  if (!_isJpeg(bytes) && !_isPng(bytes) && !_isWebp(bytes)) {
    return 'The photo must be a JPEG, PNG, or WebP image.';
  }
  return null;
}

bool _isJpeg(List<int> bytes) =>
    bytes.length >= 3 && bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF;

bool _isPng(List<int> bytes) =>
    bytes.length >= 8 &&
    bytes[0] == 0x89 &&
    bytes[1] == 0x50 &&
    bytes[2] == 0x4E &&
    bytes[3] == 0x47;

bool _isWebp(List<int> bytes) {
  if (bytes.length < 12) return false;
  return bytes[0] == 0x52 &&
      bytes[1] == 0x49 &&
      bytes[2] == 0x46 &&
      bytes[3] == 0x46 &&
      bytes[8] == 0x57 &&
      bytes[9] == 0x45 &&
      bytes[10] == 0x42 &&
      bytes[11] == 0x50;
}

/// Opens the camera or gallery only when the user asks. A cancelled picker returns null.
Future<Uint8List?> readCustomerPhoto(ImageSource source) async {
  ensureCustomerPhotoPicker();
  try {
    final file = await ImagePicker().pickImage(source: source);
    if (file == null) return null;
    return file.readAsBytes();
  } on PlatformException {
    throw CustomerPhotoAccessException(
      source == ImageSource.camera
          ? 'Camera access was denied or is unavailable. You can still choose a photo.'
          : 'The photo could not be opened. Try another image.',
    );
  } on MissingPluginException {
    throw const CustomerPhotoAccessException(
      'Photo selection is not available in this session. Stop the app and run it again.',
    );
  }
}
