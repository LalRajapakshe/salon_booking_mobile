import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/utils/currency_formatter.dart';
import '../../../shared/widgets/app_dialog.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../data/service_directory.dart';
import '../models/service_management_models.dart';
import '../widgets/service_filters.dart';
import '../widgets/service_summary_card.dart';
import '../widgets/service_table.dart';
import 'create_service_screen.dart';
import 'service_details_screen.dart';

class ServicesScreen extends StatefulWidget {
  final ServiceDirectory? directory;

  const ServicesScreen({super.key, this.directory});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  late final ServiceDirectory _directory;
  final TextEditingController _searchController = TextEditingController();

  String _categoryFilter = 'All';
  String _statusFilter = 'All';
  String _sortBy = 'Service Name';
  bool _sortAscending = true;
  int _currentPage = 1;

  static const int _rowsPerPage = 8;
  static const double _tableBreakpoint = 900;
  static const List<String> _sortOptions = [
    'Service Name',
    'Category',
    'Price',
    'Duration',
    'Created Date',
  ];

  @override
  void initState() {
    super.initState();
    _directory = widget.directory ?? ServiceDirectory.session;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _categoryOptions {
    return ['All', ...serviceCategoryNames];
  }

  List<SalonService> get _filteredServices {
    final query = _searchController.text.trim().toLowerCase();

    final result = _directory.services.where((service) {
      final matchesSearch =
          query.isEmpty ||
          service.serviceName.toLowerCase().contains(query) ||
          service.categoryName.toLowerCase().contains(query);

      final matchesCategory =
          _categoryFilter == 'All' || service.categoryName == _categoryFilter;
      final matchesStatus =
          _statusFilter == 'All' || service.statusLabel == _statusFilter;

      return matchesSearch && matchesCategory && matchesStatus;
    }).toList();

    result.sort((a, b) {
      final comparison = switch (_sortBy) {
        'Category' => a.categoryName.toLowerCase().compareTo(
          b.categoryName.toLowerCase(),
        ),
        'Price' => a.price.compareTo(b.price),
        'Duration' => a.durationMinutes.compareTo(b.durationMinutes),
        'Created Date' => a.createdDate.compareTo(b.createdDate),
        _ => a.serviceName.toLowerCase().compareTo(b.serviceName.toLowerCase()),
      };
      final directed = _sortAscending ? comparison : -comparison;
      if (directed != 0) return directed;
      return a.serviceId.compareTo(b.serviceId);
    });

    return result;
  }

  int get _totalPages {
    final count = _filteredServices.length;
    return count == 0 ? 1 : (count / _rowsPerPage).ceil();
  }

  List<SalonService> get _pagedServices {
    final services = _filteredServices;
    final page = _currentPage > _totalPages ? _totalPages : _currentPage;
    final start = (page - 1) * _rowsPerPage;
    if (start >= services.length) return [];
    final end = start + _rowsPerPage > services.length
        ? services.length
        : start + _rowsPerPage;
    return services.sublist(start, end);
  }

  void _resetPage() {
    _currentPage = 1;
  }

  void _clampPage() {
    if (_currentPage > _totalPages) _currentPage = _totalPages;
    if (_currentPage < 1) _currentPage = 1;
  }

  Future<void> _openCreate() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateServiceScreen(directory: _directory),
      ),
    );
    if (mounted) setState(_resetPage);
  }

  Future<void> _openDetails(SalonService service) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ServiceDetailsScreen(
          directory: _directory,
          serviceId: service.serviceId,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _openEdit(SalonService service) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            CreateServiceScreen(directory: _directory, service: service),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _confirmDelete(SalonService service) async {
    final confirmed = await AppDialog.show(
      context: context,
      title: 'Delete Service?',
      message:
          'Are you sure you want to delete "${service.serviceName}"?\n\nThis action cannot be undone.',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      icon: Icons.delete_outline,
      iconColor: AppColors.error,
    );
    if (!mounted || confirmed != true) return;

    _directory.delete(service.serviceId);
    setState(_clampPage);
    AppSnackBar.success(context, '${service.serviceName} was deleted.');
  }

  void _onAction(SalonService service, ServiceMenuAction action) {
    switch (action) {
      case ServiceMenuAction.view:
        _openDetails(service);
      case ServiceMenuAction.edit:
        _openEdit(service);
      case ServiceMenuAction.delete:
        _confirmDelete(service);
    }
  }

  @override
  Widget build(BuildContext context) {
    final services = _filteredServices;
    final paged = _pagedServices;
    final page = _currentPage > _totalPages ? _totalPages : _currentPage;
    final startNumber = services.isEmpty ? 0 : ((page - 1) * _rowsPerPage) + 1;
    final endNumber = services.isEmpty ? 0 : startNumber + paged.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xffF4F6FA),
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Service Management',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final padding = constraints.maxWidth < 520 ? 16.0 : 24.0;
          final contentWidth = constraints.maxWidth - (padding * 2);
          final compact = contentWidth < _tableBreakpoint;

          return SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(contentWidth),
                const SizedBox(height: 20),
                _buildSummary(contentWidth),
                const SizedBox(height: 16),
                ServiceFilters(
                  searchController: _searchController,
                  onSearchChanged: () => setState(_resetPage),
                  category: _categoryFilter,
                  categories: _categoryOptions,
                  onCategoryChanged: (value) => setState(() {
                    _categoryFilter = value;
                    _resetPage();
                  }),
                  status: _statusFilter,
                  onStatusChanged: (value) => setState(() {
                    _statusFilter = value;
                    _resetPage();
                  }),
                  sortBy: _sortBy,
                  sortOptions: _sortOptions,
                  onSortChanged: (value) => setState(() {
                    _sortBy = value;
                    _resetPage();
                  }),
                  sortAscending: _sortAscending,
                  onToggleSort: () => setState(() {
                    _sortAscending = !_sortAscending;
                    _resetPage();
                  }),
                ),
                const SizedBox(height: 16),
                ServiceTable(
                  services: paged,
                  compact: compact,
                  onAction: _onAction,
                ),
                const SizedBox(height: 16),
                _buildPagination(
                  total: services.length,
                  startNumber: startNumber,
                  endNumber: endNumber,
                  page: page,
                ),
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
          'Service Management',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 6),
        Text(
          'Manage your salon services, pricing, duration and availability.',
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
      ],
    );

    final addButton = ElevatedButton.icon(
      onPressed: _openCreate,
      icon: const Icon(Icons.add),
      label: const Text('Add Service'),
    );

    if (maxWidth < 560) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [title, const SizedBox(height: 16), addButton],
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

  Widget _buildSummary(double maxWidth) {
    final cards = [
      ServiceSummaryCard(
        label: 'Total Services',
        value: '${_directory.totalCount}',
        icon: Icons.content_cut,
        color: AppColors.service,
      ),
      ServiceSummaryCard(
        label: 'Active Services',
        value: '${_directory.activeCount}',
        icon: Icons.check_circle_outline,
        color: AppColors.success,
      ),
      ServiceSummaryCard(
        label: 'Categories',
        value: '${_directory.categoryCount}',
        icon: Icons.category_outlined,
        color: AppColors.primary,
      ),
      ServiceSummaryCard(
        label: 'Average Price',
        value: CurrencyFormatter.formatWithSymbol(_directory.averagePrice),
        icon: Icons.payments_outlined,
        color: AppColors.secondary,
      ),
    ];

    final columns = maxWidth >= 980 ? 4 : 2;
    const gap = 12.0;
    final cardWidth = (maxWidth - gap * (columns - 1)) / columns;

    return Wrap(
      spacing: gap,
      runSpacing: gap,
      children: [
        for (final card in cards) SizedBox(width: cardWidth, child: card),
      ],
    );
  }

  Widget _buildPagination({
    required int total,
    required int startNumber,
    required int endNumber,
    required int page,
  }) {
    final summary = Text(
      total == 0
          ? 'No services found'
          : 'Showing $startNumber–$endNumber of $total services',
      style: const TextStyle(color: Colors.grey),
    );

    final controls = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Previous',
          onPressed: page > 1
              ? () => setState(() => _currentPage = page - 1)
              : null,
          icon: const Icon(Icons.chevron_left),
        ),
        Text(
          'Page $page of $_totalPages',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        IconButton(
          tooltip: 'Next',
          onPressed: page < _totalPages
              ? () => setState(() => _currentPage = page + 1)
              : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 560) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [summary, controls],
          );
        }

        return Row(
          children: [
            Expanded(child: summary),
            controls,
          ],
        );
      },
    );
  }
}
