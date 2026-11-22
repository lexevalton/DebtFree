import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/account_type.dart';
import '../../../domain/entities/goal.dart';
import '../../../domain/entities/transaction.dart';
import '../../../domain/entities/transaction_type.dart';
import '../transaction_category_group.dart';
import '../transaction_edit_dialog.dart';
import '../transaction_row_card.dart';
import 'month_breakdown_bar.dart';

class MonthlyCashflowSection extends StatefulWidget {
  final String monthTitle;
  final List<Transaction> expenses;
  final List<Transaction> incomes;
  final List<Transaction> transfers;
  final List<String> categories;
  final List<Goal> savingGoals;
  final bool isSelectionMode;
  final bool showTransfersOnly;
  final Map<String, String> pendingCategoryEdits;
  final void Function(Transaction tx, TransactionType newType) onChangeType;
  final void Function(String txId, String newCategory) onStageCategoryEdit;
  final void Function(Transaction tx, String category, bool remember) onAssignCategory;
  final void Function(Transaction tx, String? goalId)? onAssignGoal;

  const MonthlyCashflowSection({
    super.key,
    required this.monthTitle,
    required this.expenses,
    required this.incomes,
    required this.transfers,
    required this.categories,
    this.savingGoals = const [],
    required this.isSelectionMode,
    this.showTransfersOnly = false,
    required this.pendingCategoryEdits,
    required this.onChangeType,
    required this.onStageCategoryEdit,
    required this.onAssignCategory,
    this.onAssignGoal,
  });

  @override
  State<MonthlyCashflowSection> createState() => _MonthlyCashflowSectionState();
}

class _MonthlyCashflowSectionState extends State<MonthlyCashflowSection> {
  bool _showDetails = false;

  double _sum(List<Transaction> list) =>
      list.fold(0.0, (sum, tx) => sum + tx.absoluteAmount);

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'en_CA', symbol: '\$');
    final debitExpenses = _sum(
      widget.expenses.where((tx) => tx.account == AccountType.rbcChequing).toList(),
    );
    final creditExpenses = _sum(
      widget.expenses.where((tx) => tx.account == AccountType.rbcVisa).toList(),
    );
    final totalTransfers = _sum(widget.transfers);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                icon: Icon(_showDetails ? Icons.expand_less : Icons.expand_more, size: 18),
                label: Text(_showDetails ? 'Show less' : 'Show more', style: const TextStyle(fontSize: 12)),
              ),
            ],
          ),
          MonthBreakdownBar(
            isVisible: _showDetails,
            debitExpenses: debitExpenses,
            creditExpenses: creditExpenses,
            totalTransfers: totalTransfers,
            currency: currency,
          ),
          const SizedBox(height: 10),
          if (widget.showTransfersOnly)
            TransactionCategoryGroup(
              title: 'Transfers',
              formattedTotal: currency.format(totalTransfers),
              accentColor: Colors.blue.shade700,
              emptyMessage: 'No transfers for this month',
              transactions: widget.transfers,
              currency: currency,
              itemBuilder: (tx) => _buildRow(tx, currency),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TransactionCategoryGroup(
                    title: 'Expenses',
                    formattedTotal: '-${currency.format(_sum(widget.expenses))}',
                    accentColor: Colors.red.shade700,
                    emptyMessage: 'No expenses',
                    transactions: widget.expenses,
                    currency: currency,
                    itemBuilder: (tx) => _buildRow(tx, currency),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TransactionCategoryGroup(
                    title: 'Income',
                    formattedTotal: '+${currency.format(_sum(widget.incomes))}',
                    accentColor: Colors.green.shade700,
                    emptyMessage: 'No income',
                    transactions: widget.incomes,
                    currency: currency,
                    itemBuilder: (tx) => _buildRow(tx, currency),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 16),
          const Divider(thickness: 2, height: 1),
        ],
      ),
    );
  }

  Widget _buildRow(Transaction tx, NumberFormat currency) {
    return TransactionRowCard(
      tx: tx,
      currency: currency,
      categories: widget.categories,
      isSelectionMode: widget.isSelectionMode,
      pendingCategory: widget.pendingCategoryEdits[tx.id],
      onStageCategoryEdit: widget.onStageCategoryEdit,
      onTap: () => showTransactionEditDialog(
        context: context,
        tx: tx,
        categories: widget.categories,
        onChangeType: widget.onChangeType,
        onAssignCategory: widget.onAssignCategory,
        savingGoals: widget.savingGoals,
        onAssignGoal: widget.onAssignGoal,
      ),
    );
  }
}
