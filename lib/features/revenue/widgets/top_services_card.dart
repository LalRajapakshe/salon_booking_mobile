import 'package:flutter/material.dart';

class TopServicesCard extends StatelessWidget {
  const TopServicesCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Top Services'),
            SizedBox(height: 8),
            Text('1. Service A'),
            Text('2. Service B'),
          ],
        ),
      ),
    );
  }
}
