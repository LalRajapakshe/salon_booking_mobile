import 'package:flutter/material.dart';

import '../models/customer_model.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _statusFilter = 'All';
  String _sortBy = 'Name';
  bool _sortAscending = true;
  int _currentPage = 1;

  static const int _rowsPerPage = 8;

  // Temporary mock data using the existing Customer model.
  // Replace this list with repository/API data later.
  final List<Customer> _customers = [
    Customer(
      id: 1, customerCode: 'CUS-001', firstName: 'Amanda', lastName: 'Silva',
      mobileNumber: '0771234567', email: 'amanda@example.com', gender: 'Female',
      dateOfBirth: DateTime(1994, 5, 12), address: 'Colombo',
      notes: 'Regular customer', isActive: true, createdDate: DateTime(2026, 1, 10),
    ),
    Customer(
      id: 2, customerCode: 'CUS-002', firstName: 'Sarah', lastName: 'Perera',
      mobileNumber: '0712345678', email: 'sarah@example.com', gender: 'Female',
      dateOfBirth: DateTime(1996, 8, 21), address: 'Nugegoda',
      notes: null, isActive: true, createdDate: DateTime(2026, 1, 18),
    ),
    Customer(
      id: 3, customerCode: 'CUS-003', firstName: 'Emma', lastName: 'Fernando',
      mobileNumber: '0751234567', email: 'emma@example.com', gender: 'Female',
      dateOfBirth: DateTime(1992, 3, 8), address: 'Rajagiriya',
      notes: 'Prefers evening appointments', isActive: true, createdDate: DateTime(2026, 2, 2),
    ),
    Customer(
      id: 4, customerCode: 'CUS-004', firstName: 'Nethmi', lastName: 'Perera',
      mobileNumber: '0763456789', email: 'nethmi@example.com', gender: 'Female',
      dateOfBirth: DateTime(1998, 11, 17), address: 'Maharagama',
      notes: null, isActive: false, createdDate: DateTime(2026, 2, 14),
    ),
    Customer(
      id: 5, customerCode: 'CUS-005', firstName: 'Daniel', lastName: 'Silva',
      mobileNumber: '0724567890', email: 'daniel@example.com', gender: 'Male',
      dateOfBirth: DateTime(1990, 7, 4), address: 'Dehiwala',
      notes: null, isActive: true, createdDate: DateTime(2026, 2, 20),
    ),
    Customer(
      id: 6, customerCode: 'CUS-006', firstName: 'Jessica', lastName: 'Fernando',
      mobileNumber: '0785678901', email: 'jessica@example.com', gender: 'Female',
      dateOfBirth: DateTime(1995, 9, 26), address: 'Kotte',
      notes: 'Frequent customer', isActive: true, createdDate: DateTime(2026, 3, 1),
    ),
    Customer(
      id: 7, customerCode: 'CUS-007', firstName: 'Kevin', lastName: 'Perera',
      mobileNumber: '0706789012', email: 'kevin@example.com', gender: 'Male',
      dateOfBirth: DateTime(1988, 12, 2), address: 'Battaramulla',
      notes: null, isActive: false, createdDate: DateTime(2026, 3, 11),
    ),
    Customer(
      id: 8, customerCode: 'CUS-008', firstName: 'Michelle', lastName: 'Silva',
      mobileNumber: '0747890123', email: 'michelle@example.com', gender: 'Female',
      dateOfBirth: DateTime(1997, 1, 19), address: 'Mount Lavinia',
      notes: null, isActive: true, createdDate: DateTime(2026, 3, 25),
    ),
    Customer(
      id: 9, customerCode: 'CUS-009', firstName: 'Ryan', lastName: 'Fernando',
      mobileNumber: '0778901234', email: 'ryan@example.com', gender: 'Male',
      dateOfBirth: DateTime(1991, 6, 15), address: 'Colombo',
      notes: null, isActive: true, createdDate: DateTime(2026, 4, 4),
    ),
    Customer(
      id: 10, customerCode: 'CUS-010', firstName: 'Sophie', lastName: 'Perera',
      mobileNumber: '0719012345', email: 'sophie@example.com', gender: 'Female',
      dateOfBirth: DateTime(1999, 10, 30), address: 'Wattala',
      notes: null, isActive: true, createdDate: DateTime(2026, 4, 15),
    ),
    Customer(
      id: 11, customerCode: 'CUS-011', firstName: 'Jason', lastName: 'Silva',
      mobileNumber: '0761122334', email: 'jason@example.com', gender: 'Male',
      dateOfBirth: DateTime(1989, 4, 10), address: 'Wellawatte',
      notes: null, isActive: true, createdDate: DateTime(2026, 4, 22),
    ),
    Customer(
      id: 12, customerCode: 'CUS-012', firstName: 'Olivia', lastName: 'Fernando',
      mobileNumber: '0752233445', email: null, gender: 'Female',
      dateOfBirth: null, address: 'Colombo',
      notes: 'Email not provided', isActive: false, createdDate: DateTime(2026, 5, 3),
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
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
      final matchesStatus =
          _statusFilter == 'All' || status == _statusFilter;

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

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Customers',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Manage customer records and relationships',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Add Customer'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 320,
                      child: TextField(
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
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    _filterDropdown(
                      label: 'Status',
                      value: _statusFilter,
                      items: const ['All', 'Active', 'Inactive'],
                      onChanged: (value) => setState(() {
                        _statusFilter = value ?? 'All';
                        _currentPage = 1;
                      }),
                    ),
                    _filterDropdown(
                      label: 'Sort',
                      value: _sortBy,
                      items: const ['Name', 'Customer Code', 'Created Date'],
                      onChanged: (value) => setState(() {
                        _sortBy = value ?? 'Name';
                        _currentPage = 1;
                      }),
                    ),
                    IconButton(
                      tooltip: _sortAscending ? 'Ascending' : 'Descending',
                      onPressed: () => setState(() {
                        _sortAscending = !_sortAscending;
                        _currentPage = 1;
                      }),
                      icon: Icon(
                        _sortAscending
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            Card(
              elevation: 0,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 28,
                  headingRowHeight: 56,
                  dataRowMinHeight: 62,
                  dataRowMaxHeight: 72,
                  headingRowColor: MaterialStateProperty.all(
                    const Color(0xffF7F8FC),
                  ),
                    columns: const [
                      DataColumn(label: Text('Customer')),
                      DataColumn(label: Text('Code')),
                      DataColumn(label: Text('Mobile')),
                      DataColumn(label: Text('Email')),
                      DataColumn(label: Text('Gender')),
                      DataColumn(label: Text('Actions')),
                    ],
                  rows: pagedCustomers.map<DataRow>((customer) {
                  //  final status = customer.isActive ? 'Active' : 'Inactive';

                    return DataRow(
                      cells: [
                        DataCell(
                          Text(
                            customer.fullName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        DataCell(Text(customer.customerCode)),
                        DataCell(Text(customer.mobileNumber)),
                        DataCell(Text(customer.email ?? '—')),
DataCell(
  Text(customer.gender ?? '—'),
),
DataCell(
  PopupMenuButton<String>(
    tooltip: 'Actions',
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
        child: ListTile(
          leading: Icon(Icons.visibility_outlined),
          title: Text('View'),
          contentPadding: EdgeInsets.zero,
        ),
      ),
      PopupMenuItem<String>(
        value: 'edit',
        child: ListTile(
          leading: Icon(Icons.edit_outlined),
          title: Text('Edit'),
          contentPadding: EdgeInsets.zero,
        ),
      ),
      PopupMenuItem<String>(
        value: 'delete',
        child: ListTile(
          leading: Icon(Icons.delete_outline),
          title: Text('Delete'),
          contentPadding: EdgeInsets.zero,
        ),
      ),
    ],
  ),
),                        
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Text(
                    customers.isEmpty
                        ? 'No customers found'
                        : 'Showing $startNumber–$endNumber '
                            'of ${customers.length} customers',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return SizedBox(
      width: 170,
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        items: items
            .map(
              (item) => DropdownMenuItem<String>(
                value: item,
                child: Text(item),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _statusBadge(String status) {
    final isActive = status == 'Active';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.green.withOpacity(0.10)
            : Colors.grey.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isActive ? Colors.green : Colors.grey,
        ),
      ),
    );
  }
}
