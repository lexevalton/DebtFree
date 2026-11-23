import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../domain/usecases/compare_monthly_spending.dart';

class MonthComparisonCard extends StatelessWidget {
  final MonthComparisonResult comparison;

  const MonthComparisonCard({super.key, required this.comparison});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'en_CA', symbol: '\$');
    final hasPrev = comparison.hasPreviousMonthData;
    final isGood = comparison.isSpendingLess;
    final statusColor = !hasPrev
        ? Colors.grey.shade700
        : (isGood ? Colors.green.shade700 : Colors.red.shade700);
    final diffSign = comparison.difference > 0 ? '+' : '-';
    final pctSign = comparison.percentChange > 0 ? '+' : '';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Tooltip(
                  message:
                      'Compares your spending from Day 1 to Day ${comparison.comparisonDay} of this month\n'
                      'against the exact same days last month.\n'
                      '• Green (-): You are spending slower than last month\n'
                      '• Red (+): You are spending faster than last month',
                  waitDuration: const Duration(milliseconds: 200),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Month-over-Month Pace',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.help_outline, size: 15, color: Colors.grey.shade600),
                    ],
                  ),
                ),
                if (hasPrev)
                  Text(
                    '$diffSign${currency.format(comparison.difference.abs())} '
                    '($pctSign${comparison.percentChange.toStringAsFixed(0)}%)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (!hasPrev)
              const Expanded(
                child: Center(
                  child: Text(
                    'No expenses recorded last month yet to compare pace.\nImport last month\'s statement to unlock this comparison.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else ...[
              _buildProgressBars(currency, statusColor),
              const SizedBox(height: 12),
              Expanded(
                child: comparison.topCategoryChanges.isEmpty
                    ? const Center(
                        child: Text(
                          'Spending matches last month across categories.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: comparison.topCategoryChanges.length,
                        itemBuilder: (context, i) {
                          final item = comparison.topCategoryChanges[i];
                          final isIncrease = item.difference > 0;
                          final deltaColor = isIncrease
                              ? Colors.red.shade700
                              : Colors.green.shade700;
                          final prefix = isIncrease ? '+' : '-';

                          return Tooltip(
                            message:
                                '${item.category} (Day 1–${comparison.comparisonDay})\n'
                                'This month: ${currency.format(item.currentAmount)}\n'
                                'Last month: ${currency.format(item.previousAmount)}',
                            waitDuration: const Duration(milliseconds: 250),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: deltaColor.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: deltaColor.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.category,
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '$prefix${currency.format(item.difference.abs())}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: deltaColor,
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
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBars(NumberFormat currency, Color statusColor) {
    final maxVal = [
      comparison.currentToDate,
      comparison.previousToDate,
      1.0,
    ].reduce((a, b) => a > b ? a : b);

    return Column(
      children: [
        _barRow(
          label: 'This Month (Day 1–${comparison.comparisonDay})',
          formattedAmount: currency.format(comparison.currentToDate),
          ratio: comparison.currentToDate / maxVal,
          color: statusColor,
        ),
        const SizedBox(height: 6),
        _barRow(
          label: 'Last Month (Day 1–${comparison.comparisonDay})',
          formattedAmount: currency.format(comparison.previousToDate),
          ratio: comparison.previousToDate / maxVal,
          color: Colors.grey.shade600,
        ),
      ],
    );
  }

  Widget _barRow({
    required String label,
    required String formattedAmount,
    required double ratio,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12)),
            Text(
              formattedAmount,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio.clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: Colors.grey.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
