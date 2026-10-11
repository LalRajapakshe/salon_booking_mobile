import 'package:image_picker_for_web/image_picker_for_web.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

void ensureCustomerPhotoPicker() {
  if (ImagePickerPlatform.instance is ImagePickerPlugin) return;
  ImagePickerPlatform.instance = ImagePickerPlugin();
}
