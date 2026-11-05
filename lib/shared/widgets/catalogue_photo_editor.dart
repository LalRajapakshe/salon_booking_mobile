import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api/api_exception.dart';

class CataloguePhotoEditor extends StatefulWidget {
  final bool hasPhoto;
  final Future<List<int>> Function() load;
  final Future<void> Function(List<int> bytes) upload;
  final Future<void> Function() remove;

  const CataloguePhotoEditor({
    super.key,
    required this.hasPhoto,
    required this.load,
    required this.upload,
    required this.remove,
  });

  @override
  State<CataloguePhotoEditor> createState() => _CataloguePhotoEditorState();
}

class _CataloguePhotoEditorState extends State<CataloguePhotoEditor> {
  List<int>? _bytes;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.hasPhoto) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final bytes = await widget.load();
      if (!mounted) return;
      setState(() {
        _bytes = bytes;
        _busy = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = error.statusCode == 404 ? null : error.message;
      });
    }
  }

  Future<void> _pick() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _bytes = bytes;
      _busy = true;
      _error = null;
    });
    try {
      await widget.upload(bytes);
      if (!mounted) return;
      setState(() => _busy = false);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = error.message;
      });
    }
  }

  Future<void> _remove() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.remove();
      if (!mounted) return;
      setState(() {
        _bytes = null;
        _busy = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = error.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Photograph', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          height: 160,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xffF7F8FC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xffE4E7EE)),
          ),
          child: _busy
              ? const CircularProgressIndicator()
              : _bytes == null
                  ? const Text('No photograph yet')
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        Uint8List.fromList(_bytes!),
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: const TextStyle(color: Colors.red)),
        ],
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: _busy ? null : _pick,
              icon: const Icon(Icons.photo_outlined),
              label: Text(_bytes == null ? 'Upload' : 'Replace'),
            ),
            if (_bytes != null)
              TextButton.icon(
                onPressed: _busy ? null : _remove,
                icon: const Icon(Icons.hide_image_outlined),
                label: const Text('Remove'),
              ),
          ],
        ),
      ],
    );
  }
}
