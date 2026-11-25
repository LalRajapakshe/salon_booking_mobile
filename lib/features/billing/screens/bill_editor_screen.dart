import 'package:flutter/material.dart';

import '../../../core/api/api_exception.dart';
import '../../../shared/utils/currency_formatter.dart';
import '../../../shared/widgets/widgets.dart';
import '../../customers/data/customer_repository.dart';
import '../../customers/models/customer_model.dart';
import '../data/billing_repository.dart';
import '../models/billing_models.dart';
import 'bill_detail_screen.dart';

class BillEditorScreen extends StatefulWidget {
  const BillEditorScreen({
    super.key,
    this.customerId,
    this.customerName,
    this.appointmentId,
    this.repository,
    this.customers,
  });

  final int? customerId;
  final String? customerName;
  final int? appointmentId;
  final BillingRepository? repository;
  final CustomerRepository? customers;

  @override
  State<BillEditorScreen> createState() => _BillEditorScreenState();
}

class _BillEditorScreenState extends State<BillEditorScreen> {
  late final BillingRepository _billing = widget.repository ?? BillingRepository();
  late final CustomerRepository _customers = widget.customers ?? CustomerRepository();
  final _selectedServices = <int>{};
  final _productQty = <int, int>{};
  List<EligibleServiceLine> _services = [];
  List<RetailProduct> _products = [];
  List<Customer> _customerChoices = [];
  int? _customerId;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _customerId = widget.customerId;
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      List<RetailProduct> products = [];
      try {
        products = await _billing.listProducts();
      } on ApiException {
        products = [];
      }
      final services = widget.appointmentId == null
          ? <EligibleServiceLine>[]
          : await _billing.eligibleServices(widget.appointmentId!);
      List<Customer> customers = [];
      if (widget.customerId == null) {
        try {
          customers = await _customers.list();
        } on ApiException {
          customers = [];
        }
      }
      if (!mounted) return;
      setState(() {
        _products = products;
        _services = services;
        _customerChoices = customers;
        _selectedServices.addAll(services.map((line) => line.appointmentServiceId));
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      AppSnackBar.error(context, error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _create() async {
    final customerId = _customerId;
    if (customerId == null) {
      AppSnackBar.warning(context, 'Choose a customer.');
      return;
    }
    final products = [
      for (final entry in _productQty.entries)
        if (entry.value > 0) {'retailProductId': entry.key, 'quantity': entry.value},
    ];
    final selected = _customerChoices.where((customer) => customer.id == customerId);
    final branchId = selected.isEmpty ? null : selected.first.branchId;
    setState(() => _saving = true);
    try {
      final bill = await _billing.createBill(
        customerId: customerId,
        branchId: branchId,
        appointmentId: widget.appointmentId,
        appointmentServiceIds: _selectedServices.toList(),
        products: products,
      );
      if (!mounted) return;
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => BillDetailScreen(billId: bill.id, repository: _billing)),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      AppSnackBar.error(context, error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: widget.appointmentId == null ? 'New bill' : 'Bill appointment',
      subtitle: widget.customerName,
      child: _loading
          ? const AppLoading(message: 'Loading billable items')
          : ListView(
              children: [
                if (widget.customerId == null)
                  DropdownButtonFormField<int>(
                    value: _customerId,
                    decoration: const InputDecoration(labelText: 'Customer'),
                    items: [
                      for (final customer in _customerChoices)
                        DropdownMenuItem(value: customer.id, child: Text(customer.fullName)),
                    ],
                    onChanged: (value) => setState(() => _customerId = value),
                  ),
                if (widget.appointmentId != null) ...[
                  const SizedBox(height: 12),
                  Text('Completed services', style: Theme.of(context).textTheme.titleMedium),
                  if (_services.isEmpty) const Text('No unbilled completed services.'),
                  for (final line in _services)
                    CheckboxListTile(
                      value: _selectedServices.contains(line.appointmentServiceId),
                      title: Text(line.serviceName),
                      subtitle: Text(CurrencyFormatter.formatWithSymbol(line.unitPrice)),
                      onChanged: (checked) {
                        setState(() {
                          if (checked == true) {
                            _selectedServices.add(line.appointmentServiceId);
                          } else {
                            _selectedServices.remove(line.appointmentServiceId);
                          }
                        });
                      },
                    ),
                ],
                const SizedBox(height: 12),
                const Text('A draft can be saved with no lines. A returned rental can be the first line on the next screen.'),
                const SizedBox(height: 12),
                Text('Retail products', style: Theme.of(context).textTheme.titleMedium),
                if (_products.isEmpty) const Text('No active products in this branch.'),
                for (final product in _products)
                  ListTile(
                    title: Text(product.name),
                    subtitle: Text('${product.code} · ${CurrencyFormatter.formatWithSymbol(product.sellingPrice)}'),
                    trailing: SizedBox(
                      width: 120,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            onPressed: () => setState(() {
                              final next = (_productQty[product.id] ?? 0) - 1;
                              if (next <= 0) {
                                _productQty.remove(product.id);
                              } else {
                                _productQty[product.id] = next;
                              }
                            }),
                            icon: const Icon(Icons.remove),
                          ),
                          Text('${_productQty[product.id] ?? 0}'),
                          IconButton(
                            onPressed: () => setState(() {
                              _productQty[product.id] = (_productQty[product.id] ?? 0) + 1;
                            }),
                            icon: const Icon(Icons.add),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                AppPrimaryButton(text: 'Create draft', isLoading: _saving, onPressed: _create),
              ],
            ),
    );
  }
}
