import 'package:flutter/material.dart';

import '../../../core/api/api_exception.dart';
import '../../../shared/widgets/app_primary_button.dart';
import '../../../shared/widgets/app_secondary_button.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../appointments/data/mock_appointment_data.dart';
import '../api/service_api_mapper.dart';
import '../data/service_directory.dart';
import '../data/service_repository.dart';
import '../models/service_management_models.dart';
import '../widgets/service_form.dart';

class CreateServiceScreen extends StatefulWidget {
  final ServiceDirectory directory;
  final SalonService? service;
  final bool persistToApi;
  final ServiceRepository? services;

  const CreateServiceScreen({
    super.key,
    required this.directory,
    this.service,
    this.persistToApi = false,
    this.services,
  });

  bool get isEditing => service != null;

  @override
  State<CreateServiceScreen> createState() => _CreateServiceScreenState();
}

class _CreateServiceScreenState extends State<CreateServiceScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String? _category;
  int? _branchId;
  bool _isActive = true;
  bool _validateOnInteraction = false;
  bool _saving = false;
  String? _saveError;
  bool _loadingCategories = false;
  String? _categoryError;
  List<ServiceCategoryRecord> _categories = [];
  late final ServiceRepository _services;

  bool get _apiCreate => widget.persistToApi && !widget.isEditing;

  @override
  void initState() {
    super.initState();
    _services = widget.services ?? ServiceRepository();
    if (_apiCreate) {
      _loadingCategories = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadCategories();
      });
    }
    final service = widget.service;
    if (service != null) {
      _codeController.text = service.serviceCode;
      _nameController.text = service.serviceName;
      _durationController.text = service.durationMinutes.toString();
      _priceController.text = priceInputText(service.price);
      _descriptionController.text = service.description;
      _category = service.categoryName;
      _branchId = service.branchId;
      _isActive = service.isActive;
    } else if (mockBranches.isNotEmpty) {
      _branchId = mockBranches.first.branchId;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _codeController.dispose();
    _nameController.dispose();
    _durationController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _cancel() {
    Navigator.of(context).pop();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _loadingCategories = true;
      _categoryError = null;
    });
    try {
      final categories = await _services.categories();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _loadingCategories = false;
        if (_category != null &&
            !categories.any((item) => item.categoryName == _category)) {
          _category = null;
        }
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingCategories = false;
        _categoryError = error.message;
      });
    }
  }

  Future<void> _save() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      setState(() => _validateOnInteraction = true);
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
      return;
    }

    final category = _category;
    final branchId = _branchId;
    final duration = tryParseDuration(_durationController.text);
    final price = tryParsePrice(_priceController.text);
    if (category == null ||
        (!_apiCreate && branchId == null) ||
        duration == null ||
        price == null) {
      setState(() => _validateOnInteraction = true);
      return;
    }

    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final existing = widget.service;

    if (_apiCreate) {
      final matches = _categories.where((item) => item.categoryName == category);
      if (matches.isEmpty) {
        setState(() => _saveError = 'Category is required');
        return;
      }
      setState(() {
        _saving = true;
        _saveError = null;
      });
      try {
        final created = await _services.create(
          serviceCategoryId: matches.first.serviceCategoryId,
          serviceName: name,
          description: description,
          durationMinutes: duration,
          price: price,
          categoryName: category,
        );
        if (!mounted) return;
        AppSnackBar.success(context, '${created.serviceName} was saved.');
        Navigator.of(context).pop(created);
      } on ApiException catch (error) {
        if (!mounted) return;
        setState(() {
          _saving = false;
          _saveError = error.message;
        });
      }
      return;
    }

    if (branchId == null) return;

    final SalonService saved;
    if (existing == null) {
      saved = widget.directory.add(
        SalonService(
          serviceId: 0,
          serviceCode: '',
          serviceName: name,
          durationMinutes: duration,
          price: price,
          branchId: branchId,
          categoryName: category,
          description: description,
          isActive: _isActive,
          createdDate: DateTime.now(),
        ),
      );
      AppSnackBar.success(context, '$name was saved.');
    } else {
      saved = existing.copyWith(
        serviceName: name,
        durationMinutes: duration,
        price: price,
        branchId: branchId,
        categoryName: category,
        description: description,
        isActive: _isActive,
      );
      widget.directory.update(saved);
      AppSnackBar.success(context, '$name was updated.');
    }

    Navigator.of(context).pop(saved);
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.isEditing;
    final title = editing ? 'Edit Service' : 'Create Service';
    final subtitle = editing
        ? 'Update the name, price, duration, or availability.'
        : 'Add a service clients can book, with a duration and price.';

    return Scaffold(
      backgroundColor: const Color(0xffF4F6FA),
      appBar: AppBar(
        elevation: 0,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final padding = constraints.maxWidth < 520 ? 16.0 : 24.0;
          if (_apiCreate && _loadingCategories) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_apiCreate && _categoryError != null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_categoryError!, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _loadCategories,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          return SingleChildScrollView(
            controller: _scrollController,
            padding: EdgeInsets.all(padding),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 840),
                child: Form(
                  key: _formKey,
                  autovalidateMode: _validateOnInteraction
                      ? AutovalidateMode.onUserInteraction
                      : AutovalidateMode.disabled,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: LayoutBuilder(
                            builder: (context, cardConstraints) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  ServiceForm(
                                    serviceCodeController: editing
                                        ? _codeController
                                        : null,
                                    nameController: _nameController,
                                    durationController: _durationController,
                                    priceController: _priceController,
                                    descriptionController:
                                        _descriptionController,
                                    category: _category,
                                    categories: _apiCreate
                                        ? {
                                            for (final item in _categories)
                                              item.categoryName,
                                          }.toList()
                                        : null,
                                    onCategoryChanged: (value) {
                                      setState(() => _category = value);
                                    },
                                    showBranch: !_apiCreate,
                                    branchId: _branchId,
                                    branches: mockBranches,
                                    onBranchChanged: (value) {
                                      setState(() => _branchId = value);
                                    },
                                    isActive: _isActive,
                                    activeLocked: _apiCreate,
                                    onActiveChanged: (value) {
                                      setState(() => _isActive = value);
                                    },
                                  ),
                                  if (_saveError != null) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      _saveError!,
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  _buildActions(cardConstraints.maxWidth),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActions(double maxWidth) {
    final cancel = AppSecondaryButton(
      text: 'Cancel',
      icon: Icons.close,
      width: maxWidth < 520 ? double.infinity : 160,
      onPressed: _saving ? null : _cancel,
    );
    final save = AppPrimaryButton(
      text: 'Save',
      icon: Icons.check,
      width: maxWidth < 520 ? double.infinity : 160,
      isLoading: _saving,
      onPressed: _saving ? null : _save,
    );

    if (maxWidth < 520) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [save, const SizedBox(height: 12), cancel],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [cancel, const SizedBox(width: 12), save],
    );
  }
}
