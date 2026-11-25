import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/auth/auth_session.dart';
import '../../../core/auth/staff_access.dart';
import '../../../shared/utils/currency_formatter.dart';
import '../../../shared/widgets/widgets.dart';
import '../../rentals/data/rental_repository.dart';
import '../data/billing_repository.dart';
import '../models/billing_models.dart';

class BillDetailScreen extends StatefulWidget {
  const BillDetailScreen({super.key, required this.billId, this.repository, this.rentals});

  final int billId;
  final BillingRepository? repository;
  final RentalRepository? rentals;

  @override
  State<BillDetailScreen> createState() => _BillDetailScreenState();
}

class _BillDetailScreenState extends State<BillDetailScreen> {
  late final BillingRepository _repository = widget.repository ?? BillingRepository();
  late final RentalRepository _rentals = widget.rentals ?? RentalRepository();
  SalonBill? _bill;
  bool _loading = true;
  bool _busy = false;
  final _amount = TextEditingController();
  final _reason = TextEditingController();
  String _method = 'Cash';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _amount.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final bill = await _repository.getBill(widget.billId);
      if (!mounted) return;
      setState(() => _bill = bill);
    } on ApiException catch (error) {
      if (!mounted) return;
      AppSnackBar.error(context, error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _run(Future<SalonBill> Function() action) async {
    setState(() => _busy = true);
    try {
      final bill = await action();
      if (!mounted) return;
      setState(() => _bill = bill);
      AppSnackBar.success(context, 'Bill updated.');
    } on ApiException catch (error) {
      if (!mounted) return;
      AppSnackBar.error(context, error.message);
      await _load();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addRental(SalonBill bill) async {
    List<RentalReservation> reservations;
    try {
      reservations = await _rentals.reservations();
    } on ApiException catch (error) {
      if (!mounted) return;
      AppSnackBar.error(context, error.message);
      return;
    } catch (error) {
      if (!mounted) return;
      AppSnackBar.error(context, error.toString());
      return;
    }
    final choices = reservations.where((reservation) {
      return reservation.isBillable &&
          reservation.customerId == bill.customerId &&
          reservation.branchId == bill.branchId;
    }).toList();
    if (!mounted) return;
    if (choices.isEmpty) {
      AppSnackBar.warning(context, 'No returned rental is waiting to be billed for this customer.');
      return;
    }
    var reservationId = choices.first.id;
    final chosen = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Add returned rental'),
          content: DropdownButtonFormField<int>(
            value: reservationId,
            decoration: const InputDecoration(labelText: 'Returned rental'),
            items: [
              for (final reservation in choices)
                DropdownMenuItem(
                  value: reservation.id,
                  child: Text('${reservation.assetName} · ${reservation.chargePerUse.toStringAsFixed(2)}'),
                ),
            ],
            onChanged: (value) => setLocal(() => reservationId = value ?? reservationId),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Add')),
          ],
        ),
      ),
    );
    if (chosen != true || !mounted) return;
    await _run(() => _repository.addRental(
          billId: bill.id,
          rowVersion: bill.rowVersion,
          reservationId: reservationId,
        ));
  }

  Future<void> _addProduct(SalonBill bill) async {
    List<RetailProduct> products;
    try {
      products = await _repository.listProducts();
    } on ApiException catch (error) {
      if (!mounted) return;
      AppSnackBar.error(context, error.message);
      return;
    }
    if (!mounted) return;
    final active = products.where((product) => product.isActive).toList();
    if (active.isEmpty) {
      AppSnackBar.warning(context, 'No active products in this branch.');
      return;
    }
    var productId = active.first.id;
    final quantity = TextEditingController(text: '1');
    final chosen = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Add product'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: productId,
                decoration: const InputDecoration(labelText: 'Product'),
                items: [
                  for (final product in active)
                    DropdownMenuItem(value: product.id, child: Text(product.name)),
                ],
                onChanged: (value) => setLocal(() => productId = value ?? productId),
              ),
              AppTextField(controller: quantity, labelText: 'Quantity', keyboardType: TextInputType.number),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Add')),
          ],
        ),
      ),
    );
    final qty = int.tryParse(quantity.text.trim()) ?? 0;
    quantity.dispose();
    if (chosen != true || !mounted) return;
    if (qty < 1) {
      AppSnackBar.warning(context, 'Quantity must be at least 1.');
      return;
    }
    await _run(() => _repository.addProduct(
          billId: bill.id,
          rowVersion: bill.rowVersion,
          productId: productId,
          quantity: qty,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final bill = _bill;
    final session = AuthSession.instance;
    return AppPage(
      title: bill?.billNumber ?? 'Bill',
      actions: [
        IconButton(
          tooltip: 'Copy receipt',
          onPressed: bill == null
              ? null
              : () async {
                  await Clipboard.setData(ClipboardData(text: bill.receiptText));
                  if (!context.mounted) return;
                  AppSnackBar.success(context, 'Receipt copied.');
                },
          icon: const Icon(Icons.share_outlined),
        ),
      ],
      child: _loading || bill == null
          ? const AppLoading(message: 'Loading bill')
          : ListView(
              children: [
                Text(bill.customerName ?? 'Customer ${bill.customerId}', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text('${bill.status} · ${bill.paymentStatus}'),
                const SizedBox(height: 12),
                for (final line in bill.lines)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(line.description),
                    subtitle: Text('${line.lineType} · ${line.quantity} × ${CurrencyFormatter.format(line.unitPrice)}'),
                    trailing: Text(CurrencyFormatter.formatWithSymbol(line.lineTotal)),
                  ),
                const Divider(),
                Text('Subtotal ${CurrencyFormatter.formatWithSymbol(bill.subtotal)}'),
                Text(
                  bill.lines.isEmpty
                      ? 'Tax ${CurrencyFormatter.formatWithSymbol(bill.taxAmount)}'
                      : 'Tax ${bill.lines.first.taxRatePercent.toStringAsFixed(2)}% · ${CurrencyFormatter.formatWithSymbol(bill.taxAmount)}',
                ),
                Text('Total ${CurrencyFormatter.formatWithSymbol(bill.total)}'),
                Text('Collected ${CurrencyFormatter.formatWithSymbol(bill.netCollected)}'),
                Text('Outstanding ${CurrencyFormatter.formatWithSymbol(bill.outstanding)}'),
                if (bill.isFinalized && bill.netCollected != 0 && StaffAccess.canManageBills(session))
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text('Void is available after the collected amount has been refunded.'),
                  ),
                if (bill.voidReason != null) Text('Void reason: ${bill.voidReason}'),
                const SizedBox(height: 12),
                const Text('Payments and refunds'),
                if (bill.payments.isEmpty) const Text('None yet.'),
                for (final payment in bill.payments)
                  Text('${payment.kind} ${payment.method} ${CurrencyFormatter.formatWithSymbol(payment.amount)}'),
                const SizedBox(height: 16),
                if (bill.isDraft && StaffAccess.canManageBills(session)) ...[
                  if (StaffAccess.seesProducts(session))
                    AppSecondaryButton(
                      text: 'Add product',
                      onPressed: _busy ? null : () => _addProduct(bill),
                    ),
                  if (StaffAccess.seesRentals(session))
                    AppSecondaryButton(
                      text: 'Add rental',
                      onPressed: _busy ? null : () => _addRental(bill),
                    ),
                  const SizedBox(height: 8),
                  AppPrimaryButton(
                    text: 'Finalize',
                    isLoading: _busy,
                    onPressed: () => _run(() => _repository.finalize(bill.id, bill.rowVersion)),
                  ),
                  const SizedBox(height: 8),
                  for (final line in bill.lines)
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => _run(() => _repository.removeLine(
                                billId: bill.id,
                                lineId: line.id,
                                rowVersion: bill.rowVersion,
                              )),
                      child: Text('Remove ${line.description}'),
                    ),
                ],
                if (bill.isFinalized && StaffAccess.canCollectPayments(session)) ...[
                  DropdownButtonFormField<String>(
                    value: _method,
                    decoration: const InputDecoration(labelText: 'Method'),
                    items: const ['Cash', 'Card', 'BankTransfer', 'Other']
                        .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                        .toList(),
                    onChanged: (value) => setState(() => _method = value ?? 'Cash'),
                  ),
                  AppTextField(controller: _amount, labelText: 'Amount', keyboardType: TextInputType.number),
                  const SizedBox(height: 8),
                  AppPrimaryButton(
                    text: 'Record payment',
                    isLoading: _busy,
                    onPressed: () => _run(() => _repository.pay(
                          billId: bill.id,
                          rowVersion: bill.rowVersion,
                          method: _method,
                          amount: double.tryParse(_amount.text) ?? 0,
                        )),
                  ),
                  const SizedBox(height: 8),
                  AppSecondaryButton(
                    text: 'Record refund',
                    onPressed: _busy
                        ? null
                        : () => _run(() => _repository.refund(
                              billId: bill.id,
                              rowVersion: bill.rowVersion,
                              method: _method,
                              amount: double.tryParse(_amount.text) ?? 0,
                            )),
                  ),
                ],
                if (!bill.isVoid && StaffAccess.canManageBills(session) && bill.netCollected == 0) ...[
                  const SizedBox(height: 8),
                  AppTextField(controller: _reason, labelText: 'Void reason'),
                  const SizedBox(height: 8),
                  AppSecondaryButton(
                    text: 'Void bill',
                    onPressed: _busy
                        ? null
                        : () => _run(() => _repository.voidBill(
                              billId: bill.id,
                              rowVersion: bill.rowVersion,
                              reason: _reason.text,
                            )),
                  ),
                ],
              ],
            ),
    );
  }
}
