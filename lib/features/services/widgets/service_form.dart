import 'package:flutter/material.dart';

import '../../../shared/utils/app_constants.dart';
import '../../../shared/utils/validators.dart';
import '../../../shared/widgets/app_dropdown.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../appointments/models/salon_lookups.dart';
import '../models/service_management_models.dart';

int? tryParseDuration(String raw) {
  final parsed = int.tryParse(raw.trim());
  if (parsed == null || parsed <= 0 || parsed > 480) return null;
  return parsed;
}

double? tryParsePrice(String raw) {
  final cleaned = raw.trim().replaceAll(',', '');
  if (cleaned.isEmpty) return null;
  final parsed = double.tryParse(cleaned);
  if (parsed == null || parsed <= 0 || parsed.isNaN || parsed.isInfinite) {
    return null;
  }
  return parsed;
}

String? validateServiceName(String? value) {
  if (Validators.required(value) != null) {
    return 'Service name is required';
  }
  return Validators.maxLength(value?.trim(), AppConstants.maxNameLength);
}

String? validateDuration(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Duration is required';
  }
  if (tryParseDuration(value) == null) {
    return 'Enter a valid duration in minutes';
  }
  return null;
}

String? validatePrice(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Price is required';
  }
  if (tryParsePrice(value) == null) {
    return 'Enter a valid price';
  }
  return null;
}

String? validateServiceDescription(String? value) {
  return Validators.maxLength(value, AppConstants.maxDescriptionLength);
}

String priceInputText(double price) {
  if (price == price.roundToDouble()) return price.toStringAsFixed(0);
  return price.toStringAsFixed(2);
}

class ServiceForm extends StatelessWidget {
  final TextEditingController? serviceCodeController;
  final TextEditingController nameController;
  final TextEditingController durationController;
  final TextEditingController priceController;
  final TextEditingController descriptionController;
  final String? category;
  final ValueChanged<String?> onCategoryChanged;
  final int? branchId;
  final List<BranchLookup> branches;
  final ValueChanged<int?> onBranchChanged;
  final bool isActive;
  final ValueChanged<bool> onActiveChanged;

  const ServiceForm({
    super.key,
    this.serviceCodeController,
    required this.nameController,
    required this.durationController,
    required this.priceController,
    required this.descriptionController,
    required this.category,
    required this.onCategoryChanged,
    required this.branchId,
    required this.branches,
    required this.onBranchChanged,
    required this.isActive,
    required this.onActiveChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= 640;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (serviceCodeController != null) ...[
              AppTextField(
                controller: serviceCodeController,
                labelText: 'Service Code',
                prefixIcon: Icons.tag,
                readOnly: true,
              ),
              const SizedBox(height: 16),
            ],
            AppTextField(
              controller: nameController,
              labelText: 'Service Name',
              hintText: 'Haircut',
              prefixIcon: Icons.content_cut,
              textInputAction: TextInputAction.next,
              validator: validateServiceName,
            ),
            const SizedBox(height: 16),
            _pair(
              twoColumns: twoColumns,
              first: AppDropdown<String>(
                labelText: 'Category',
                hintText: 'Select category',
                value: category,
                items: [
                  for (final name in serviceCategoryNames)
                    DropdownMenuItem<String>(
                      value: name,
                      child: Text(name, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: onCategoryChanged,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Category is required';
                  }
                  return null;
                },
              ),
              second: AppDropdown<int>(
                labelText: 'Branch',
                hintText: 'Select branch',
                value: branchId,
                items: [
                  for (final branch in branches)
                    DropdownMenuItem<int>(
                      value: branch.branchId,
                      child: Text(
                        branch.branchName,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: onBranchChanged,
                validator: (value) {
                  if (value == null) return 'Branch is required';
                  return null;
                },
              ),
            ),
            const SizedBox(height: 16),
            _pair(
              twoColumns: twoColumns,
              first: AppTextField(
                controller: durationController,
                labelText: 'Duration (minutes)',
                hintText: '45',
                prefixIcon: Icons.timer_outlined,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                validator: validateDuration,
              ),
              second: AppTextField(
                controller: priceController,
                labelText: 'Price (Rs.)',
                hintText: '2500',
                prefixIcon: Icons.payments_outlined,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.next,
                validator: validatePrice,
              ),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: descriptionController,
              labelText: 'Description',
              hintText: 'What the client can expect',
              prefixIcon: Icons.notes_outlined,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              maxLines: 4,
              validator: validateServiceDescription,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Active'),
              subtitle: const Text('Shown when booking new appointments'),
              value: isActive,
              onChanged: onActiveChanged,
            ),
          ],
        );
      },
    );
  }

  Widget _pair({
    required bool twoColumns,
    required Widget first,
    required Widget second,
  }) {
    if (!twoColumns) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [first, const SizedBox(height: 16), second],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: first),
        const SizedBox(width: 16),
        Expanded(child: second),
      ],
    );
  }
}
