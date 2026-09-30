import 'package:flutter/material.dart';

import '../models/customer_model.dart';
import 'create_customer_screen.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _tableScrollController = ScrollController();

  String _statusFilter = 'All';
  String _sortBy = 'Name';
  bool _sortAscending = true;
  int _currentPage = 1;

  static const int _rowsPerPage = 8;

  /// Width at which every column still fits. Narrower viewports scroll the
  /// table instead of squeezing the page.
  static const double _minTableWidth = 960;

  // Temporary mock data using the existing Customer model.
  // Replace this list with repository/API data later.
  final List<Customer> _customers = [
    Customer(
      id: 1,
      customerCode: 'CUS-001',
      firstName: 'Amanda',
      lastName: 'Silva',
      mobileNumber: '0771234567',
      email: 'amanda@example.com',
      gender: 'Female',
      dateOfBirth: DateTime(1994, 5, 12),
      address: 'Colombo',
      notes: 'Regular customer',
      isActive: true,
      createdDate: DateTime(2026, 1, 10),
    ),
    Customer(
      id: 2,
      customerCode: 'CUS-002',
      firstName: 'Sarah',
      lastName: 'Perera',
      mobileNumber: '0712345678',
      email: 'sarah@example.com',
      gender: 'Female',
      dateOfBirth: DateTime(1996, 8, 21),
      address: 'Nugegoda',
      notes: null,
      isActive: true,
      createdDate: DateTime(2026, 1, 18),
    ),
    Customer(
      id: 3,
      customerCode: 'CUS-003',
      firstName: 'Emma',
      lastName: 'Fernando',
      mobileNumber: '0751234567',
      email: 'emma@example.com',
      gender: 'Female',
      dateOfBirth: DateTime(1992, 3, 8),
      address: 'Rajagiriya',
      notes: 'Prefers evening appointments',
      isActive: true,
      createdDate: DateTime(2026, 2, 2),
    ),
    Customer(
      id: 4,
      customerCode: 'CUS-004',
      firstName: 'Nethmi',
      lastName: 'Perera',
      mobileNumber: '0763456789',
      email: 'nethmi@example.com',
      gender: 'Female',
      dateOfBirth: DateTime(1998, 11, 17),
      address: 'Maharagama',
      notes: null,
      isActive: false,
      createdDate: DateTime(2026, 2, 14),
    ),
    Customer(
      id: 5,
      customerCode: 'CUS-005',
      firstName: 'Daniel',
      lastName: 'Silva',
      mobileNumber: '0724567890',
      email: 'daniel@example.com',
      gender: 'Male',
      dateOfBirth: DateTime(1990, 7, 4),
      address: 'Dehiwala',
      notes: null,
      isActive: true,
      createdDate: DateTime(2026, 2, 20),
    ),
    Customer(
      id: 6,
      customerCode: 'CUS-006',
      firstName: 'Jessica',
      lastName: 'Fernando',
      mobileNumber: '0785678901',
      email: 'jessica@example.com',
      gender: 'Female',
      dateOfBirth: DateTime(1995, 9, 26),
      address: 'Kotte',
      notes: 'Frequent customer',
      isActive: true,
      createdDate: DateTime(2026, 3, 1),
    ),
    Customer(
      id: 7,
      customerCode: 'CUS-007',
      firstName: 'Kevin',
      lastName: 'Perera',
      mobileNumber: '0706789012',
      email: 'kevin@example.com',
      gender: 'Male',
      dateOfBirth: DateTime(1988, 12, 2),
      address: 'Battaramulla',
      notes: null,
      isActive: false,
      createdDate: DateTime(2026, 3, 11),
    ),
    Customer(
      id: 8,
      customerCode: 'CUS-008',
      firstName: 'Michelle',
      lastName: 'Silva',
      mobileNumber: '0747890123',
      email: 'michelle@example.com',
      gender: 'Female',
      dateOfBirth: DateTime(1997, 1, 19),
      address: 'Mount Lavinia',
      notes: null,
      isActive: true,
      createdDate: DateTime(2026, 3, 25),
    ),
    Customer(
      id: 9,
      customerCode: 'CUS-009',
      firstName: 'Ryan',
      lastName: 'Fernando',
      mobileNumber: '0778901234',
      email: 'ryan@example.com',
      gender: 'Male',
      dateOfBirth: DateTime(1991, 6, 15),
      address: 'Colombo',
      notes: null,
      isActive: true,
      createdDate: DateTime(2026, 4, 4),
    ),
    Customer(
      id: 10,
      customerCode: 'CUS-010',
      firstName: 'Sophie',
      lastName: 'Perera',
      mobileNumber: '0719012345',
      email: 'sophie@example.com',
      gender: 'Female',
      dateOfBirth: DateTime(1999, 10, 30),
      address: 'Wattala',
      notes: null,
      isActive: true,
      createdDate: DateTime(2026, 4, 15),
    ),
    Customer(
      id: 11,
      customerCode: 'CUS-011',
      firstName: 'Jason',
      lastName: 'Silva',
      mobileNumber: '0761122334',
      email: 'jason@example.com',
      gender: 'Male',
      dateOfBirth: DateTime(1989, 4, 10),
      address: 'Wellawatte',
      notes: null,
      isActive: true,
      createdDate: DateTime(2026, 4, 22),
    ),
    Customer(
      id: 12,
      customerCode: 'CUS-012',
      firstName: 'Olivia',
      lastName: 'Fernando',
      mobileNumber: '0752233445',
      email: null,
      gender: 'Female',
      dateOfBirth: null,
      address: 'Colombo',
      notes: 'Email not provided',
      isActive: false,
      createdDate: DateTime(2026, 5, 3),
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _tableScrollController.dispose();
    super.dispose();
  }

  List<Customer> get _filteredCustomers {
    final query = _searchController.text.trim().toLowerCase();

    final result = _customers.where((customer) {
      final matchesSearch =
          query.isEmpty ||
          customer.fullName.toLowerCase().contains(query) ||
          customer.customerCode.toLowerCase().contains(query) ||
          customer.mobileNumber.toLowerCase().contains(query) ||
          (customer.email?.toLowerCase().contains(query) ?? false);

      final status = customer.isActive ? 'Active' : 'Inactive';
      final matchesStatus = _statusFilter == 'All' || status == _statusFilter;

      return matchesSearch && matchesStatus;
    }).toList();

    result.sort((a, b) {
      int comparison;
      switch (_sortBy) {
        case 'Customer Code':
          comparison = a.customerCode.compareTo(b.customerCode);
          break;
        case 'Created Date':
          comparison = a.createdDate.compareTo(b.createdDate);
          break;
        case 'Name':
        default:
          comparison = a.fullName.compareTo(b.fullName);
      }
      return _sortAscending ? comparison : -comparison;
    });

    return result;
  }

  List<Customer> get _pagedCustomers {
    final customers = _filteredCustomers;
    final start = (_currentPage - 1) * _rowsPerPage;
    if (start >= customers.length) return [];

    final end = (start + _rowsPerPage > customers.length)
        ? customers.length
        : start + _rowsPerPage;

    return customers.sublist(start, end);
  }

  int get _totalPages {
    final count = _filteredCustomers.length;
    return count == 0 ? 1 : (count / _rowsPerPage).ceil();
  }

  @override
  Widget build(BuildContext context) {
    final customers = _filteredCustomers;
    final pagedCustomers = _pagedCustomers;

    final startNumber = customers.isEmpty
        ? 0
        : ((_currentPage - 1) * _rowsPerPage) + 1;
    final endNumber = customers.isEmpty
        ? 0
        : startNumber + pagedCustomers.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xffF4F6FA),
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Customers',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildFilters(),
            const SizedBox(height: 20),
            _buildTableCard(pagedCustomers),
            const SizedBox(height: 16),
            _buildPagination(
              customers: customers,
              startNumber: startNumber,
              endNumber: endNumber,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return _headerContent(constraints.maxWidth);
      },
    );
  }

  Widget _headerContent(double maxWidth) {
    final title = const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Customers',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 6),
        Text(
          'Manage customer records and relationships',
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
      ],
    );

    final addButton = ElevatedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const CreateCustomerScreen(),
          ),
        );
      },
      icon: const Icon(Icons.person_add_alt_1),
      label: const Text('Add Customer'),
    );

    if (maxWidth < 520) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
    final search = _searchField();
    final status = _filterDropdown(
      label: 'Status',
      value: _statusFilter,
      items: const ['All', 'Active', 'Inactive'],
      onChanged: (value) => setState(() {
        _statusFilter = value ?? 'All';
        _currentPage = 1;
      }),
    );
    final sort = _filterDropdown(
      label: 'Sort',
      value: _sortBy,
      items: const ['Name', 'Customer Code', 'Created Date'],
      onChanged: (value) => setState(() {
        _sortBy = value ?? 'Name';
        _currentPage = 1;
      }),
    );
    final direction = IconButton(
      tooltip: _sortAscending ? 'Ascending' : 'Descending',
      onPressed: () => setState(() {
        _sortAscending = !_sortAscending;
        _currentPage = 1;
      }),
      icon: Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward),
    );

    if (maxWidth < 520) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          search,
          const SizedBox(height: 14),
          status,
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: sort),
              direction,
            ],
          ),
        ],
      );
    }

    if (maxWidth < 760) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          search,
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: status),
              const SizedBox(width: 14),
              Expanded(flex: 2, child: sort),
              direction,
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: search),
        const SizedBox(width: 14),
        SizedBox(width: 170, child: status),
        const SizedBox(width: 14),
        SizedBox(width: 200, child: sort),
        direction,
      ],
    );
  }

  Widget _searchField() {
    return TextField(
      controller: _searchController,
      onChanged: (_) => setState(() => _currentPage = 1),
      decoration: InputDecoration(
        hintText: 'Search name, code, phone or email',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() => _currentPage = 1);
                },
                icon: const Icon(Icons.clear),
              )
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildTableCard(List<Customer> pagedCustomers) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final table = _customerTable(pagedCustomers);
          final available = constraints.maxWidth;

          if (available >= _minTableWidth) {
            return SizedBox(width: available, child: table);
          }

          return Scrollbar(
            controller: _tableScrollController,
            thumbVisibility: true,
            scrollbarOrientation: ScrollbarOrientation.bottom,
            child: SingleChildScrollView(
              controller: _tableScrollController,
              scrollDirection: Axis.horizontal,
              child: SizedBox(width: _minTableWidth, child: table),
            ),
          );
        },
      ),
    );
  }

  Widget _customerTable(List<Customer> pagedCustomers) {
    return DataTable(
      showCheckboxColumn: false,
      columnSpacing: 28,
      headingRowHeight: 56,
      dataRowMinHeight: 62,
      dataRowMaxHeight: 72,
      headingRowColor: const WidgetStatePropertyAll(Color(0xffF7F8FC)),
      columns: const [
        DataColumn(
          label: Flexible(
            child: Text('Customer', overflow: TextOverflow.ellipsis),
          ),
          columnWidth: MaxColumnWidth(
            FixedColumnWidth(180),
            FlexColumnWidth(2.4),
          ),
        ),
        DataColumn(
          label: Flexible(
            child: Text('Code', overflow: TextOverflow.ellipsis),
          ),
          columnWidth: MaxColumnWidth(
            FixedColumnWidth(120),
            FlexColumnWidth(1.3),
          ),
        ),
        DataColumn(
          label: Flexible(
            child: Text('Mobile', overflow: TextOverflow.ellipsis),
          ),
          columnWidth: MaxColumnWidth(
            FixedColumnWidth(150),
            FlexColumnWidth(1.6),
          ),
        ),
        DataColumn(
          label: Flexible(
            child: Text('Email', overflow: TextOverflow.ellipsis),
          ),
          columnWidth: MaxColumnWidth(
            FixedColumnWidth(220),
            FlexColumnWidth(2.6),
          ),
        ),
        DataColumn(
          label: Flexible(
            child: Text('Gender', overflow: TextOverflow.ellipsis),
          ),
          columnWidth: MaxColumnWidth(
            FixedColumnWidth(120),
            FlexColumnWidth(1.2),
          ),
        ),
        DataColumn(
          label: Flexible(
            child: Text('Actions', overflow: TextOverflow.ellipsis),
          ),
          columnWidth: FixedColumnWidth(148),
        ),
      ],
      rows: pagedCustomers.map<DataRow>((customer) {
        return DataRow(
          cells: [
            DataCell(
              Text(
                customer.fullName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            DataCell(
              Text(
                customer.customerCode,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            DataCell(
              Text(
                customer.mobileNumber,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            DataCell(
              Text(
                customer.email ?? '—',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            DataCell(
              Text(
                customer.gender ?? '—',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            DataCell(
              PopupMenuButton<String>(
                tooltip: 'Actions',
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.more_vert),
                onSelected: (action) {
                  switch (action) {
                    case 'view':
                      // TODO: Connect to Customer Details screen.
                      break;
                    case 'edit':
                      // TODO: Connect to Customer Edit form.
                      break;
                    case 'delete':
                      // TODO: Connect to Delete confirmation.
                      break;
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem<String>(
                    value: 'view',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.visibility_outlined, size: 20),
                        SizedBox(width: 12),
                        Text('View'),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'edit',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit_outlined, size: 20),
                        SizedBox(width: 12),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.delete_outline, size: 20),
                        SizedBox(width: 12),
                        Text('Delete'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildPagination({
    required List<Customer> customers,
    required int startNumber,
    required int endNumber,
  }) {
    final summary = Text(
      customers.isEmpty
          ? 'No customers found'
          : 'Showing $startNumber–$endNumber of ${customers.length} customers',
      style: const TextStyle(color: Colors.grey),
    );

    final controls = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Previous',
          onPressed: _currentPage > 1
              ? () => setState(() => _currentPage--)
              : null,
          icon: const Icon(Icons.chevron_left),
        ),
        Text(
          'Page $_currentPage of $_totalPages',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        IconButton(
          tooltip: 'Next',
          onPressed: _currentPage < _totalPages
              ? () => setState(() => _currentPage++)
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
            children: [summary, const SizedBox(height: 4), controls],
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

  Widget _filterDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: items
          .map(
            (item) => DropdownMenuItem<String>(
              value: item,
              child: Text(item, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}
