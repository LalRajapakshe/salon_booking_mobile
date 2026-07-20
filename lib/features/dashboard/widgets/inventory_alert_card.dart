import 'package:flutter/material.dart';

class InventoryAlertCard extends StatelessWidget {
  const InventoryAlertCard({super.key});

  @override
  Widget build(BuildContext context) {
    final alerts = [
      ("Hair Colour", 2),
      ("Conditioner", 6),
      ("Wax", 5),
      ("Shampoo", 8),
    ];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Inventory Alerts",
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            ...alerts.map(
              (e) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: Colors.red.shade100,
                  child: const Icon(
                    Icons.inventory_2,
                    color: Colors.red,
                  ),
                ),
                title: Text(e.$1),
                subtitle: Text("${e.$2} remaining"),
                trailing: const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}