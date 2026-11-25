import 'package:flutter/material.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/auth/auth_session.dart';
import '../../../core/auth/staff_access.dart';
import '../../../shared/widgets/widgets.dart';
import '../data/billing_repository.dart';
import '../models/billing_models.dart';

class TaxScreen extends StatefulWidget {
  const TaxScreen({super.key, this.repository});

  final BillingRepository? repository;

  @override
  State<TaxScreen> createState() => _TaxScreenState();
}

class _TaxScreenState extends State<TaxScreen> {
  late final BillingRepository _repository = widget.repository ?? BillingRepository();
  final _name = TextEditingController();
  final _rate = TextEditingController();
  TaxSetting? _setting;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _rate.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final session = AuthSession.instance;
    if (!StaffAccess.seesTax(session)) {
      setState(() {
        _loading = false;
        _error = 'You do not have permission to view tax settings.';
      });
      return;
    }
    final branchId = session.branchId;
    if (branchId == null || branchId <= 0) {
      setState(() {
        _loading = false;
        _error = 'This account is not assigned to a branch, so the branch tax rate cannot be shown.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final setting = await _repository.getTax(branchId);
      if (!mounted) return;
      _apply(setting);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _apply(TaxSetting setting) {
    _setting = setting;
    _name.text = setting.name;
    _rate.text = setting.ratePercent.toStringAsFixed(2);
  }

  Future<void> _save() async {
    final session = AuthSession.instance;
    final branchId = session.branchId;
    if (!StaffAccess.canManageTax(session) || branchId == null) return;
    final name = _name.text.trim();
    if (name.isEmpty || name.length > 80) {
      AppSnackBar.warning(context, 'Enter a tax name of up to 80 characters.');
      return;
    }
    final raw = _rate.text.trim();
    final rate = double.tryParse(raw);
    final decimals = raw.contains('.') ? raw.split('.').last.length : 0;
    if (rate == null || rate < 0 || rate > 100 || decimals > 2) {
      AppSnackBar.warning(context, 'Enter a tax percentage from 0 to 100, with at most two decimal places.');
      return;
    }

    setState(() => _saving = true);
    try {
      final saved = await _repository.saveTax(branchId: branchId, name: name, ratePercent: rate);
      if (!mounted) return;
      setState(() => _apply(saved));
      AppSnackBar.success(
        context,
        'Tax saved. ${saved.name} is now ${saved.ratePercent.toStringAsFixed(2)}% for this branch.',
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
    final setting = _setting;
    final canManage = StaffAccess.canManageTax(AuthSession.instance);
    final configured = setting?.configured == true;
    final rateText = setting == null ? '0.00' : setting.ratePercent.toStringAsFixed(2);
    return AppPage(
      title: 'Tax',
      subtitle: 'Branch rate used when a bill is saved',
      child: _loading
          ? const AppLoading(message: 'Loading tax')
          : _error != null
              ? AppEmptyState(title: 'Tax unavailable', message: _error!, buttonText: 'Retry', onPressed: _load)
              : ListView(
                  children: [
                    Text(
                      configured
                          ? 'Current rate: ${setting!.name} $rateText%'
                          : 'No tax is configured. The rate used on new bills is 0.00%.',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text('Finalized bills keep the rate they were saved with. This does not change them.'),
                    if (canManage) ...[
                      const SizedBox(height: 16),
                      AppTextField(controller: _name, labelText: 'Tax name'),
                      AppTextField(
                        controller: _rate,
                        labelText: 'Percentage',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                      const SizedBox(height: 12),
                      AppPrimaryButton(text: 'Save tax', isLoading: _saving, onPressed: _save),
                    ],
                  ],
                ),
    );
  }
}
