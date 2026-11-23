import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/account_type.dart';
import '../../domain/entities/goal.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../widgets/allTransactions/expenses_bars.dart';
import '../widgets/allTransactions/global_summary_card.dart';
import '../widgets/allTransactions/import_source_dialog.dart';
import '../widgets/allTransactions/monthly_cashflow_section.dart';

class ExpensesPage extends StatefulWidget {
  final TransactionRepository repository;

  const ExpensesPage({super.key, required this.repository});

  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  List<Transaction> _transactions = [];
  List<Goal> _goals = [];
  bool _isLoading = true;
  List<String> _categories = ['Uncategorized'];
  bool _isSelectionMode = false;
  final Map<String, String> _pendingCategoryEdits = {};
  bool _rememberBulkRules = true;
  bool _onlyUncategorized = false;
  bool _onlyTransfers = false;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    final items = await widget.repository.getLastTwelveMonthsTransactions();
    final cats = await widget.repository.getCategories();
    final goals = await widget.repository.getGoals();
    if (!mounted) return;
    setState(() {
      _transactions = items;
      _categories = cats.isEmpty ? ['Uncategorized'] : cats;
      _goals = goals;
      _isLoading = false;
    });
  }

  Future<void> _handleRefresh() async {
    final selection = await showImportSourceDialog(
      context,
      hasExistingData: _transactions.isNotEmpty,
    );
    if (selection == null) return;

    final chosenSource = selection.method == ImportMethod.webSync
        ? widget.repository.webSyncSource
        : widget.repository.csvSource;

    final newCount = await widget.repository.syncFromSource(
      source: chosenSource,
      replaceExisting: selection.replaceExisting,
    );
    await _loadTransactions();

    if (mounted) {
      final msg = selection.replaceExisting
          ? 'Database replaced with $newCount transactions.'
          : 'Added $newCount new transactions.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Map<String, List<Transaction>> get _groupedByMonth {
    final Map<String, List<Transaction>> grouped = {};
    for (final tx in _transactions) {
      if (_onlyTransfers) {
        if (!tx.isTransfer) continue;
      } else if (_onlyUncategorized &&
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
    final expenses = _transactions.where((tx) => tx.isExpense);
    final uncategorizedCount = _transactions.where((tx) => tx.category == 'Uncategorized').length;
    final savingGoals = _goals.where((g) => g.type == GoalType.saving).toList();

    return Scaffold(
      appBar: ExpensesAppBar(
        isSelectionMode: _isSelectionMode,
        onToggleSelectionMode: () => setState(() {
          _isSelectionMode = !_isSelectionMode;
          _pendingCategoryEdits.clear();
        }),
        onRefresh: _handleRefresh,
      ),
      bottomNavigationBar: _isSelectionMode
          ? BulkEditBottomBar(
              modifiedCount: _pendingCategoryEdits.length,
              rememberRules: _rememberBulkRules,
              onRememberChanged: (val) => setState(() => _rememberBulkRules = val),
              onSaveAll: _saveAllBulkEdits,
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                GlobalSummaryCard(
                  totalExpenses: expenses.fold(0.0, (s, tx) => s + tx.absoluteAmount),
                  totalIncomes: _transactions.where((tx) => tx.isIncome).fold(0.0, (s, tx) => s + tx.absoluteAmount),
                  totalTransfers: _transactions.where((tx) => tx.isTransfer).fold(0.0, (s, tx) => s + tx.absoluteAmount),
                  totalDebitExpenses: expenses.where((tx) => tx.account == AccountType.rbcChequing).fold(0.0, (s, tx) => s + tx.absoluteAmount),
                  totalCreditExpenses: expenses.where((tx) => tx.account == AccountType.rbcVisa).fold(0.0, (s, tx) => s + tx.absoluteAmount),
                  transactionCount: _transactions.length,
                  isTransfersOnly: _onlyTransfers,
                  onToggleTransfersOnly: () => setState(() {
                    _onlyTransfers = !_onlyTransfers;
                    if (_onlyTransfers) _onlyUncategorized = false;
                  }),
                ),
                ExpensesFilterBar(
                  uncategorizedCount: uncategorizedCount,
                  onlyUncategorized: _onlyUncategorized,
                  onUncategorizedChanged: (val) => setState(() => _onlyUncategorized = val),
                ),
                Expanded(
                  child: monthlyGroups.isEmpty
                      ? const Center(
                          child: Text(
                            'No transactions yet.\nClick "Refresh" to sync with RBC or import CSVs.',
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.builder(
                          itemCount: monthlyGroups.length,
                          itemBuilder: (context, index) {
                            final entry = monthlyGroups[index];
                            final monthTitle = DateFormat('MMMM yyyy').format(DateTime.parse('${entry.key}-01'));

                            return MonthlyCashflowSection(
                              key: ValueKey(entry.key),
                              monthTitle: monthTitle,
                              expenses: entry.value.where((tx) => tx.isExpense).toList(),
                              incomes: entry.value.where((tx) => tx.isIncome).toList(),
                              transfers: entry.value.where((tx) => tx.isTransfer).toList(),
                              categories: _categories,
                              savingGoals: savingGoals,
                              isSelectionMode: _isSelectionMode,
                              pendingCategoryEdits: _pendingCategoryEdits,
                              showTransfersOnly: _onlyTransfers,
                              onStageCategoryEdit: (id, cat) => setState(() => _pendingCategoryEdits[id] = cat),
                              onChangeType: (tx, type) async {
                                await widget.repository.updateTransactionType(tx.id, type);
                                await _loadTransactions();
                              },
                              onAssignCategory: (tx, cat, remember) async {
                                await widget.repository.assignCategoryToMerchant(
                                  transactionId: tx.id,
                                  merchant: tx.merchant,
                                  category: cat,
                                  rememberForFuture: remember,
                                );
                                await _loadTransactions();
                              },
                              onAssignGoal: (tx, goalId) async {
                                await widget.repository.assignGoalToTransaction(tx.id, goalId);
                                await _loadTransactions();
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Future<void> _saveAllBulkEdits() async {
    if (_pendingCategoryEdits.isEmpty) return;

    final Map<Transaction, String> updates = {
      for (final entry in _pendingCategoryEdits.entries)
        _transactions.firstWhere((t) => t.id == entry.key): entry.value,
    };

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
