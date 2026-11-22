import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/transaction.dart';

class TransactionCategoryGroup extends StatelessWidget {
  final String title;
  final String formattedTotal;
  final Color accentColor;
  final String? emptyMessage;
  final List<Transaction> transactions;
  final NumberFormat currency;
  final Widget Function(Transaction tx) itemBuilder;

  const TransactionCategoryGroup({
    super.key,
    required this.title,
    required this.formattedTotal,
    required this.accentColor,
    required this.transactions,
    required this.currency,
    required this.itemBuilder,
    this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$title (${transactions.length})',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: accentColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            Text(
              formattedTotal,
              style: TextStyle(
                color: accentColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (transactions.isEmpty && emptyMessage != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(emptyMessage!, style: const TextStyle(color: Colors.grey)),
          )
        else
          ...transactions.map(itemBuilder),
      ],
    );
  }
}
