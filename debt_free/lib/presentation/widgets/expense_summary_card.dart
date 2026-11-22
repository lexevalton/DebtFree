import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ExpenseSummaryCard extends StatelessWidget {
  final double totalSpent;
  final int transactionCount;

  const ExpenseSummaryCard({
    super.key,
    required this.totalSpent,
    required this.transactionCount,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'en_CA', symbol: '\$');

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Expenses (12 Months)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '$transactionCount transactions',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            Text(
              currencyFormat.format(totalSpent),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
