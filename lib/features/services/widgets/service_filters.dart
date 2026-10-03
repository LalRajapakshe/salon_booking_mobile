import 'package:flutter/material.dart';

class ServiceFilters extends StatelessWidget {
  final TextEditingController searchController;
  final VoidCallback onSearchChanged;
  final String category;
  final List<String> categories;
  final ValueChanged<String> onCategoryChanged;
  final String status;
  final ValueChanged<String> onStatusChanged;
  final String sortBy;
  final List<String> sortOptions;
  final ValueChanged<String> onSortChanged;
  final bool sortAscending;
  final VoidCallback onToggleSort;

  const ServiceFilters({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.category,
    required this.categories,
    required this.onCategoryChanged,
    required this.status,
    required this.onStatusChanged,
    required this.sortBy,
    required this.sortOptions,
    required this.onSortChanged,
    required this.sortAscending,
    required this.onToggleSort,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return _controls(constraints.maxWidth);
          },
        ),
      ),
    );
  }

  Widget _controls(double maxWidth) {
    final search = _searchField();
    final categoryField = _dropdown(
      label: 'Category',
      value: category,
      items: categories,
      onChanged: onCategoryChanged,
    );
    final statusField = _dropdown(
      label: 'Status',
      value: status,
      items: const ['All', 'Active', 'Inactive'],
      onChanged: onStatusChanged,
    );
    final sortField = _dropdown(
      label: 'Sort',
      value: sortBy,
      items: sortOptions,
      onChanged: onSortChanged,
    );
    final direction = IconButton(
      tooltip: sortAscending ? 'Ascending' : 'Descending',
      onPressed: onToggleSort,
      icon: Icon(sortAscending ? Icons.arrow_upward : Icons.arrow_downward),
    );

    if (maxWidth < 560) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          search,
          const SizedBox(height: 14),
          categoryField,
          const SizedBox(height: 14),
          statusField,
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: sortField),
              direction,
            ],
          ),
        ],
      );
    }

    if (maxWidth < 980) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          search,
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: categoryField),
              const SizedBox(width: 14),
              Expanded(child: statusField),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: sortField),
              direction,
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(flex: 3, child: search),
        const SizedBox(width: 14),
        Expanded(child: categoryField),
        const SizedBox(width: 14),
        Expanded(child: statusField),
        const SizedBox(width: 14),
        Expanded(child: sortField),
        direction,
      ],
    );
  }

  Widget _searchField() {
    return TextField(
      key: const Key('service-search'),
      controller: searchController,
      onChanged: (_) => onSearchChanged(),
      decoration: InputDecoration(
        hintText: 'Search service or category',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: searchController.text.isNotEmpty
            ? IconButton(
                tooltip: 'Clear search',
                onPressed: () {
                  searchController.clear();
                  onSearchChanged();
                },
                icon: const Icon(Icons.clear),
              )
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _dropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
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
            child: Text(item, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (selected) {
        if (selected != null) onChanged(selected);
      },
    );
  }
}
