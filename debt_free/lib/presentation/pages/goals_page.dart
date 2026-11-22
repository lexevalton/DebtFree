import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/goal.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../widgets/goals/goal_creation_card.dart';
import '../widgets/goals/surplus_banner_card.dart';

class GoalsPage extends StatefulWidget {
  final TransactionRepository repository;

  const GoalsPage({super.key, required this.repository});

  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> {
  List<Goal> _goals = [];
  List<Transaction> _transactions = [];
  List<String> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final goals = await widget.repository.getGoals();
    final txs = await widget.repository.getLastTwelveMonthsTransactions();
    final cats = await widget.repository.getCategories();
    if (!mounted) return;
    setState(() {
      _goals = goals;
      _transactions = txs;
      _categories = cats;
      _isLoading = false;
    });
  }

  double get _availableSurplus {
    final income = _transactions.where((t) => t.isIncome).fold(0.0, (s, t) => s + t.absoluteAmount);
    final expenses = _transactions.where((t) => t.isExpense).fold(0.0, (s, t) => s + t.absoluteAmount);
    final virtualAllocated = _goals
        .where((g) => g.type == GoalType.saving)
        .fold(0.0, (s, g) => s + g.allocatedAmount);
    final linkedWealthsimple = _transactions
        .where((t) => t.isTransfer && t.goalId != null)
        .fold(0.0, (s, t) => s + t.absoluteAmount);

    return income - expenses - virtualAllocated - linkedWealthsimple;
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'en_CA', symbol: '\$');
    final savingGoals = _goals.where((g) => g.type == GoalType.saving).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Goals & Budgets')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SurplusBannerCard(
                  availableSurplus: _availableSurplus,
                  savingGoals: savingGoals,
                  onAllocate: (goalId, amount) async {
                    await widget.repository.allocateToGoal(goalId, amount);
                    await _load();
                  },
                ),
                const SizedBox(height: 16),
                GoalCreationCard(
                  categories: _categories,
                  onCreateGoal: (goal) async {
                    await widget.repository.addGoal(goal);
                    await _load();
                  },
                ),
                const SizedBox(height: 20),
                const Text(
                  'Your Active Goals',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (_goals.isEmpty)
                  const Text('No goals yet.', style: TextStyle(color: Colors.grey))
                else
                  ..._goals.map((g) {
                    final isSaving = g.type == GoalType.saving;
                    final subtitle = isSaving
                        ? 'Saving • Target: ${currency.format(g.targetAmount)} (Allocated: ${currency.format(g.allocatedAmount)})'
                        : 'Restriction (${g.categoryName}) • Max: ${currency.format(g.targetAmount)} / month';
                    return Card(
                      child: ListTile(
                        leading: Icon(
                          isSaving ? Icons.savings : Icons.speed,
                          color: isSaving ? Colors.orange.shade700 : Colors.blue.shade700,
                        ),
                        title: Text(g.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(g.notes.isEmpty ? subtitle : '$subtitle\n${g.notes}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            await widget.repository.deleteGoal(g.id);
                            await _load();
                          },
                        ),
                      ),
                    );
                  }),
              ],
            ),
    );
  }
}
