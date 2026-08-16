import 'package:flutter/material.dart';

import '../models/transaction_model.dart';

class RecentTransactionsTable extends StatelessWidget {
  final List<TransactionModel> transactions;
  const RecentTransactionsTable({Key? key, this.transactions = const []}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: transactions.isEmpty
              ? [const Text('No recent transactions')]
              : transactions.map((t) => ListTile(
                    title: Text(t.service ?? 'Service'),
                    subtitle: Text(t.customerName),
                    trailing: Text('\$${t.amount.toStringAsFixed(2)}'),
                  )).toList(),
        ),
      ),
    );
  }
}
