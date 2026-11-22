import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/transaction.dart';

class TransactionTile extends StatelessWidget {
  final Transaction transaction;

  const TransactionTile({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'en_CA', symbol: '\$');
    final dateStr = DateFormat('yyyy-MM-dd').format(transaction.date);

    return ListTile(
      title: Text(
        transaction.merchant,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text('$dateStr  •  ${transaction.account.displayName}'),
      trailing: Text(
        currencyFormat.format(transaction.absoluteAmount),
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
    );
  }
}
