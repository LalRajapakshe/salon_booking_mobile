import 'package:flutter/material.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/auth/auth_session.dart';
import '../../../core/auth/staff_access.dart';
import '../../../shared/utils/currency_formatter.dart';
import '../../../shared/widgets/widgets.dart';
import '../data/billing_repository.dart';
import '../models/billing_models.dart';
import 'bill_detail_screen.dart';
import 'bill_editor_screen.dart';

class BillsScreen extends StatefulWidget {
  const BillsScreen({super.key, this.repository});

  final BillingRepository? repository;

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> {
  late final BillingRepository _repository = widget.repository ?? BillingRepository();
  List<SalonBill> _bills = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final bills = await _repository.listBills();
      if (!mounted) return;
      setState(() => _bills = bills);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canManage = StaffAccess.canManageBills(AuthSession.instance);
    return AppPage(
      title: 'Bills',
      subtitle: 'Draft, finalized, and void bills',
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const BillEditorScreen()));
                await _load();
              },
              icon: const Icon(Icons.add),
              label: const Text('New bill'),
            )
          : null,
      child: _loading
          ? const AppLoading(message: 'Loading bills')
          : _error != null
              ? AppEmptyState(title: 'Bills unavailable', message: _error!, buttonText: 'Retry', onPressed: _load)
              : _bills.isEmpty
                  ? const AppEmptyState(title: 'No bills', message: 'Completed services and retail sales appear here.')
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        itemCount: _bills.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final bill = _bills[index];
                          return ListTile(
                            tileColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            title: Text(bill.billNumber ?? 'Draft ${bill.id}'),
                            subtitle: Text('${bill.customerName ?? 'Customer ${bill.customerId}'} · ${bill.status} · ${bill.paymentStatus}'),
                            trailing: Text(CurrencyFormatter.formatWithSymbol(bill.total)),
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => BillDetailScreen(billId: bill.id, repository: _repository)),
                              );
                              await _load();
                            },
                          );
                        },
                      ),
                    ),
    );
  }
}
