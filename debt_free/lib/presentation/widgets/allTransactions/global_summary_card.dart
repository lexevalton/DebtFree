import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class GlobalSummaryCard extends StatefulWidget {
  final double totalExpenses;
  final double totalIncomes;
  final double totalTransfers;
  final double totalDebitExpenses;
  final double totalCreditExpenses;
  final int transactionCount;
  final bool isTransfersOnly;
  final VoidCallback? onToggleTransfersOnly;

  const GlobalSummaryCard({
    super.key,
    required this.totalExpenses,
    required this.totalIncomes,
    required this.totalTransfers,
    required this.totalDebitExpenses,
    required this.totalCreditExpenses,
    required this.transactionCount,
    this.isTransfersOnly = false,
    this.onToggleTransfersOnly,
  });

  @override
  State<GlobalSummaryCard> createState() => _GlobalSummaryCardState();
}

class _GlobalSummaryCardState extends State<GlobalSummaryCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'en_CA', symbol: '\$');
    final netBalance = widget.totalIncomes - widget.totalExpenses;

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      const Text('Total Expenses'),
                      const SizedBox(height: 2),
                      Text(
                        '-${currency.format(widget.totalExpenses)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      const Text('Total Income'),
                      const SizedBox(height: 2),
                      Text(
                        '+${currency.format(widget.totalIncomes)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () => setState(() => _isExpanded = !_isExpanded),
                  icon: Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                  ),
                  label: Text(
                    _isExpanded ? 'Show less' : 'Show more',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            if (_isExpanded) ...[
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSubStat(
                    label: 'Debit Expenses',
                    value: '-${currency.format(widget.totalDebitExpenses)}',
                    color: Colors.orange.shade800,
                  ),
                  _buildSubStat(
                    label: 'Credit Expenses',
                    value: '-${currency.format(widget.totalCreditExpenses)}',
                    color: Colors.purple.shade700,
                  ),
                  InkWell(
                    onTap: widget.onToggleTransfersOnly,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: widget.isTransfersOnly
                            ? Colors.blue.shade100
                            : Colors.blue.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: widget.isTransfersOnly
                              ? Colors.blue.shade700
                              : Colors.blue.shade200,
                        ),
                      ),
                      child: _buildSubStat(
                        label: 'Transfers',
                        value: currency.format(widget.totalTransfers),
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                  _buildSubStat(
                    label: 'Net Cashflow',
                    value:
                        '${netBalance >= 0 ? '+' : '-'}${currency.format(netBalance.abs())}',
                    color: netBalance >= 0
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                  ),
                  _buildSubStat(
                    label: 'Transactions',
                    value: '${widget.transactionCount}',
                    color: Colors.black87,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSubStat({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
