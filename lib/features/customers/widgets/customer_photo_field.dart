import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../photos/customer_camera_stub.dart'
    if (dart.library.js_interop) '../photos/customer_camera_web.dart';
import '../photos/customer_photo_store.dart';

/// Optional photo picker used by customer registration and later by Reception Desk.
class CustomerPhotoField extends StatefulWidget {
  final Uint8List? bytes;
  final String? errorText;
  final bool enabled;
  final String previewCaption;
  final Future<Uint8List?> Function()? choosePhoto;
  final Future<Uint8List?> Function()? takePhoto;
  final ValueChanged<Uint8List> onSelected;
  final ValueChanged<String> onInvalid;
  final VoidCallback? onRemove;

  const CustomerPhotoField({
    super.key,
    required this.bytes,
    required this.onSelected,
    required this.onInvalid,
    this.errorText,
    this.enabled = true,
    this.previewCaption = 'Preview — not saved',
    this.choosePhoto,
    this.takePhoto,
    this.onRemove,
  });

  @override
  State<CustomerPhotoField> createState() => _CustomerPhotoFieldState();
}

class _CustomerPhotoFieldState extends State<CustomerPhotoField> {
  bool _busy = false;

  Future<void> _pick(Future<Uint8List?> Function() source) async {
    if (!widget.enabled || _busy) return;
    setState(() => _busy = true);
    try {
      final bytes = await source();
      if (!mounted || bytes == null) return;
      final error = validateCustomerPhoto(bytes);
      if (error != null) {
        widget.onInvalid(error);
        return;
      }
      widget.onSelected(bytes);
    } on CustomerPhotoAccessException catch (error) {
      widget.onInvalid(error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = widget.bytes != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Profile photo',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        const Text(
          'Optional. Used only for this customer’s salon profile.',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: const Color(0xffE8EEF8),
              backgroundImage: hasPhoto ? MemoryImage(widget.bytes!) : null,
              child: hasPhoto
                  ? null
                  : _busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.person_outline, color: Color(0xff3D4F6F)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: widget.enabled && !_busy
                        ? () => _pick(
                              widget.takePhoto ?? () => captureCustomerPhoto(context),
                            )
                        : null,
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Take Photo'),
                  ),
                  OutlinedButton.icon(
                    onPressed: widget.enabled && !_busy
                        ? () => _pick(
                              widget.choosePhoto ?? () => readCustomerPhoto(ImageSource.gallery),
                            )
                        : null,
                    icon: const Icon(Icons.upload_outlined),
                    label: Text(hasPhoto ? 'Replace' : 'Choose Photo'),
                  ),
                  if (hasPhoto && widget.onRemove != null)
                    TextButton.icon(
                      onPressed: widget.enabled && !_busy ? widget.onRemove : null,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Remove'),
                    ),
                ],
              ),
            ),
          ],
        ),
        if (hasPhoto) ...[
          const SizedBox(height: 8),
          Text(
            widget.previewCaption,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
        if (widget.errorText != null) ...[
          const SizedBox(height: 8),
          Text(widget.errorText!, style: const TextStyle(color: Colors.red)),
        ],
      ],
    );
  }
}
