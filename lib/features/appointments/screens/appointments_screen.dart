import 'package:flutter/material.dart';

import '../../../shared/utils/date_formatter.dart';
import '../models/appointment.dart';
import '../models/appointment_status.dart';
import '../models/appointment_time.dart';
import '../services/appointment_catalog.dart';
import '../widgets/appointment_status_badge.dart';
import 'create_appointment_screen.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _tableScrollController = ScrollController();

  String _statusFilter = 'All';
  String _dateFilter = 'All';

  static const double _minTableWidth = 980;
  static const double _headingRowHeight = 56;
  static const double _dataRowHeight = 64;

  @override
  void dispose() {
    _searchController.dispose();
    _tableScrollController.dispose();
    super.dispose();
  }

  List<Appointment> get _filteredAppointments {
    final query = _searchController.text.trim().toLowerCase();
    final status = AppointmentStatus.fromLabel(_statusFilter);

    final matches = AppointmentCatalog.appointments.where((appointment) {
      if (status != null && appointment.status != status) return false;
      if (_dateFilter != 'All' && _dateKey(appointment.appointmentDate) != _dateFilter) {
        return false;
      }
      if (query.isEmpty) return true;

      final customer = AppointmentCatalog.customer(appointment.customerId);
      final employee = AppointmentCatalog.employee(appointment.employeeId);
      final services = AppointmentCatalog.serviceSummary(appointment);
      final haystack = '${customer.fullName} ${employee.fullName} $services'.toLowerCase();
      return haystack.contains(query);
    }).toList();

    matches.sort((a, b) {
      final byDate = a.appointmentDate.compareTo(b.appointmentDate);
      if (byDate != 0) return byDate;
      return appointmentMinutes(a.startTime).compareTo(appointmentMinutes(b.startTime));
    });
    return matches;
  }

  List<String> get _dateOptions {
    final keys = AppointmentCatalog.appointments
        .map((item) => _dateKey(item.appointmentDate))
        .toSet()
        .toList()
      ..sort();
    return ['All', ...keys];
  }

  String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _dateLabel(String key) {
    if (key == 'All') return 'All';
    return DateFormatter.format(DateTime.parse(key));
  }

  @override
  Widget build(BuildContext context) {
    final appointments = _filteredAppointments;

    return Scaffold(
      backgroundColor: const Color(0xffF4F6FA),
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Appointments',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final padding = constraints.maxWidth < 520 ? 16.0 : 24.0;

          return SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(constraints.maxWidth),
                const SizedBox(height: 24),
                _buildFilters(),
                const SizedBox(height: 20),
                _buildTableCard(appointments),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(double maxWidth) {
    final title = const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Appointments',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 6),
        Text(
          'Schedule and review salon appointments',
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
      ],
    );

    final addButton = ElevatedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const CreateAppointmentScreen(),
          ),
        );
      },
      icon: const Icon(Icons.add),
      label: const Text('Add Appointment'),
    );

    if (maxWidth < 560) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          title,
          const SizedBox(height: 16),
          addButton,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: title),
        const SizedBox(width: 16),
        addButton,
      ],
    );
  }

  Widget _buildFilters() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return _buildFilterControls(constraints.maxWidth);
          },
        ),
      ),
    );
  }

  Widget _buildFilterControls(double maxWidth) {
    final search = TextField(
      controller: _searchController,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: 'Search customer, employee or service',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                tooltip: 'Clear search',
                onPressed: () {
                  _searchController.clear();
                  setState(() {});
                },
                icon: const Icon(Icons.clear),
              )
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    final date = _filterDropdown(
      label: 'Date',
      value: _dateFilter,
      items: _dateOptions,
      itemLabel: _dateLabel,
      onChanged: (value) => setState(() => _dateFilter = value ?? 'All'),
    );

    final status = _filterDropdown(
      label: 'Status',
      value: _statusFilter,
      items: ['All', ...AppointmentStatus.values.map((item) => item.label)],
      itemLabel: (value) => value,
      onChanged: (value) => setState(() => _statusFilter = value ?? 'All'),
    );

    if (maxWidth < 720) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          search,
          const SizedBox(height: 14),
          date,
          const SizedBox(height: 14),
          status,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: search),
        const SizedBox(width: 14),
        SizedBox(width: 190, child: date),
        const SizedBox(width: 14),
        SizedBox(width: 180, child: status),
      ],
    );
  }

  Widget _filterDropdown({
    required String label,
    required String value,
    required List<String> items,
    required String Function(String value) itemLabel,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: [
        for (final item in items)
          DropdownMenuItem<String>(
            value: item,
            child: Text(itemLabel(item), overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: onChanged,
    );
  }

  Widget _buildTableCard(List<Appointment> appointments) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (appointments.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 36),
              child: Text(
                'No appointments found',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          final table = _appointmentTable(appointments);
          final available = constraints.maxWidth;

          if (available >= _minTableWidth) {
            return SizedBox(width: available, child: table);
          }

          final tableHeight =
              _headingRowHeight + (appointments.length * _dataRowHeight) + 16;

          return SizedBox(
            height: tableHeight,
            width: available,
            child: Scrollbar(
              controller: _tableScrollController,
              thumbVisibility: true,
              scrollbarOrientation: ScrollbarOrientation.bottom,
              child: SingleChildScrollView(
                controller: _tableScrollController,
                scrollDirection: Axis.horizontal,
                primary: false,
                child: SizedBox(width: _minTableWidth, child: table),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _appointmentTable(List<Appointment> appointments) {
    return DataTable(
      showCheckboxColumn: false,
      columnSpacing: 20,
      horizontalMargin: 16,
      headingRowHeight: _headingRowHeight,
      dataRowMinHeight: _dataRowHeight,
      dataRowMaxHeight: _dataRowHeight,
      headingRowColor: const WidgetStatePropertyAll(Color(0xffF7F8FC)),
      columns: [
        _column('Customer', flex: 1.6),
        _column('Employee', flex: 1.5),
        _column('Services', flex: 1.8),
        _column('Appointment Date', flex: 2.3),
        _column('Start Time', flex: 1.35),
        _column('End Time', flex: 1.25),
        _column('Status', flex: 1.25),
        const DataColumn(
          label: Flexible(
            child: Text(
              'Actions',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          columnWidth: FixedColumnWidth(120),
        ),
      ],
      rows: [
        for (final appointment in appointments)
          DataRow(
            cells: [
              DataCell(_cellText(
                AppointmentCatalog.customer(appointment.customerId).fullName,
                strong: true,
              )),
              DataCell(_cellText(
                AppointmentCatalog.employee(appointment.employeeId).fullName,
              )),
              DataCell(_cellText(AppointmentCatalog.serviceSummary(appointment))),
              DataCell(_cellText(DateFormatter.format(appointment.appointmentDate))),
              DataCell(_cellText(formatAppointmentTime(appointment.startTime))),
              DataCell(_cellText(formatAppointmentTime(appointment.endTime))),
              DataCell(AppointmentStatusBadge(status: appointment.status)),
              DataCell(
                PopupMenuButton<String>(
                  tooltip: 'Actions',
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.more_vert),
                  onSelected: (action) {
                    switch (action) {
                      case 'view':
                      case 'edit':
                      case 'delete':
                        break;
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem<String>(
                      value: 'view',
                      child: Text('View'),
                    ),
                    PopupMenuItem<String>(
                      value: 'edit',
                      child: Text('Edit'),
                    ),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Text('Delete'),
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  DataColumn _column(String label, {required double flex}) {
    return DataColumn(
      label: Flexible(
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      columnWidth: FlexColumnWidth(flex),
    );
  }

  Widget _cellText(String value, {bool strong = false}) {
    return Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: strong ? const TextStyle(fontWeight: FontWeight.w600) : null,
    );
  }
}
