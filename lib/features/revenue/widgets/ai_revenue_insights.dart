import 'package:flutter/material.dart';

class AiRevenueInsights extends StatelessWidget {
  const AiRevenueInsights({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('AI Revenue Insights'),
            SizedBox(height: 8),
            Text('No insights yet.'),
          ],
        ),
      ),
    );
  }
}
