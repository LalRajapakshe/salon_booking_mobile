import 'package:flutter/material.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/auth/auth_session.dart';
import '../../../core/auth/staff_access.dart';
import '../../../shared/utils/currency_formatter.dart';
import '../../../shared/widgets/widgets.dart';
import '../data/billing_repository.dart';
import '../models/billing_models.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key, this.repository});

  final BillingRepository? repository;

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  late final BillingRepository _repository = widget.repository ?? BillingRepository();
  final _search = TextEditingController();
  List<RetailProduct> _products = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final products = await _repository.listProducts(search: _search.text, includeInactive: true);
      if (!mounted) return;
      setState(() => _products = products);
    } on ApiException catch (error) {
      if (!mounted) return;
      AppSnackBar.error(context, error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _edit([RetailProduct? product]) async {
    if (!StaffAccess.canManageProducts(AuthSession.instance)) return;
    final code = TextEditingController(text: product?.code ?? '');
    final name = TextEditingController(text: product?.name ?? '');
    final price = TextEditingController(text: product == null ? '' : product.sellingPrice.toStringAsFixed(2));
    final description = TextEditingController(text: product?.description ?? '');
    var active = product?.isActive ?? true;
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: Text(product == null ? 'New product' : 'Edit product'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(controller: code, labelText: 'Code'),
                AppTextField(controller: name, labelText: 'Name'),
                AppTextField(controller: price, labelText: 'Selling price', keyboardType: TextInputType.number),
                AppTextField(controller: description, labelText: 'Description'),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active'),
                  value: active,
                  onChanged: product == null ? null : (value) => setLocal(() => active = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
          ],
        ),
      ),
    );
    if (saved != true || !mounted) {
      code.dispose();
      name.dispose();
      price.dispose();
      description.dispose();
      return;
    }
    final sellingPrice = double.tryParse(price.text.trim());
    final codeText = code.text.trim();
    final nameText = name.text.trim();
    if (codeText.isEmpty || codeText.length > 40 || nameText.isEmpty || nameText.length > 100) {
      AppSnackBar.warning(context, 'Enter a product code and name within the allowed length.');
      code.dispose();
      name.dispose();
      price.dispose();
      description.dispose();
      return;
    }
    if (sellingPrice == null || sellingPrice < 0) {
      AppSnackBar.warning(context, 'Enter a selling price of zero or more.');
      code.dispose();
      name.dispose();
      price.dispose();
      description.dispose();
      return;
    }
    try {
      await _repository.saveProduct(
        id: product?.id,
        code: codeText,
        name: nameText,
        sellingPrice: sellingPrice,
        description: description.text,
        isActive: active,
      );
      if (!mounted) return;
      AppSnackBar.success(context, active ? 'Product saved.' : 'Product saved and marked inactive.');
      await _load();
    } on ApiException catch (error) {
      if (!mounted) return;
      AppSnackBar.error(context, error.message);
    } finally {
      code.dispose();
      name.dispose();
      price.dispose();
      description.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final canManage = StaffAccess.canManageProducts(AuthSession.instance);
    return AppPage(
      title: 'Retail products',
      subtitle: 'Catalogue only. Stock is not tracked.',
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () => _edit(),
              icon: const Icon(Icons.add),
              label: const Text('Product'),
            )
          : null,
      child: Column(
        children: [
          AppSearchBox(controller: _search, hintText: 'Search products', onChanged: (_) {}),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(onPressed: _load, child: const Text('Search')),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _loading
                ? const AppLoading(message: 'Loading products')
                : _products.isEmpty
                    ? const AppEmptyState(title: 'No products', message: 'Add a retail product to sell it on a bill.')
                    : ListView.separated(
                        itemCount: _products.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final product = _products[index];
                          return ListTile(
                            tileColor: Colors.white,
                            title: Text(product.name),
                            subtitle: Text(
                              '${product.code}${product.description == null || product.description!.isEmpty ? '' : ' · ${product.description}'}${product.isActive ? '' : ' · Inactive'}',
                            ),
                            trailing: Text(CurrencyFormatter.formatWithSymbol(product.sellingPrice)),
                            onTap: canManage ? () => _edit(product) : null,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
