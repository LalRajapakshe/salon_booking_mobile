import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';

import 'customer_photo_store.dart';

Future<Uint8List?> captureCustomerPhoto(BuildContext context) {
  return readCustomerPhoto(ImageSource.camera);
}
