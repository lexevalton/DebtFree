import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/account_type.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/transaction_type.dart';

class TransactionRowCard extends StatefulWidget {
  final Transaction tx;
  final NumberFormat currency;
  final List<String> categories;
  final bool isSelectionMode;
  final String? pendingCategory;
  final VoidCallback onTap;
  final void Function(String txId, String newCategory) onStageCategoryEdit;

  const TransactionRowCard({
    super.key,
    required this.tx,
    required this.currency,
    required this.categories,
    required this.isSelectionMode,
    required this.pendingCategory,
    required this.onTap,
    required this.onStageCategoryEdit,
  });

  @override
  State<TransactionRowCard> createState() => _TransactionRowCardState();
}

class _TransactionRowCardState extends State<TransactionRowCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final tx = widget.tx;
    final dayStr = DateFormat('dd MMM').format(tx.date);
    final isDebit = tx.account == AccountType.rbcChequing;
    final currentCategory = widget.pendingCategory ?? tx.category;
    final isModified = widget.pendingCategory != null;

    final Color baseColor;
    final Color hoverColor;
    final Color amountColor;
    final String prefix;

    switch (tx.type) {
      case TransactionType.expense:
        baseColor = Colors.red.withValues(alpha: 0.04);
        hoverColor = Colors.red.withValues(alpha: 0.11);
        amountColor = Colors.red.shade800;
        prefix = '-';
        break;
      case TransactionType.income:
        baseColor = Colors.green.withValues(alpha: 0.04);
        hoverColor = Colors.green.withValues(alpha: 0.11);
        amountColor = Colors.green.shade800;
        prefix = '+';
        break;
      case TransactionType.transfer:
        baseColor = Colors.blue.withValues(alpha: 0.06);
        hoverColor = Colors.blue.withValues(alpha: 0.13);
        amountColor = Colors.blue.shade800;
        prefix = '⇄ ';
        break;
    }

    final effectiveBgColor = isModified
        ? Colors.amber.withValues(alpha: _isHovered ? 0.25 : 0.15)
        : (_isHovered && !widget.isSelectionMode ? hoverColor : baseColor);

    return MouseRegion(
      cursor: widget.isSelectionMode
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.isSelectionMode ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            color: effectiveBgColor,
            borderRadius: BorderRadius.circular(6),
            border: isModified
                ? Border.all(color: Colors.amber.shade700, width: 1)
                : Border.all(
                    color: _isHovered && !widget.isSelectionMode
                        ? amountColor.withValues(alpha: 0.35)
                        : Colors.transparent,
                    width: 1,
                  ),
          ),
          child: Row(
            children: [
              // DEBIT / CREDIT badge
              Container(
                width: 58,
                padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: isDebit ? Colors.orange.shade100 : Colors.purple.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isDebit ? 'DEBIT' : 'CREDIT',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isDebit ? Colors.orange.shade900 : Colors.purple.shade900,
                  ),
                ),
              ),

              // Merchant + Date + Category
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Tooltip(
                      message: tx.merchant,
                      waitDuration: const Duration(milliseconds: 400),
                      child: Text(
                        tx.merchant,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                    Text(
                      '$dayStr • $currentCategory',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Bulk Edit dropdown vs Amount
              if (widget.isSelectionMode)
                SizedBox(
                  width: 155,
                  child: DropdownButton<String>(
                    value: widget.categories.contains(currentCategory)
                        ? currentCategory
                        : 'Uncategorized',
                    isExpanded: true,
                    isDense: true,
                    underline: const SizedBox.shrink(),
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                    items: widget.categories
                        .map((c) => DropdownMenuItem(
                              value: c,
                              child: Text(c, overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        widget.onStageCategoryEdit(tx.id, val);
                      }
                    },
                  ),
                )
              else
                Text(
                  '$prefix${widget.currency.format(tx.absoluteAmount)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: amountColor,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
