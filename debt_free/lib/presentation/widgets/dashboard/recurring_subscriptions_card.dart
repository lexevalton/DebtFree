import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../domain/usecases/detect_recurring_subscriptions.dart';

class RecurringSubscriptionsCard extends StatelessWidget {
  final RecurringSummary summary;
  final List<String> allCategories;
  final Set<String> trackedCategories;
  final Future<void> Function(String category, bool isTracked) onToggleCategory;

  const RecurringSubscriptionsCard({
    super.key,
    required this.summary,
    required this.allCategories,
    required this.trackedCategories,
    required this.onToggleCategory,
  });

  void _openCategoryPicker(BuildContext context) {
    final localSelected = Set<String>.from(trackedCategories);

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Track Essential Categories'),
              content: SizedBox(
                width: 340,
                height: 360,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select variable bills (e.g. Gas, Utilities, Taxes) to calculate their monthly average alongside your subscriptions:',
                      style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        itemCount: allCategories.length,
                        itemBuilder: (_, i) {
                          final cat = allCategories[i];
                          final isChecked = localSelected.contains(cat);
                          return CheckboxListTile(
                            dense: true,
                            title: Text(cat),
                            value: isChecked,
                            onChanged: (val) async {
                              final nextValue = val ?? false;
                              setDialogState(() {
                                if (nextValue) {
                                  localSelected.add(cat);
                                } else {
                                  localSelected.remove(cat);
                                }
                              });
                              await onToggleCategory(cat, nextValue);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'en_CA', symbol: '\$');
    final items = summary.items;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Tooltip(
                    message:
                        'Combines your pinned essential categories (monthly average)\n'
                        'and auto-detected recurring subscriptions so you know your fixed baseline.',
                    waitDuration: const Duration(milliseconds: 200),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Flexible(
                          child: Text(
                            'Recurring & Essential Bills',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.help_outline, size: 15, color: Colors.grey.shade600),
                      ],
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _openCategoryPicker(context),
                  icon: const Icon(Icons.tune, size: 16),
                  label: const Text('Track'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ],
            ),
            if (items.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                'Total baseline: ${currency.format(summary.totalMonthly)}/mo • '
                '${currency.format(summary.totalYearly)}/yr',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Expanded(
              child: items.isEmpty
                  ? const Center(
                      child: Text(
                        'No recurring bills yet.\nClick "Track" above to pin categories like Gas or Utilities.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, i) {
                        final item = items[i];
                        final accent = item.isTrackedCategory
                            ? Colors.blue.shade700
                            : Colors.orange.shade700;

                        return Tooltip(
                          message:
                              '${item.title}\n'
                              'Monthly avg: ${currency.format(item.monthlyAmount)} • '
                              'Yearly projection: ${currency.format(item.yearlyAmount)}\n'
                              '${item.subtitle}',
                          waitDuration: const Duration(milliseconds: 250),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: accent.withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        '${item.subtitle} • ${currency.format(item.yearlyAmount)}/yr',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          color: Colors.grey.shade600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${currency.format(item.monthlyAmount)}/mo',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14.5,
                                    color: accent,
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
