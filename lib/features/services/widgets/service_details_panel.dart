import 'package:flutter/material.dart';

import '../../../shared/utils/currency_formatter.dart';
import '../../../shared/utils/date_formatter.dart';
import '../models/service_management_models.dart';
import 'service_category_chip.dart';

class ServiceDetailsPanel extends StatelessWidget {
  final SalonService service;
  final String branchName;

  const ServiceDetailsPanel({
    super.key,
    required this.service,
    required this.branchName,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 720;
        final titleSize = constraints.maxWidth < 420 ? 24.0 : 28.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              service.serviceName,
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${service.serviceCode} · $branchName',
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ServiceCategoryChip(category: service.categoryName),
                ServiceStatusBadge(isActive: service.isActive),
              ],
            ),
            const SizedBox(height: 20),
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _descriptionCard()),
                  const SizedBox(width: 16),
                  Expanded(child: _operationalCard()),
                ],
              )
            else ...[
              _descriptionCard(),
              const SizedBox(height: 16),
              _operationalCard(),
            ],
          ],
        );
      },
    );
  }

  Widget _descriptionCard() {
    final description = service.description.trim().isEmpty
        ? 'No description has been added for this service.'
        : service.description;

    return _sectionCard(
      title: 'Description',
      child: Text(
        description,
        style: const TextStyle(fontSize: 15, height: 1.45),
      ),
    );
  }

  Widget _operationalCard() {
    // Staff who can perform the service are not stored here. Duration and
    // price are the fields scheduling will use once eligibility exists.
    return _sectionCard(
      title: 'Operational Information',
      child: Column(
        children: [
          _fact('Category', service.categoryName),
          _fact('Duration', service.durationLabel),
          _fact('Price', CurrencyFormatter.formatWithSymbol(service.price)),
          _fact('Status', service.statusLabel),
          _fact('Branch', branchName),
          _fact('Created', DateFormatter.format(service.createdDate)),
        ],
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _fact(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}
