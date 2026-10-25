import 'package:flutter/material.dart';

import '../../../core/api/api_exception.dart';
import '../../../shared/widgets/app_dialog.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../api/service_api_mapper.dart';
import '../data/service_repository.dart';

class ServiceCategoriesScreen extends StatefulWidget {
  final ServiceRepository? repository;

  const ServiceCategoriesScreen({super.key, this.repository});

  @override
  State<ServiceCategoriesScreen> createState() => _ServiceCategoriesScreenState();
}

class _ServiceCategoriesScreenState extends State<ServiceCategoriesScreen> {
  late final ServiceRepository _repository;
  List<ServiceCategoryRecord> _categories = const [];
  bool _loading = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ServiceRepository();
    if (_repository.isApiBacked) {
      _loading = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _load();
      });
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final categories = await _repository.categories();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error.message;
        _loading = false;
      });
    }
  }

  Future<void> _edit(ServiceCategoryRecord category) async {
    final result = await showDialog<_CategoryDraft>(
      context: context,
      builder: (context) => _CategoryForm(category: category),
    );
    if (result == null || !mounted) return;
    try {
      await _repository.updateCategory(
        ServiceCategoryRecord(
          serviceCategoryId: category.serviceCategoryId,
          categoryCode: category.categoryCode,
          categoryName: result.name,
          description: result.description,
          displayOrder: result.order,
          isActive: result.active,
        ),
      );
      if (!mounted) return;
      AppSnackBar.success(context, '${result.name} was updated.');
      await _load();
    } on ApiException catch (error) {
      if (!mounted) return;
      AppSnackBar.error(context, error.message);
    }
  }

  Future<void> _create() async {
    final result = await showDialog<_CategoryDraft>(
      context: context,
      builder: (context) => const _CategoryForm(),
    );
    if (result == null || !mounted) return;
    try {
      await _repository.createCategory(
        categoryName: result.name,
        description: result.description,
        displayOrder: result.order,
      );
      if (!mounted) return;
      AppSnackBar.success(context, '${result.name} was saved.');
      await _load();
    } on ApiException catch (error) {
      if (!mounted) return;
      AppSnackBar.error(context, error.message);
    }
  }

  Future<void> _view(ServiceCategoryRecord category) {
    return AppDialog.showDetails(
      context: context,
      title: category.categoryName,
      rows: [
        (label: 'Code', value: category.categoryCode.isEmpty ? '—' : category.categoryCode),
        (label: 'Description', value: category.description.isEmpty ? '—' : category.description),
        (label: 'Order', value: '${category.displayOrder}'),
        (label: 'Status', value: category.isActive ? 'Active' : 'Inactive'),
      ],
    );
  }

  Future<void> _confirmDelete(ServiceCategoryRecord category) async {
    final confirmed = await AppDialog.show(
      context: context,
      title: 'Delete Category?',
      message: 'Hide ${category.categoryName} from the list?\n\nThe record stays stored.',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      icon: Icons.delete_outline,
      iconColor: Colors.red,
    );
    if (!mounted || confirmed != true) return;
    try {
      await _repository.deleteCategory(category.serviceCategoryId);
      if (!mounted) return;
      AppSnackBar.success(context, '${category.categoryName} was deleted.');
      await _load();
    } on ApiException catch (error) {
      if (!mounted) return;
      AppSnackBar.error(context, error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F6FA),
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Service Categories',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Groups such as Hair, Nails, and Spa',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _repository.isApiBacked ? _create : null,
                icon: const Icon(Icons.add),
                label: const Text('Add Category'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _body(),
        ],
      ),
    );
  }

  Widget _body() {
    if (!_repository.isApiBacked) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 36),
        child: Text('Sign in to manage categories.', textAlign: TextAlign.center),
      );
    }
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_loadError != null) {
      return Column(
        children: [
          Text(_loadError!, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: _load, child: const Text('Retry')),
        ],
      );
    }
    if (_categories.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 36),
        child: Text('No categories yet.', textAlign: TextAlign.center),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: DataTable(
        headingRowColor: const WidgetStatePropertyAll(Color(0xffF7F8FC)),
        columns: const [
          DataColumn(label: Text('Code')),
          DataColumn(label: Text('Name')),
          DataColumn(label: Text('')),
        ],
        rows: [
          for (final category in _categories)
            DataRow(
              cells: [
                DataCell(Text(category.categoryCode)),
                DataCell(Text(category.categoryName)),
                DataCell(
                  PopupMenuButton<String>(
                    key: ValueKey('category-actions-${category.serviceCategoryId}'),
                    onSelected: (action) {
                      switch (action) {
                        case 'view':
                          _view(category);
                        case 'edit':
                          _edit(category);
                        case 'delete':
                          _confirmDelete(category);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'view', child: Text('View')),
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _CategoryDraft {
  final String name;
  final String description;
  final int order;
  final bool active;

  const _CategoryDraft({
    required this.name,
    required this.description,
    required this.order,
    required this.active,
  });
}

class _CategoryForm extends StatefulWidget {
  final ServiceCategoryRecord? category;

  const _CategoryForm({this.category});

  @override
  State<_CategoryForm> createState() => _CategoryFormState();
}

class _CategoryFormState extends State<_CategoryForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name = TextEditingController(
    text: widget.category?.categoryName ?? '',
  );
  late final TextEditingController _description = TextEditingController(
    text: widget.category?.description ?? '',
  );
  late final TextEditingController _order = TextEditingController(
    text: '${widget.category?.displayOrder ?? 0}',
  );
  late bool _active = widget.category?.isActive ?? true;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _order.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState?.validate() != true) return;
    Navigator.of(context).pop(
      _CategoryDraft(
        name: _name.text.trim(),
        description: _description.text.trim(),
        order: int.parse(_order.text.trim()),
        active: _active,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.category != null;
    return AlertDialog(
      title: Text(editing ? 'Edit Category' : 'Add Category'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (editing)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Code ${widget.category!.categoryCode} stays the same',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              AppTextField(
                controller: _name,
                labelText: 'Name',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Name is required';
                  if (value.trim().length > 100) return 'Name is too long';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _description,
                labelText: 'Description',
                validator: (value) {
                  if ((value ?? '').trim().length > 100) return 'Description is too long';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _order,
                labelText: 'Display order',
                keyboardType: TextInputType.number,
                validator: (value) {
                  final parsed = int.tryParse((value ?? '').trim());
                  if (parsed == null || parsed < 0) return 'Enter 0 or more';
                  return null;
                },
              ),
              if (editing)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active'),
                  value: _active,
                  onChanged: (value) => setState(() => _active = value),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
