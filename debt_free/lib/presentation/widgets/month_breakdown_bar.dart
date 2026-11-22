import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MonthBreakdownBar extends StatelessWidget {
  final bool isVisible;
  final double debitExpenses;
  final double creditExpenses;
  final double totalTransfers;
  final NumberFormat currency;

  const MonthBreakdownBar({
    super.key,
    required this.isVisible,
    required this.debitExpenses,
    required this.creditExpenses,
    required this.totalTransfers,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedCrossFade(
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
            _buildStat(
              Icons.account_balance,
              'Debit: -${currency.format(debitExpenses)}',
              Colors.orange.shade800,
              Colors.orange.shade900,
            ),
            _buildStat(
              Icons.credit_card,
              'Credit: -${currency.format(creditExpenses)}',
              Colors.purple.shade700,
              Colors.purple.shade800,
            ),
            _buildStat(
              Icons.swap_horiz,
              'Transfers: ${currency.format(totalTransfers)}',
              Colors.blue.shade700,
              Colors.blue.shade800,
            ),
          ],
        ),
      ),
      crossFadeState:
          isVisible ? CrossFadeState.showSecond : CrossFadeState.showFirst,
      duration: const Duration(milliseconds: 200),
    );
  }

  Widget _buildStat(IconData icon, String label, Color iconColor, Color textColor) {
    return Row(
      children: [
        Icon(icon, size: 15, color: iconColor),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ],
    );
  }
}
