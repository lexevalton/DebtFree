import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/account_type.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/transaction_type.dart';

class MonthlyCashflowSection extends StatefulWidget {
  final String monthTitle;
  final List<Transaction> expenses;
  final List<Transaction> incomes;
  final List<Transaction> transfers;
  final List<String> categories;
  final bool isSelectionMode;
  final Map<String, String> pendingCategoryEdits;
  final void Function(Transaction tx, TransactionType newType) onChangeType;
  final void Function(String txId, String newCategory) onStageCategoryEdit;
  final void Function(Transaction tx, String category, bool remember) onAssignCategory;


  const MonthlyCashflowSection({
    super.key,
    required this.monthTitle,
    required this.expenses,
    required this.incomes,
    required this.transfers,
    required this.categories,
    required this.isSelectionMode,
    required this.pendingCategoryEdits,
    required this.onChangeType,
    required this.onStageCategoryEdit,
    required this.onAssignCategory,
  });

  @override
  State<MonthlyCashflowSection> createState() => _MonthlyCashflowSectionState();
}

class _MonthlyCashflowSectionState extends State<MonthlyCashflowSection> {
  bool _showDetails = false;

  double get _totalExpenses =>
      widget.expenses.fold(0.0, (sum, tx) => sum + tx.absoluteAmount);

  double get _debitExpenses => widget.expenses
      .where((tx) => tx.account == AccountType.rbcChequing)
      .fold(0.0, (sum, tx) => sum + tx.absoluteAmount);

  double get _creditExpenses => widget.expenses
      .where((tx) => tx.account == AccountType.rbcVisa)
      .fold(0.0, (sum, tx) => sum + tx.absoluteAmount);

  double get _totalIncomes =>
      widget.incomes.fold(0.0, (sum, tx) => sum + tx.absoluteAmount);

  double get _totalTransfers =>
      widget.transfers.fold(0.0, (sum, tx) => sum + tx.absoluteAmount);

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'en_CA', symbol: '\$');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Month title + Show more / Show less
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.monthTitle.toUpperCase(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              TextButton.icon(
                onPressed: () => setState(() => _showDetails = !_showDetails),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: Icon(
                  _showDetails ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                ),
                label: Text(
                  _showDetails ? 'Show less' : 'Show more',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),

          // Expandable breakdown bar (Debit vs Credit vs Transfers)
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              margin: const EdgeInsets.only(top: 6, bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Row(
                    children: [
                      Icon(Icons.account_balance, size: 15, color: Colors.orange.shade800),
                      const SizedBox(width: 6),
                      Text(
                        'Debit: -${currency.format(_debitExpenses)}',
                        style: TextStyle(
                          color: Colors.orange.shade900,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.credit_card, size: 15, color: Colors.purple.shade700),
                      const SizedBox(width: 6),
                      Text(
                        'Credit: -${currency.format(_creditExpenses)}',
                        style: TextStyle(
                          color: Colors.purple.shade800,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.swap_horiz, size: 16, color: Colors.blue.shade700),
                      const SizedBox(width: 6),
                      Text(
                        'Transfers: ${currency.format(_totalTransfers)}',
                        style: TextStyle(
                          color: Colors.blue.shade800,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            crossFadeState:
                _showDetails ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),

          const SizedBox(height: 10),

          // Two columns: Expenses (left, red) | Income (right, green)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // LEFT COLUMN: EXPENSES (RED)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Expenses (${widget.expenses.length})',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        Text(
                          '-${currency.format(_totalExpenses)}',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (widget.expenses.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('No expenses', style: TextStyle(color: Colors.grey)),
                      )
                    else
                      ...widget.expenses.map((tx) => _buildTransactionRow(tx, currency)),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // RIGHT COLUMN: INCOME (GREEN)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Income (${widget.incomes.length})',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        Text(
                          '+${currency.format(_totalIncomes)}',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (widget.incomes.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('No income', style: TextStyle(color: Colors.grey)),
                      )
                    else
                      ...widget.incomes.map((tx) => _buildTransactionRow(tx, currency)),
                  ],
                ),
              ),
            ],
          ),

          // TRANSFERS SECTION (BLUE) — shown below Expenses & Income when present
          if (widget.transfers.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Transfers (${widget.transfers.length})',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  currency.format(_totalTransfers),
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
...widget.transfers.map((tx) => _buildTransactionRow(tx, currency)),
],
const SizedBox(height: 16),
const Divider(thickness: 2, height: 1),
],
),
);
}

  Widget _buildTransactionRow(Transaction tx, NumberFormat currency) {
    final dayStr = DateFormat('dd MMM').format(tx.date);
    final isDebit = tx.account == AccountType.rbcChequing;
    final currentCategory = widget.pendingCategoryEdits[tx.id] ?? tx.category;
    final isModified = widget.pendingCategoryEdits.containsKey(tx.id);

    final Color bgColor;
    final Color amountColor;
    final String prefix;

    switch (tx.type) {
      case TransactionType.expense:
        bgColor = Colors.red.withValues(alpha: 0.04);
        amountColor = Colors.red.shade800;
        prefix = '-';
        break;
      case TransactionType.income:
        bgColor = Colors.green.withValues(alpha: 0.04);
        amountColor = Colors.green.shade800;
        prefix = '+';
        break;
      case TransactionType.transfer:
        bgColor = Colors.blue.withValues(alpha: 0.06);
        amountColor = Colors.blue.shade800;
        prefix = '⇄ ';
        break;
    }

    return InkWell(
      onTap: widget.isSelectionMode ? null : () => _showTypePicker(tx),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: isModified ? Colors.amber.withValues(alpha: 0.15) : bgColor,
          borderRadius: BorderRadius.circular(6),
          border: isModified ? Border.all(color: Colors.amber.shade700, width: 1) : null,
        ),
        child: Row(
          children: [
            // DEBIT / CREDIT badge
            Container(
              width: 58,
              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
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

            // Merchant + Date + Category
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
                    '$dayStr • $currentCategory',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // En mode Bulk Edit : menu déroulant rapide par ligne ; sinon : montant
            if (widget.isSelectionMode)
              SizedBox(
                width: 155,
                child: DropdownButton<String>(
                  value: widget.categories.contains(currentCategory)
                      ? currentCategory
                      : 'Uncategorized',
                  isExpanded: true,
                  isDense: true,
                  underline: const SizedBox.shrink(),
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                  items: widget.categories
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c, overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      widget.onStageCategoryEdit(tx.id, val);
                    }
                  },
                ),
              )
            else
              Text(
                '$prefix${currency.format(tx.absoluteAmount)}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: amountColor,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showTypePicker(Transaction tx) async {
    if (widget.isSelectionMode) {
      return;
    }

    String selectedCat = widget.categories.contains(tx.category)
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
                items: widget.categories
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
                  widget.onChangeType(tx, set.first);
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
                widget.onAssignCategory(tx, selectedCat, remember);
              },
              child: const Text('Save Category'),
            ),
          ],
        ),
      ),
    );
  }


}