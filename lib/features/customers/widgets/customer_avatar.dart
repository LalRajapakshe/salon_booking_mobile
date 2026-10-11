import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../data/customer_repository.dart';
import '../models/customer_model.dart';

/// Shows a saved customer photo, or initials when there is none.
class CustomerAvatar extends StatefulWidget {
  final Customer customer;
  final CustomerRepository? repository;
  final double radius;

  const CustomerAvatar({
    super.key,
    required this.customer,
    this.repository,
    this.radius = 18,
  });

  @override
  State<CustomerAvatar> createState() => _CustomerAvatarState();
}

class _CustomerAvatarState extends State<CustomerAvatar> {
  Uint8List? _bytes;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _bytes = _cached();
    if (_bytes == null && _shouldFetch) {
      _load();
    }
  }

  @override
  void didUpdateWidget(CustomerAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.customer.id != widget.customer.id ||
        oldWidget.customer.photoPath != widget.customer.photoPath) {
      _load();
    }
  }

  bool get _shouldFetch {
    final repository = widget.repository;
    final path = widget.customer.photoPath;
    return repository != null && repository.isApiBacked && path != null && path.isNotEmpty;
  }

  Uint8List? _cached() {
    final repository = widget.repository;
    final path = widget.customer.photoPath;
    if (repository == null || path == null || path.isEmpty) return null;
    return repository.photos.read(widget.customer.id, path);
  }

  Future<void> _load() async {
    final repository = widget.repository;
    final path = widget.customer.photoPath;
    if (!_shouldFetch || repository == null || path == null) {
      if (mounted) {
        setState(() {
          _bytes = null;
          _loading = false;
        });
      }
      return;
    }

    final cached = repository.photos.read(widget.customer.id, path);
    if (cached != null) {
      if (mounted) {
        setState(() {
          _bytes = cached;
          _loading = false;
        });
      }
      return;
    }

    setState(() => _loading = true);
    try {
      final bytes = await repository.fetchPhoto(widget.customer.id, path);
      if (!mounted || widget.customer.photoPath != path) return;
      setState(() {
        _bytes = bytes;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _bytes = null;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final initials = _initials(widget.customer.fullName);
    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: const Color(0xffE8EEF8),
      backgroundImage: _bytes == null ? null : MemoryImage(_bytes!),
      child: _bytes != null
          ? null
          : _loading
              ? SizedBox(
                  width: widget.radius,
                  height: widget.radius,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  initials,
                  style: TextStyle(
                    fontSize: widget.radius * 0.7,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xff3D4F6F),
                  ),
                ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return '${parts.first.characters.first}${parts.last.characters.first}'.toUpperCase();
  }
}
