import 'package:flutter/material.dart';

class RevenueStatisticsCard extends StatelessWidget {
  const RevenueStatisticsCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Revenue Statistics'),
            SizedBox(height: 8),
            Text('Avg ticket: \$0.00'),
          ],
        ),
      ),
    );
  }
}
