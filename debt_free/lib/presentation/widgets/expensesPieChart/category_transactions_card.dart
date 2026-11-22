import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/account_type.dart';
import '../../../domain/entities/transaction.dart';

class CategoryTransactionsCard extends StatelessWidget {
  final String? category;
  final List<Transaction> transactions;
  final VoidCallback onClear;

  const CategoryTransactionsCard({
    super.key,
    required this.category,
    required this.transactions,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'en_CA', symbol: '\$');
    final sorted = [...transactions]..sort((a, b) => b.date.compareTo(a.date));
    final total = sorted.fold<double>(0.0, (s, tx) => s + tx.absoluteAmount);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    category == null ? 'Category Transactions' : '$category (${sorted.length})',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (category != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    tooltip: 'Clear selection',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: onClear,
                  ),
              ],
            ),
            Text(
              category == null ? '\$0.00' : '-${currency.format(total)}',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: category == null ? Colors.grey : Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: category == null
                  ? const Center(
                      child: Text(
                        'Click a slice on the chart to inspect its transactions.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: sorted.length,
                      itemBuilder: (context, i) {
                        final tx = sorted[i];
                        final isDebit = tx.account == AccountType.rbcChequing;
                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 54,
                                padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: isDebit ? Colors.orange.shade100 : Colors.purple.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  isDebit ? 'DEBIT' : 'CREDIT',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isDebit ? Colors.orange.shade900 : Colors.purple.shade900,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tx.merchant,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                    ),
                                    Text(
                                      DateFormat('dd MMM yyyy').format(tx.date),
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '-${currency.format(tx.absoluteAmount)}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red.shade800,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
