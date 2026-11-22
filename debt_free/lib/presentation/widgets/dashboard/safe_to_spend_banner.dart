import 'package:flutter/material.dart';
import '../../../domain/usecases/calculate_safe_to_spend.dart';

class SafeToSpendBanner extends StatelessWidget {
  final SafeToSpendResult result;

  const SafeToSpendBanner({super.key, required this.result});

  String _formatMoney(double value) {
    if (value.abs() < 0.005) return '\$0.00';
    final prefix = value < 0 ? '-' : '';
    return '$prefix\$${value.abs().toStringAsFixed(2)}';
  }

  String _buildTooltipMessage() {
    final carryLabel = result.carryOver >= 0 ? 'Prior Leftover' : 'Prior Debt';
    final lines = <String>[
      'How Daily Pace & Safe-to-Spend are calculated:',
      '• This Month Income: ${_formatMoney(result.currentMonthIncome)}',
      '• $carryLabel: ${_formatMoney(result.carryOver)}',
      '• Net Available Funds: ${_formatMoney(result.availableFunds)}',
    ];

    if (result.hasAvailableFunds) {
      lines.addAll([
        '• Daily Pace: ${_formatMoney(result.availableFunds)} ÷ ${result.daysInMonth} days = ${_formatMoney(result.dailyAllowance)}/day',
        '• Allowed to Date (Day ${result.currentDay}): ${_formatMoney(result.allowedToDate)}',
        '• Spent & Saved This Month: -${_formatMoney(result.spentThisMonth)}',
        '• Safe to Spend Today: ${_formatMoney(result.safeToday)}',
      ]);
    } else {
      lines.addAll([
        '• Spent This Month: -${_formatMoney(result.spentThisMonth)}',
        '• Safe to Spend Today: ${_formatMoney(result.safeToday)} (No positive funds available)',
      ]);
    }

    return lines.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final isOnTrack = result.isOnTrack;
    final accentColor = isOnTrack ? Colors.green.shade700 : Colors.red.shade700;
    final bgColor = isOnTrack
        ? Colors.green.withValues(alpha: 0.12)
        : Colors.red.withValues(alpha: 0.14);
    final borderColor = isOnTrack
        ? Colors.green.withValues(alpha: 0.4)
        : Colors.red.withValues(alpha: 0.5);

    final startOfDayBudget = result.safeToday + result.spentToday;

    return Tooltip(
      message: _buildTooltipMessage(),
      padding: const EdgeInsets.all(12),
      textStyle: const TextStyle(color: Colors.white, fontSize: 12.5, height: 1.4),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: 1.2),
        ),
        child: Row(
          children: [
            Icon(
              isOnTrack ? Icons.check_circle_outline : Icons.warning_amber_rounded,
              color: accentColor,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: DefaultTextStyle.of(context).style.copyWith(fontSize: 14),
                  children: _buildMessageSpans(accentColor, startOfDayBudget),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.help_outline, size: 16, color: accentColor.withValues(alpha: 0.8)),
          ],
        ),
      ),
    );
  }

  List<InlineSpan> _buildMessageSpans(Color accentColor, double startOfDayBudget) {
    final boldAccent = TextStyle(fontWeight: FontWeight.bold, color: accentColor);
    const boldDefault = TextStyle(fontWeight: FontWeight.bold);

    if (!result.hasAvailableFunds) {
      if (result.safeToday < -0.005) {
        final debtDetail = result.priorDebt > 0
            ? 'Includes ${_formatMoney(result.priorDebt)} carried-over debt — cut spending and wait for income to recover'
            : 'Cumulative deficit — pause spending until new income arrives';
        return [
          const TextSpan(text: 'Safe to spend today: '),
          TextSpan(text: _formatMoney(result.safeToday), style: boldAccent),
          TextSpan(text: '  •  $debtDetail'),
        ];
      }
      return [
        const TextSpan(text: 'Safe to spend today: '),
        TextSpan(text: '\$0.00', style: boldAccent),
        const TextSpan(text: '  •  No funds available — do not spend until paid'),
      ];
    }

    if (result.isOnTrack) {
      final debtNote = result.priorDebt > 0
          ? ' (${_formatMoney(result.priorDebt)} prior debt deducted)'
          : '';
      if (result.spentToday > 0) {
        return [
          const TextSpan(text: 'Safe to spend today: '),
          TextSpan(text: _formatMoney(result.safeToday), style: boldAccent),
          TextSpan(
            text: '  •  You spent ${_formatMoney(result.spentToday)} today '
                '(started at ${_formatMoney(startOfDayBudget)})$debtNote',
          ),
        ];
      }
      return [
        const TextSpan(text: 'Safe to spend today: '),
        TextSpan(text: _formatMoney(result.safeToday), style: boldAccent),
        TextSpan(
          text: '  •  Daily pace: ${_formatMoney(result.dailyAllowance)}/day$debtNote',
        ),
      ];
    }

    final recoveryText = result.daysToRecover == 1
        ? 'Pause spending today to return to green tomorrow'
        : 'Pause spending for ${result.daysToRecover} days to recover';

    if (result.spentToday > 0 && startOfDayBudget > 0) {
      return [
        TextSpan(text: 'Safe to spend: ${_formatMoney(startOfDayBudget)} — '),
        TextSpan(
          text: 'You spent ${_formatMoney(result.spentToday)} '
              '(${_formatMoney(result.overAmount)} over!)',
          style: boldAccent,
        ),
        TextSpan(text: '  •  $recoveryText', style: boldDefault),
      ];
    }

    return [
      const TextSpan(text: 'Safe to spend today: '),
      TextSpan(text: _formatMoney(result.safeToday), style: boldAccent),
      TextSpan(text: ' (No spending room)  •  $recoveryText'),
    ];
  }
}
