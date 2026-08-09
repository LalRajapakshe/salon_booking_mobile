import 'package:flutter/material.dart';

import '../models/employee_revenue.dart';

class TopEmployeeCard extends StatelessWidget {
  final EmployeeRevenue? employee;
  const TopEmployeeCard({Key? key, this.employee}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(employee?.name ?? 'Top Employee'),
        subtitle: Text('Revenue: \$${employee?.revenue.toStringAsFixed(2) ?? '0.00'}'),
      ),
    );
  }
}
