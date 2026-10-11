import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/api/api_exception.dart';
import '../data/customer_repository.dart';
import '../models/customer_model.dart';
import 'customer_photo_field.dart';

/// Replace or remove a photo for a customer that is already saved.
Future<Customer?> showCustomerPhotoSheet({
  required BuildContext context,
  required Customer customer,
  required CustomerRepository repository,
}) {
  return showDialog<Customer>(
    context: context,
    builder: (context) => _CustomerPhotoSheet(customer: customer, repository: repository),
  );
}

class _CustomerPhotoSheet extends StatefulWidget {
  final Customer customer;
  final CustomerRepository repository;

  const _CustomerPhotoSheet({required this.customer, required this.repository});

  @override
  State<_CustomerPhotoSheet> createState() => _CustomerPhotoSheetState();
}

class _CustomerPhotoSheetState extends State<_CustomerPhotoSheet> {
  Uint8List? _bytes;
  Uint8List? _savedBytes;
  String? _error;
  bool _loading = false;
  bool _saving = false;
  bool _removeSaved = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final path = widget.customer.photoPath;
    if (path == null || path.isEmpty) return;
    setState(() => _loading = true);
    try {
      final bytes = await widget.repository.fetchPhoto(widget.customer.id, path);
      if (!mounted) return;
      setState(() {
        _savedBytes = bytes;
        _bytes = bytes;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.message;
      });
    }
  }

  Future<void> _save() async {
    final selected = _bytes;
    final changed = selected != _savedBytes || _removeSaved;
    if (!changed) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final Customer saved;
      if (selected == null) {
        saved = await widget.repository.removePhoto(widget.customer.id);
      } else {
        saved = await widget.repository.uploadPhoto(widget.customer.id, selected);
      }
      if (!mounted) return;
      Navigator.of(context).pop(saved);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = error.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final preview = _bytes;
    return AlertDialog(
      title: Text('${widget.customer.fullName} photo'),
      content: SizedBox(
        width: 420,
        child: _loading
            ? const SizedBox(
                height: 80,
                child: Center(child: CircularProgressIndicator()),
              )
            : CustomerPhotoField(
                bytes: preview,
                errorText: _error,
                enabled: !_saving,
                previewCaption: preview == null
                    ? ''
                    : identical(preview, _savedBytes)
                        ? 'Saved photo'
                        : 'Preview — not saved',
                onSelected: (bytes) => setState(() {
                  _bytes = bytes;
                  _removeSaved = false;
                  _error = null;
                }),
                onInvalid: (message) => setState(() => _error = message),
                onRemove: () => setState(() {
                  _bytes = null;
                  _removeSaved = _savedBytes != null;
                  _error = null;
                }),
              ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        FilledButton(
          onPressed: _saving || _loading ? null : _save,
          child: Text(_saving ? 'Saving' : 'Save photo'),
        ),
      ],
    );
  }
}
