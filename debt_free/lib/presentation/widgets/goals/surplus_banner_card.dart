import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/goal.dart';

class SurplusBannerCard extends StatelessWidget {
  final double availableSurplus;
  final List<Goal> savingGoals;
  final Future<void> Function(String goalId, double amount) onAllocate;

  const SurplusBannerCard({
    super.key,
    required this.availableSurplus,
    required this.savingGoals,
    required this.onAllocate,
  });

  Future<void> _showAllocateDialog(BuildContext context) async {
    if (savingGoals.isEmpty || availableSurplus <= 0) return;
    String selectedGoalId = savingGoals.first.id;
    final amountCtrl = TextEditingController(
      text: availableSurplus.toStringAsFixed(2),
    );

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Allocate Unspent Money'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                value: selectedGoalId,
                decoration: const InputDecoration(labelText: 'Saving Goal'),
                items: savingGoals
                    .map((g) => DropdownMenuItem(value: g.id, child: Text(g.name)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setDialogState(() => selectedGoalId = val);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Amount (Max \$${availableSurplus.toStringAsFixed(2)})',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final val = double.tryParse(amountCtrl.text.trim().replaceAll(',', '.'));
                if (val == null || val <= 0 || val > availableSurplus + 0.001) return;
                Navigator.pop(ctx);
                await onAllocate(selectedGoalId, val);
              },
              child: const Text('Allocate'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'en_CA', symbol: '\$');
    final hasSurplus = availableSurplus > 0.009;

    return Card(
      color: hasSurplus ? Colors.green.shade50 : Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              hasSurplus ? Icons.account_balance_wallet : Icons.info_outline,
              color: hasSurplus ? Colors.green.shade700 : Colors.grey.shade600,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                hasSurplus
                    ? 'You have +${currency.format(availableSurplus)}, what do you want to do with it?'
                    : 'No unallocated surplus available right now (\$0.00).',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: hasSurplus ? Colors.green.shade900 : Colors.grey.shade800,
                ),
              ),
            ),
            if (hasSurplus)
              FilledButton.icon(
                onPressed: savingGoals.isEmpty ? null : () => _showAllocateDialog(context),
                icon: const Icon(Icons.savings),
                label: Text(savingGoals.isEmpty ? 'Create a Saving Goal First' : 'Allocate'),
              ),
          ],
        ),
      ),
    );
  }
}
