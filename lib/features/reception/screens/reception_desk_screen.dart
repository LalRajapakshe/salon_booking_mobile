import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_exception.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../appointments/screens/create_appointment_screen.dart';
import '../../appointments/widgets/appointment_status_badge.dart';
import '../data/reception_repository.dart';
import '../models/reception_visit.dart';
import '../widgets/check_in_dialog.dart';
import '../widgets/confirm_appointment_dialog.dart';
import '../widgets/walk_in_dialog.dart';

class ReceptionDeskScreen extends StatefulWidget {
  const ReceptionDeskScreen({
    super.key,
    this.repository,
  });

  final ReceptionRepository? repository;

  @override
  State<ReceptionDeskScreen> createState() => _ReceptionDeskScreenState();
}

class _ReceptionDeskScreenState extends State<ReceptionDeskScreen> {
  late final ReceptionRepository _repository = widget.repository ?? ReceptionRepository();
  final TextEditingController _searchController = TextEditingController();

  ReceptionDay? _day;
  String? _error;
  bool _loading = true;
  _DeskFilter _filter = _DeskFilter.today;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final day = await _repository.load();
      if (!mounted) return;
      setState(() {
        _day = day;
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

  List<ReceptionVisit> get _visible {
    final visits = _day?.visits ?? const <ReceptionVisit>[];
    final query = _query.trim().toLowerCase();
    return [
      for (final visit in visits)
        if (_filter.matches(visit) && _matchesQuery(visit, query)) visit,
    ];
  }

  bool _matchesQuery(ReceptionVisit visit, String query) {
    if (query.isEmpty) return true;
    return visit.customerName.toLowerCase().contains(query) ||
        visit.mobile.contains(query) ||
        '${visit.appointmentId}'.contains(query) ||
        visit.services.toLowerCase().contains(query);
  }

  Future<void> _confirm(ReceptionVisit visit) async {
    final saved = await showConfirmAppointmentDialog(
      context: context,
      visit: visit,
      onConfirm: () => _repository.confirm(visit.appointmentId),
    );
    if (!mounted || saved != true) return;
    AppSnackBar.success(context, '${visit.customerName} is confirmed.');
    await _load();
  }

  Future<void> _checkIn(ReceptionVisit visit) async {
    final saved = await showCheckInDialog(
      context: context,
      visit: visit,
      onConfirm: () => _repository.checkIn(visit.appointmentId),
    );
    if (!mounted || saved != true) return;
    AppSnackBar.success(context, '${visit.customerName} is checked in.');
    await _load();
  }

  Future<void> _walkIn() async {
    final choice = await showWalkInDialog(
      context: context,
      customers: _repository.customers,
    );
    if (!mounted || choice == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute<bool>(
        builder: (_) => CreateAppointmentScreen(
          repository: _repository.appointments,
          customers: _repository.customers,
          liveLookups: _repository.isApiBacked,
          initialCustomerId: choice.customerId,
        ),
      ),
    );
    if (mounted) await _load();
  }

  void _view(ReceptionVisit visit) {
    final date = DateFormat('EEE, d MMM yyyy').format(visit.date);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(visit.customerName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Appointment #${visit.appointmentId}'),
            const SizedBox(height: 8),
            Text('$date · ${visit.timeLabel}'),
            Text(visit.services),
            Text(visit.employee),
            const SizedBox(height: 8),
            AppointmentStatusBadge(status: visit.status),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final day = _day;
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Reception Desk'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorState(message: _error!, onRetry: _load)
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 900;
                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _Header(wide: wide, onWalkIn: _walkIn, day: day),
                        if (day?.sampleDay == true) ...[
                          const SizedBox(height: 12),
                          const _SampleBanner(),
                        ],
                        const SizedBox(height: 16),
                        _Counts(visits: day?.visits ?? const [], wide: wide),
                        const SizedBox(height: 16),
                        _Filters(
                          filter: _filter,
                          onChanged: (value) => setState(() => _filter = value),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: 'Search by name, phone or appointment',
                            prefixIcon: Icon(Icons.search),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderSide: BorderSide.none),
                          ),
                          onChanged: (value) => setState(() => _query = value),
                        ),
                        const SizedBox(height: 12),
                        if (_visible.isEmpty)
                          const _EmptyState()
                        else if (wide)
                          _VisitTable(visits: _visible, onView: _view, onConfirm: _confirm, onCheckIn: _checkIn)
                        else
                          for (final visit in _visible)
                            _VisitCard(visit: visit, onView: _view, onConfirm: _confirm, onCheckIn: _checkIn),
                      ],
                    );
                  },
                ),
    );
  }
}

class _Header extends StatelessWidget {
  final bool wide;
  final ReceptionDay? day;
  final VoidCallback onWalkIn;

  const _Header({required this.wide, required this.day, required this.onWalkIn});

  @override
  Widget build(BuildContext context) {
    final date = day == null ? '' : DateFormat('EEE, d MMM yyyy').format(day!.date);
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Reception Desk', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        const Text(
          'Manage customer arrivals, check-in and walk-ins',
          style: TextStyle(color: Colors.grey),
        ),
        if (date.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(date, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ],
    );
    final button = FilledButton.icon(
      onPressed: onWalkIn,
      icon: const Icon(Icons.person_add_alt_1),
      label: const Text('Walk-in Registration'),
    );
    if (!wide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [title, const SizedBox(height: 12), button],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [Expanded(child: title), button],
    );
  }
}

