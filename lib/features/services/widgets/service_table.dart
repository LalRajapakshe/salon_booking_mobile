import 'package:flutter/material.dart';

import '../../../shared/utils/currency_formatter.dart';
import '../data/mock_service_data.dart';
import '../models/service_management_models.dart';
import 'service_category_chip.dart';

class ServiceTable extends StatelessWidget {
  final List<SalonService> services;
  final bool compact;
  final void Function(SalonService service, ServiceMenuAction action) onAction;

  const ServiceTable({
    super.key,
    required this.services,
    required this.compact,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: services.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 36),
              child: Text(
                'No services match your search or filters.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            )
          : compact
          ? _ServiceCardList(services: services, onAction: onAction)
          : _DesktopServiceTable(services: services, onAction: onAction),
    );
  }
}

class _DesktopServiceTable extends StatelessWidget {
  final List<SalonService> services;
  final void Function(SalonService service, ServiceMenuAction action) onAction;

  const _DesktopServiceTable({required this.services, required this.onAction});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth,
          child: DataTable(
            showCheckboxColumn: false,
            columnSpacing: 20,
            horizontalMargin: 16,
            headingRowHeight: 52,
            dataRowMinHeight: 68,
            dataRowMaxHeight: 80,
            headingRowColor: const WidgetStatePropertyAll(Color(0xffF7F8FC)),
            columns: const [
              DataColumn(
                label: Flexible(
                  child: Text(
                    'Service',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                columnWidth: FlexColumnWidth(2.4),
              ),
              DataColumn(
                label: Flexible(
                  child: Text(
                    'Category',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                columnWidth: FlexColumnWidth(1.4),
              ),
              DataColumn(
                label: Flexible(
                  child: Text(
                    'Duration',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                columnWidth: FlexColumnWidth(1.2),
              ),
              DataColumn(
                label: Flexible(
                  child: Text(
                    'Price',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                columnWidth: FlexColumnWidth(1.4),
              ),
              DataColumn(
                label: Flexible(
                  child: Text(
                    'Status',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                columnWidth: FlexColumnWidth(1.2),
              ),
              DataColumn(
                label: Flexible(
                  child: Text(
                    'Actions',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                columnWidth: FixedColumnWidth(148),
              ),
            ],
            rows: [
              for (final service in services)
                DataRow(
                  cells: [
                    DataCell(_ServiceIdentity(service: service)),
                    DataCell(
                      ServiceCategoryChip(category: service.categoryName),
                    ),
                    DataCell(Text(service.durationCompact)),
                    DataCell(
                      Text(CurrencyFormatter.formatWithSymbol(service.price)),
                    ),
                    DataCell(ServiceStatusBadge(isActive: service.isActive)),
                    DataCell(
                      _ServiceActions(service: service, onAction: onAction),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ServiceCardList extends StatelessWidget {
  final List<SalonService> services;
  final void Function(SalonService service, ServiceMenuAction action) onAction;

  const _ServiceCardList({required this.services, required this.onAction});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < services.length; index++) ...[
          if (index > 0) const Divider(height: 1),
          _ServiceCard(service: services[index], onAction: onAction),
        ],
      ],
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final SalonService service;
  final void Function(SalonService service, ServiceMenuAction action) onAction;

  const _ServiceCard({required this.service, required this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 4, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _ServiceIdentity(service: service)),
              _ServiceActions(service: service, onAction: onAction),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ServiceCategoryChip(category: service.categoryName),
              ServiceStatusBadge(isActive: service.isActive),
              Text(
                service.durationCompact,
                style: const TextStyle(color: Colors.black54, fontSize: 13),
              ),
              Text(
                CurrencyFormatter.formatWithSymbol(service.price),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ServiceIdentity extends StatelessWidget {
  final SalonService service;

  const _ServiceIdentity({required this.service});

  @override
  Widget build(BuildContext context) {
    final branch = branchNameForService(service.branchId);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          service.serviceName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: service.isActive ? const Color(0xFF212121) : Colors.black54,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${service.serviceCode} · $branch',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }
}

class _ServiceActions extends StatelessWidget {
  final SalonService service;
  final void Function(SalonService service, ServiceMenuAction action) onAction;

  const _ServiceActions({required this.service, required this.onAction});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<ServiceMenuAction>(
      key: ValueKey('service-actions-${service.serviceId}'),
      tooltip: 'Actions',
      padding: EdgeInsets.zero,
      icon: const Icon(Icons.more_vert),
      onSelected: (action) => onAction(service, action),
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: ServiceMenuAction.view,
          child: _MenuRow(icon: Icons.visibility_outlined, label: 'View'),
        ),
        PopupMenuItem(
          value: ServiceMenuAction.edit,
          child: _MenuRow(icon: Icons.edit_outlined, label: 'Edit'),
        ),
        PopupMenuItem(
          value: ServiceMenuAction.delete,
          child: _MenuRow(icon: Icons.delete_outline, label: 'Delete'),
        ),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MenuRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [Icon(icon, size: 20), const SizedBox(width: 12), Text(label)],
    );
  }
}
