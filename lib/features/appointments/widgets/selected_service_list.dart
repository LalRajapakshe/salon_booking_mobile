import 'package:flutter/material.dart';

import '../../../shared/utils/currency_formatter.dart';
import '../models/salon_lookups.dart';

class SelectedServiceList extends StatelessWidget {
  final List<ServiceLookup> services;
  final ValueChanged<int> onRemove;

  const SelectedServiceList({
    super.key,
    required this.services,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (services.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        for (final service in services) ...[
          const SizedBox(height: 8),
          Material(
            color: const Color(0xffF7F8FC),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.only(left: 14, right: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            service.serviceName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${service.durationMinutes} min · ${CurrencyFormatter.formatWithSymbol(service.price)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Remove ${service.serviceName}',
                    onPressed: () => onRemove(service.serviceId),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