class _SampleBanner extends StatelessWidget {
  const _SampleBanner();

  @override
  Widget build(BuildContext context) {
    return const Material(
      color: Color(0xFFFFF8E1),
      borderRadius: BorderRadius.all(Radius.circular(8)),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Text('Sample day from the demo catalog. Sign in for today’s appointments.'),
      ),
    );
  }
}

class _Counts extends StatelessWidget {
  final List<ReceptionVisit> visits;
  final bool wide;

  const _Counts({required this.visits, required this.wide});

  @override
  Widget build(BuildContext context) {
    final active = visits.where((visit) => visit.status.name != 'cancelled').length;
    final expected = visits.where((visit) {
      return visit.status.name == 'pending' ||
          visit.status.name == 'confirmed' ||
          visit.status.name == 'scheduled';
    }).length;
    final checkedIn = visits.where((visit) => visit.status.name == 'checkedIn').length;
    final inProgress = visits.where((visit) => visit.status.name == 'inProgress').length;
    final cards = [
      _CountCard(label: "Today's appointments", value: '$active', color: const Color(0xFFE3F2FD)),
      _CountCard(label: 'Expected arrivals', value: '$expected', color: const Color(0xFFFFF3E0)),
      _CountCard(label: 'Checked in', value: '$checkedIn', color: const Color(0xFFE8F5E9)),
      _CountCard(label: 'In progress', value: '$inProgress', color: const Color(0xFFF3E5F5)),
    ];
    if (!wide) {
      return Wrap(spacing: 12, runSpacing: 12, children: cards);
    }
    return Row(
      children: [
        for (final card in cards) Expanded(child: Padding(padding: const EdgeInsets.only(right: 12), child: card)),
      ],
    );
  }
}

class _CountCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _CountCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(label),
        ],
      ),
    );
  }
}

enum _DeskFilter {
  today('Today'),
  expected('Expected'),
  checkedIn('Checked in'),
  inProgress('In progress'),
  completed('Completed');

  final String label;
  const _DeskFilter(this.label);

  bool matches(ReceptionVisit visit) {
    return switch (this) {
      _DeskFilter.today => visit.status.name != 'cancelled',
      _DeskFilter.expected =>
        visit.status.name == 'pending' || visit.status.name == 'confirmed' || visit.status.name == 'scheduled',
      _DeskFilter.checkedIn => visit.status.name == 'checkedIn',
      _DeskFilter.inProgress => visit.status.name == 'inProgress',
      _DeskFilter.completed => visit.status.name == 'completed',
    };
  }
}

class _Filters extends StatelessWidget {
  final _DeskFilter filter;
  final ValueChanged<_DeskFilter> onChanged;

  const _Filters({required this.filter, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        for (final item in _DeskFilter.values)
          ChoiceChip(
            label: Text(item.label),
            selected: item == filter,
            onSelected: (_) => onChanged(item),
          ),
      ],
    );
  }
}

class _VisitTable extends StatelessWidget {
  final List<ReceptionVisit> visits;
  final ValueChanged<ReceptionVisit> onView;
  final ValueChanged<ReceptionVisit> onConfirm;
  final ValueChanged<ReceptionVisit> onCheckIn;

  const _VisitTable({
    required this.visits,
    required this.onView,
    required this.onConfirm,
    required this.onCheckIn,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Time')),
            DataColumn(label: Text('Customer')),
            DataColumn(label: Text('Services')),
            DataColumn(label: Text('Employee')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Action')),
          ],
          rows: [
            for (final visit in visits)
              DataRow(cells: [
                DataCell(Text(visit.timeLabel)),
                DataCell(Text(visit.customerName)),
                DataCell(Text(visit.services)),
                DataCell(Text(visit.employee)),
                DataCell(AppointmentStatusBadge(status: visit.status)),
                DataCell(_Actions(visit: visit, onView: onView, onConfirm: onConfirm, onCheckIn: onCheckIn)),
              ]),
          ],
        ),
      ),
    );
  }
}

class _VisitCard extends StatelessWidget {
  final ReceptionVisit visit;
  final ValueChanged<ReceptionVisit> onView;
  final ValueChanged<ReceptionVisit> onConfirm;
  final ValueChanged<ReceptionVisit> onCheckIn;

  const _VisitCard({
    required this.visit,
    required this.onView,
    required this.onConfirm,
    required this.onCheckIn,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(visit.timeLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
            Text(visit.customerName),
            Text(visit.services),
            Text(visit.employee),
            const SizedBox(height: 8),
            AppointmentStatusBadge(status: visit.status),
            _Actions(visit: visit, onView: onView, onConfirm: onConfirm, onCheckIn: onCheckIn),
          ],
        ),
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  final ReceptionVisit visit;
  final ValueChanged<ReceptionVisit> onView;
  final ValueChanged<ReceptionVisit> onConfirm;
  final ValueChanged<ReceptionVisit> onCheckIn;

  const _Actions({
    required this.visit,
    required this.onView,
    required this.onConfirm,
    required this.onCheckIn,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      children: [
        TextButton(onPressed: () => onView(visit), child: const Text('View')),
        if (visit.canConfirm)
          TextButton(onPressed: () => onConfirm(visit), child: const Text('Confirm')),
        if (visit.canCheckIn)
          TextButton(onPressed: () => onCheckIn(visit), child: const Text('Check in')),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 32),
      child: Center(child: Text('No appointments match this view.')),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
