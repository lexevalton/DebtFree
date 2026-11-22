import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/account_type.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/transaction_type.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../widgets/global_summary_card.dart';
import '../widgets/monthly_cashflow_section.dart';

class ExpensesPage extends StatefulWidget {
  final TransactionRepository repository;

  const ExpensesPage({super.key, required this.repository});

  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  List<Transaction> _transactions = [];
  bool _isLoading = true;
  List<String> _categories = ['Uncategorized'];
  bool _isSelectionMode = false;
  final Map<String, String> _pendingCategoryEdits = {};
  bool _rememberBulkRules = true;
  bool _onlyUncategorized = false;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    final items = await widget.repository.getLastTwelveMonthsTransactions();
    final cats = await widget.repository.getCategories();
    setState(() {
      _transactions = items;
      _categories = cats.isEmpty ? ['Uncategorized'] : cats;
      _isLoading = false;
    });
  }

  Future<void> _handleRefresh() async {
    if (_transactions.isEmpty) {
      await _executeSync(replaceExisting: false);
      return;
    }

    final replaceExisting = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import Transactions'),
        content: const Text(
          'Do you want to append new transactions to existing data or replace everything?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Cancel'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Replace all'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Append'),
          ),
        ],
      ),
    );

    if (replaceExisting == null) return;
    await _executeSync(replaceExisting: replaceExisting);
  }

  Future<void> _executeSync({required bool replaceExisting}) async {
    final newCount = await widget.repository.syncFromSource(
      replaceExisting: replaceExisting,
    );
    await _loadTransactions();

    if (mounted) {
      final msg = replaceExisting
          ? 'Database replaced with $newCount transactions.'
          : 'Added $newCount new transactions.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _changeTransactionType(Transaction tx, TransactionType newType) async {
    await widget.repository.updateTransactionType(tx.id, newType);
    await _loadTransactions();
  }

  Map<String, List<Transaction>> get _groupedByMonth {
    final Map<String, List<Transaction>> grouped = {};
    for (final tx in _transactions) {
      if (_onlyUncategorized &&
          tx.category != 'Uncategorized' &&
          !_pendingCategoryEdits.containsKey(tx.id)) {
        continue;
      }
      final key = DateFormat('yyyy-MM').format(tx.date);
      grouped.putIfAbsent(key, () => []).add(tx);
      }
      return grouped;
    }

  @override
  Widget build(BuildContext context) {
    final monthlyGroups = _groupedByMonth.entries.toList();

    final totalExpenses = _transactions
        .where((tx) => tx.isExpense)
        .fold(0.0, (sum, tx) => sum + tx.absoluteAmount);

    final totalIncomes = _transactions
        .where((tx) => tx.isIncome)
        .fold(0.0, (sum, tx) => sum + tx.absoluteAmount);

    final totalTransfers = _transactions
        .where((tx) => tx.isTransfer)
        .fold(0.0, (sum, tx) => sum + tx.absoluteAmount);

    final totalDebitExpenses = _transactions
        .where((tx) => tx.isExpense && tx.account == AccountType.rbcChequing)
        .fold(0.0, (sum, tx) => sum + tx.absoluteAmount);

    final totalCreditExpenses = _transactions
        .where((tx) => tx.isExpense && tx.account == AccountType.rbcVisa)
        .fold(0.0, (sum, tx) => sum + tx.absoluteAmount);

    final uncategorizedCount = _transactions
        .where((tx) => tx.category == 'Uncategorized')
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('DebtFree — Clear your debts !'),
        actions: [
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _isSelectionMode = !_isSelectionMode;
                _pendingCategoryEdits.clear();
              });
            },
            icon: Icon(_isSelectionMode ? Icons.close : Icons.checklist),
            label: Text(_isSelectionMode ? 'Cancel Bulk' : 'Bulk Edit'),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: _handleRefresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      bottomNavigationBar: _isSelectionMode
          ? BottomAppBar(
              child: Row(
                children: [
                  Text(
                    '${_pendingCategoryEdits.length} modified',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberBulkRules,
                        onChanged: (val) =>
                            setState(() => _rememberBulkRules = val ?? true),
                      ),
                      const Text('Remember rules', style: TextStyle(fontSize: 13)),
                    ],
                  ),
                  const SizedBox(width: 16),
                  FilledButton.icon(
                    onPressed: _pendingCategoryEdits.isEmpty ? null : _saveAllBulkEdits,
                    icon: const Icon(Icons.save),
                    label: const Text('Save All'),
                  ),
                ],
              ),
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                GlobalSummaryCard(
                  totalExpenses: totalExpenses,
                  totalIncomes: totalIncomes,
                  totalTransfers: totalTransfers,
                  totalDebitExpenses: totalDebitExpenses,
                  totalCreditExpenses: totalCreditExpenses,
                  transactionCount: _transactions.length,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Row(
                    children: [
                      FilterChip(
                        avatar: const Icon(Icons.filter_list, size: 16),
                        label: Text('Uncategorized only ($uncategorizedCount)'),
                        selected: _onlyUncategorized,
                        onSelected: (val) => setState(() => _onlyUncategorized = val),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: monthlyGroups.isEmpty
                      ? const Center(
                          child: Text(
                            'No transactions yet.\nClick "Refresh" to import your RBC CSVs.',
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.builder(
                          itemCount: monthlyGroups.length,
                          itemBuilder: (context, index) {
                            final entry = monthlyGroups[index];
                            final monthDate = DateTime.parse('${entry.key}-01');
                            final monthTitle = DateFormat('MMMM yyyy').format(monthDate);

                            final expenses = entry.value.where((tx) => tx.isExpense).toList();
                            final incomes = entry.value.where((tx) => tx.isIncome).toList();
                            final transfers = entry.value.where((tx) => tx.isTransfer).toList();

                            return MonthlyCashflowSection(
                              monthTitle: monthTitle,
                              expenses: expenses,
                              incomes: incomes,
                              transfers: transfers,
                              categories: _categories,
                              isSelectionMode: _isSelectionMode,
                              pendingCategoryEdits: _pendingCategoryEdits,
                              onStageCategoryEdit: _stageCategoryEdit,
                              onChangeType: _changeTransactionType,
                              onAssignCategory: _assignSingleCategory,
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Future<void> _assignSingleCategory(Transaction tx, String category, bool remember) async {
    await widget.repository.assignCategoryToMerchant(
      transactionId: tx.id,
      merchant: tx.merchant,
      category: category,
      rememberForFuture: remember,
    );
    await _loadTransactions();
  }

  void _stageCategoryEdit(String txId, String newCategory) {
    setState(() {
      _pendingCategoryEdits[txId] = newCategory;
    });
  }

  Future<void> _saveAllBulkEdits() async {
    if (_pendingCategoryEdits.isEmpty) return;

    final Map<Transaction, String> updates = {};
    for (final entry in _pendingCategoryEdits.entries) {
      final tx = _transactions.firstWhere((t) => t.id == entry.key);
      updates[tx] = entry.value;
    }

    await widget.repository.saveBulkCategoryMap(
      updates: updates,
      rememberRules: _rememberBulkRules,
    );

    final count = updates.length;
    setState(() {
      _isSelectionMode = false;
      _pendingCategoryEdits.clear();
    });
    await _loadTransactions();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved $count category updates.')),
      );
    }
  }

}