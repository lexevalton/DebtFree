import 'package:flutter/material.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/transaction_type.dart';

Future<void> showTransactionEditDialog({
  required BuildContext context,
  required Transaction tx,
  required List<String> categories,
  required void Function(Transaction tx, TransactionType newType) onChangeType,
  required void Function(Transaction tx, String category, bool remember) onAssignCategory,
}) async {
  String selectedCat = categories.contains(tx.category)
      ? tx.category
      : 'Uncategorized';
  bool remember = true;

  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        title: Tooltip(
          message: tx.merchant,
          waitDuration: const Duration(milliseconds: 300),
          child: Text(
            tx.merchant,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Category', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: selectedCat,
              isExpanded: true,
              items: categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setDialogState(() => selectedCat = val);
              },
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: remember,
              title: const Text('Remember for this merchant', style: TextStyle(fontSize: 13)),
              onChanged: (val) => setDialogState(() => remember = val ?? true),
            ),
            const Divider(),
            const Text('Transaction Type', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            SegmentedButton<TransactionType>(
              segments: const [
                ButtonSegment(value: TransactionType.expense, label: Text('Expense')),
                ButtonSegment(value: TransactionType.income, label: Text('Income')),
                ButtonSegment(value: TransactionType.transfer, label: Text('Transfer')),
              ],
              selected: {tx.type},
              onSelectionChanged: (set) {
                Navigator.pop(ctx);
                onChangeType(tx, set.first);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              onAssignCategory(tx, selectedCat, remember);
            },
            child: const Text('Save Category'),
          ),
        ],
      ),
    ),
  );
}
