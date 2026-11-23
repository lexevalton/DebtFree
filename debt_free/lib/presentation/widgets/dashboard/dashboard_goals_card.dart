import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/goal.dart';
import '../../../domain/entities/transaction.dart';

class DashboardGoalsCard extends StatelessWidget {
  final List<Goal> goals;
  final List<Transaction> allTransactions;

  const DashboardGoalsCard({
    super.key,
    required this.goals,
    required this.allTransactions,
  });

  double _computeCurrentAmount(Goal goal) {
    if (goal.type == GoalType.saving) {
      final linkedTransfers = allTransactions
          .where((tx) => tx.isTransfer && tx.goalId == goal.id)
          .fold(0.0, (s, tx) => s + tx.absoluteAmount);
      return goal.allocatedAmount + linkedTransfers;
    } else {
      final now = DateTime.now();
      return allTransactions
          .where((tx) =>
              tx.isExpense &&
              tx.category == goal.categoryName &&
              tx.date.year == now.year &&
              tx.date.month == now.month)
          .fold(0.0, (s, tx) => s + tx.absoluteAmount);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'en_CA', symbol: '\$');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Tooltip(
              message:
                  'Tracks your Saving goals (allocated surplus + linked transfers)\n'
                  'and monthly category Restrictions (green when under limit, red when exceeded).',
              waitDuration: const Duration(milliseconds: 200),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Goals & Monthly Limits',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.help_outline, size: 15, color: Colors.grey.shade600),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: goals.isEmpty
                  ? const Center(
                      child: Text(
                        'No goals set yet. Go to "Goals" to create one.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: goals.length,
                      itemBuilder: (context, i) {
                        final goal = goals[i];
                        final current = _computeCurrentAmount(goal);
                        final isSaving = goal.type == GoalType.saving;

                        final Color statusColor;
                        if (isSaving) {
                          statusColor = current >= goal.targetAmount
                              ? Colors.green.shade700
                              : Colors.orange.shade700;
                        } else {
                          statusColor = current <= goal.targetAmount
                              ? Colors.green.shade700
                              : Colors.red.shade700;
                        }

                        final typeLabel = isSaving ? 'Saving' : 'Restriction';
                        final hoverMessage = goal.notes.isEmpty
                            ? '${goal.name} ($typeLabel) - ${currency.format(goal.targetAmount)}'
                            : '${goal.name} ($typeLabel) - ${currency.format(goal.targetAmount)}\n\n${goal.notes}';

                        return Tooltip(
                          message: hoverMessage,
                          waitDuration: const Duration(milliseconds: 250),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    goal.name,
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  currency.format(current),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: statusColor,
                                  ),
                                ),
                              ],
                            ),
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
