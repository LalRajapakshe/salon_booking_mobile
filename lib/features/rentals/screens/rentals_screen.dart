import 'package:flutter/material.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/auth/auth_session.dart';
import '../../../core/auth/staff_access.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../branches/data/branch_repository.dart';
import '../../customers/data/customer_repository.dart';
import '../data/rental_repository.dart';

class RentalsScreen extends StatefulWidget {
  const RentalsScreen({
    super.key,
    this.repository,
    this.loadBranches,
    this.loadCustomers,
  });

  final RentalRepository? repository;
  final Future<List<RentalBranchChoice>> Function()? loadBranches;
  final Future<List<RentalCustomerChoice>> Function()? loadCustomers;

  @override
  State<RentalsScreen> createState() => _RentalsScreenState();
}

class _RentalsScreenState extends State<RentalsScreen> {
  late final RentalRepository _repository = widget.repository ?? RentalRepository();
  List<RentalAsset> _assets = [];
  List<RentalReservation> _reservations = [];
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    if (StaffAccess.seesRentals(AuthSession.instance)) {
      _load();
    } else {
      _loading = false;
    }
  }

  Future<List<RentalBranchChoice>> _branches() {
    final loader = widget.loadBranches;
    if (loader != null) return loader();
    return BranchRepository().list().then(
          (rows) => [
            for (final branch in rows)
              if (branch.isActive) RentalBranchChoice(id: branch.id, name: branch.branchName),
          ],
        );
  }

  Future<List<RentalCustomerChoice>> _customers() {
    final loader = widget.loadCustomers;
    if (loader != null) return loader();
    return CustomerRepository().list().then(
          (rows) => [
            for (final customer in rows)
              if (customer.isActive)
                RentalCustomerChoice(id: customer.id, name: customer.fullName, branchId: customer.branchId),
          ],
        );
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final assets = await _repository.assets();
      final reservations = await _repository.reservations();
      if (!mounted) return;
      setState(() {
        _assets = assets;
        _reservations = reservations;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error is ApiException ? error.message : error.toString();
        _loading = false;
      });
    }
  }

  Future<int?> _branchForNewAsset() async {
    final locked = AuthSession.instance.branchId;
    if (locked != null && locked > 0) return locked;
    List<RentalBranchChoice> branches;
    try {
      branches = await _branches();
    } catch (error) {
      if (mounted) AppSnackBar.error(context, error is ApiException ? error.message : error.toString());
      return null;
    }
    if (!mounted) return null;
    if (branches.isEmpty) {
      AppSnackBar.warning(context, 'Choose a branch before creating a rental asset.');
      return null;
    }
    var branchId = branches.first.id;
    final chosen = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Branch'),
          content: DropdownButtonFormField<int>(
            value: branchId,
            decoration: const InputDecoration(labelText: 'Branch'),
            items: [
              for (final branch in branches)
                DropdownMenuItem(value: branch.id, child: Text(branch.name)),
            ],
            onChanged: (value) => setLocal(() => branchId = value ?? branchId),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Continue')),
          ],
        ),
      ),
    );
    return chosen == true ? branchId : null;
  }

  Future<void> _editAsset([RentalAsset? asset]) async {
    if (!StaffAccess.canManageRentals(AuthSession.instance)) return;
    final branchId = asset?.branchId ?? await _branchForNewAsset();
    if (branchId == null || branchId <= 0 || !mounted) return;
    final saved = await showDialog<_AssetDraft>(
      context: context,
      builder: (context) => _AssetDialog(asset: asset),
    );
    if (saved == null || !mounted) return;
    final chargeValue = double.tryParse(saved.charge);
    final bufferValue = int.tryParse(saved.buffer);
    final codeText = saved.code;
    final nameText = saved.name;
    final categoryText = saved.category;
    final active = saved.active;
    if (codeText.isEmpty || nameText.isEmpty || categoryText.isEmpty || chargeValue == null || chargeValue < 0 || bufferValue == null || bufferValue < 0) {
      AppSnackBar.warning(context, 'Enter a code, name, category, charge, and cleaning buffer.');
      return;
    }
    try {
      await _repository.saveAsset(
        id: asset?.id,
        branchId: branchId,
        code: codeText,
        name: nameText,
        category: categoryText,
        chargePerUse: chargeValue,
        cleaningBufferMinutes: bufferValue,
        isActive: asset == null ? true : active,
      );
      if (!mounted) return;
      AppSnackBar.success(context, active ? 'Rental asset saved.' : 'Rental asset saved and marked inactive.');
      await _load();
    } catch (error) {
      if (mounted) AppSnackBar.error(context, error is ApiException ? error.message : error.toString());
    }
  }

  Future<void> _reserve(RentalAsset asset) async {
    if (asset.availability == 'Inactive' || asset.availability == 'Maintenance') {
      AppSnackBar.warning(context, 'That asset is not available to reserve.');
      return;
    }
    List<RentalCustomerChoice> customers;
    try {
      customers = await _customers();
    } catch (error) {
      if (mounted) AppSnackBar.error(context, error is ApiException ? error.message : error.toString());
      return;
    }
    final inBranch = customers.where((customer) => customer.branchId == asset.branchId).toList();
    if (!mounted) return;
    if (inBranch.isEmpty) {
      AppSnackBar.warning(context, 'No active customer is available in this branch.');
      return;
    }
    final start = DateTime.now().add(const Duration(hours: 1));
    final saved = await showDialog<_ReservationDraft>(
      context: context,
      builder: (context) => _ReserveDialog(
        assetName: asset.name,
        customers: inBranch,
        issueText: _formatLocal(start),
        returnText: _formatLocal(start.add(const Duration(hours: 4))),
        cleaningBufferMinutes: asset.cleaningBufferMinutes,
      ),
    );
    if (saved == null || !mounted) return;
    final customerId = saved.customerId;
    final issueAt = _parseLocal(saved.issueText);
    final returnAt = _parseLocal(saved.returnText);
    if (issueAt == null || returnAt == null || !returnAt.isAfter(issueAt)) {
      AppSnackBar.warning(context, 'The return time must be after the issue time.');
      return;
    }
    try {
      await _repository.reserve(
        customerId: customerId,
        assetId: asset.id,
        issueAt: issueAt,
        returnAt: returnAt,
      );
      await _load();
    } catch (error) {
      if (mounted) AppSnackBar.error(context, error is ApiException ? error.message : error.toString());
    }
  }

  Future<void> _move(RentalReservation reservation, String action) async {
    var conditionText = '';
    var noteText = '';
    if (action != 'cancel') {
      final movement = await showDialog<_MovementDraft>(
        context: context,
        builder: (context) => _MovementDialog(returning: action == 'return'),
      );
      if (movement == null) return;
      conditionText = movement.condition;
      noteText = movement.notes;
    }
    if (action != 'cancel' && conditionText.isEmpty) {
      if (mounted) AppSnackBar.warning(context, 'Record the condition.');
      return;
    }
    try {
      if (action == 'cancel') {
        await _repository.cancel(reservation.id);
      } else if (action == 'issue') {
        await _repository.issue(reservation.id, conditionText, notes: noteText);
      } else {
        await _repository.returned(reservation.id, conditionText, notes: noteText);
      }
      await _load();
    } catch (error) {
      if (mounted) AppSnackBar.error(context, error is ApiException ? error.message : error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = AuthSession.instance;
    final canManage = StaffAccess.canManageRentals(session);
    final canIssue = StaffAccess.canIssueRentals(session);
    if (!StaffAccess.seesRentals(session)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Rentals')),
        body: const Center(child: Text('You do not have permission to view rentals.')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rentals'),
        actions: [
          IconButton(tooltip: 'Refresh', onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      floatingActionButton: canManage
          ? FloatingActionButton(onPressed: () => _editAsset(), child: const Icon(Icons.add))
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!),
                      TextButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      if (session.branchId == null)
                        const ListTile(
                          title: Text('All branches you can access'),
                          subtitle: Text('A branch is chosen when an asset is created. Another branch stays closed.'),
                        ),
                      const ListTile(title: Text('Assets')),
                      if (_assets.isEmpty) const ListTile(title: Text('No rental assets.')),
                      for (final asset in _assets)
                        ListTile(
                          title: Text(asset.name),
                          subtitle: Text(
                            '${asset.code} · ${asset.category} · ${asset.availability} · ${asset.chargePerUse.toStringAsFixed(2)} per use · buffer ${asset.cleaningBufferMinutes}m',
                          ),
                          trailing: Wrap(
                            spacing: 4,
                            children: [
                              if (canManage)
                                TextButton(onPressed: () => _editAsset(asset), child: const Text('Edit')),
                              if (canManage && asset.isActive && asset.availability != 'Maintenance')
                                TextButton(onPressed: () => _reserve(asset), child: const Text('Reserve')),
                            ],
                          ),
                        ),
                      const ListTile(title: Text('Reservations')),
                      if (_reservations.isEmpty) const ListTile(title: Text('No reservations.')),
                      for (final reservation in _reservations)
                        ListTile(
                          title: Text('${reservation.assetName} · ${reservation.customerName}'),
                          subtitle: Text(
                            '${reservation.status} · ${reservation.chargePerUse.toStringAsFixed(2)}'
                            '${reservation.isOverdue ? ' · Overdue' : ''}'
                            '${reservation.conditionDiscrepancy ? ' · Condition differs' : ''}'
                            '${reservation.isBillable ? ' · Ready to bill' : ''}'
                            '${reservation.notes == null || reservation.notes!.isEmpty ? '' : ' · ${reservation.notes}'}',
                          ),
                          trailing: Wrap(
                            spacing: 8,
                            children: [
                              if (reservation.status == 'Reserved' && canIssue)
                                TextButton(onPressed: () => _move(reservation, 'issue'), child: const Text('Issue')),
                              if (reservation.status == 'Issued' && canIssue)
                                TextButton(onPressed: () => _move(reservation, 'return'), child: const Text('Return')),
                              if (reservation.status == 'Reserved' && canManage)
                                TextButton(onPressed: () => _move(reservation, 'cancel'), child: const Text('Cancel')),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}

class _AssetDraft {
  const _AssetDraft({
    required this.code,
    required this.name,
    required this.category,
    required this.charge,
    required this.buffer,
    required this.active,
  });

  final String code;
  final String name;
  final String category;
  final String charge;
  final String buffer;
  final bool active;
}

class _AssetDialog extends StatefulWidget {
  const _AssetDialog({this.asset});

  final RentalAsset? asset;

  @override
  State<_AssetDialog> createState() => _AssetDialogState();
}

class _AssetDialogState extends State<_AssetDialog> {
  late final TextEditingController _code = TextEditingController(text: widget.asset?.code ?? '');
  late final TextEditingController _name = TextEditingController(text: widget.asset?.name ?? '');
  late final TextEditingController _category = TextEditingController(text: widget.asset?.category ?? 'Costume');
  late final TextEditingController _charge = TextEditingController(
    text: widget.asset == null ? '' : widget.asset!.chargePerUse.toStringAsFixed(2),
  );
  late final TextEditingController _buffer = TextEditingController(text: '${widget.asset?.cleaningBufferMinutes ?? 60}');
  late bool _active = widget.asset?.isActive ?? true;

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    _category.dispose();
    _charge.dispose();
    _buffer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.asset == null ? 'Rental asset' : 'Edit rental asset'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _code, decoration: const InputDecoration(labelText: 'Code')),
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: _category, decoration: const InputDecoration(labelText: 'Category')),
            TextField(
              controller: _charge,
              decoration: const InputDecoration(labelText: 'Charge per use'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            TextField(
              controller: _buffer,
              decoration: const InputDecoration(labelText: 'Cleaning buffer minutes'),
              keyboardType: TextInputType.number,
            ),
            if (widget.asset != null)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active'),
                value: _active,
                onChanged: (value) => setState(() => _active = value),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(
          onPressed: () => Navigator.pop(
            context,
            _AssetDraft(
              code: _code.text.trim(),
              name: _name.text.trim(),
              category: _category.text.trim(),
              charge: _charge.text.trim(),
              buffer: _buffer.text.trim(),
              active: _active,
            ),
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _ReservationDraft {
  const _ReservationDraft({required this.customerId, required this.issueText, required this.returnText});

  final int customerId;
  final String issueText;
  final String returnText;
}

class _ReserveDialog extends StatefulWidget {
  const _ReserveDialog({
    required this.assetName,
    required this.customers,
    required this.issueText,
    required this.returnText,
    required this.cleaningBufferMinutes,
  });

  final String assetName;
  final List<RentalCustomerChoice> customers;
  final String issueText;
  final String returnText;
  final int cleaningBufferMinutes;

  @override
  State<_ReserveDialog> createState() => _ReserveDialogState();
}

class _ReserveDialogState extends State<_ReserveDialog> {
  late int _customerId = widget.customers.first.id;
  late final TextEditingController _issue = TextEditingController(text: widget.issueText);
  late final TextEditingController _due = TextEditingController(text: widget.returnText);

  @override
  void dispose() {
    _issue.dispose();
    _due.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Reserve ${widget.assetName}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<int>(
            value: _customerId,
            decoration: const InputDecoration(labelText: 'Customer'),
            items: [
              for (final customer in widget.customers)
                DropdownMenuItem(value: customer.id, child: Text(customer.name)),
            ],
            onChanged: (value) => setState(() => _customerId = value ?? _customerId),
          ),
          TextField(controller: _issue, decoration: const InputDecoration(labelText: 'Issue (yyyy-MM-dd HH:mm)')),
          TextField(controller: _due, decoration: const InputDecoration(labelText: 'Return (yyyy-MM-dd HH:mm)')),
          Text('Cleaning buffer ${widget.cleaningBufferMinutes} minutes is included in availability.'),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(
          onPressed: () => Navigator.pop(
            context,
            _ReservationDraft(customerId: _customerId, issueText: _issue.text, returnText: _due.text),
          ),
          child: const Text('Reserve'),
        ),
      ],
    );
  }
}

class _MovementDraft {
  const _MovementDraft({required this.condition, required this.notes});

  final String condition;
  final String notes;
}

class _MovementDialog extends StatefulWidget {
  const _MovementDialog({required this.returning});

  final bool returning;

  @override
  State<_MovementDialog> createState() => _MovementDialogState();
}

class _MovementDialogState extends State<_MovementDialog> {
  late final TextEditingController _condition = TextEditingController(text: widget.returning ? '' : 'Good');
  final TextEditingController _notes = TextEditingController();

  @override
  void dispose() {
    _condition.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.returning ? 'Return condition' : 'Issue condition'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: _condition, decoration: const InputDecoration(labelText: 'Condition')),
          TextField(
            controller: _notes,
            decoration: InputDecoration(labelText: widget.returning ? 'Discrepancy notes' : 'Notes'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(
          onPressed: () => Navigator.pop(
            context,
            _MovementDraft(condition: _condition.text.trim(), notes: _notes.text.trim()),
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

String _formatLocal(DateTime value) {
  String two(int number) => number.toString().padLeft(2, '0');
  return '${value.year}-${two(value.month)}-${two(value.day)} ${two(value.hour)}:${two(value.minute)}';
}

DateTime? _parseLocal(String text) {
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})[ T](\d{2}):(\d{2})$').firstMatch(text.trim());
  if (match == null) return null;
  return DateTime(
    int.parse(match.group(1)!),
    int.parse(match.group(2)!),
    int.parse(match.group(3)!),
    int.parse(match.group(4)!),
    int.parse(match.group(5)!),
  );
}
