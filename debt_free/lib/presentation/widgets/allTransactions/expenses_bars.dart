import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class ExpensesAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isSelectionMode;
  final VoidCallback onToggleSelectionMode;
  final VoidCallback onRefresh;

  const ExpensesAppBar({
    super.key,
    required this.isSelectionMode,
    required this.onToggleSelectionMode,
    required this.onRefresh,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('DebtFree — Clear your debts!'),
      actions: [
        OutlinedButton.icon(
          onPressed: onToggleSelectionMode,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white70, width: 1.3),
          ),
          icon: Icon(isSelectionMode ? Icons.close : Icons.checklist, size: 18),
          label: Text(isSelectionMode ? 'Cancel Bulk' : 'Bulk Edit'),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: onRefresh,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.primaryDark,
          ),
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Refresh'),
        ),
        const SizedBox(width: 24),
      ],
    );
  }
}

class ExpensesFilterBar extends StatelessWidget {
  final int uncategorizedCount;
  final bool onlyUncategorized;
  final ValueChanged<bool> onUncategorizedChanged;

  const ExpensesFilterBar({
    super.key,
    required this.uncategorizedCount,
    required this.onlyUncategorized,
    required this.onUncategorizedChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          FilterChip(
            avatar: const Icon(Icons.filter_list, size: 16),
            label: Text('Uncategorized only ($uncategorizedCount)'),
            selected: onlyUncategorized,
            onSelected: onUncategorizedChanged,
          ),
        ],
      ),
    );
  }
}

class BulkEditBottomBar extends StatelessWidget {
  final int modifiedCount;
  final bool rememberRules;
  final ValueChanged<bool> onRememberChanged;
  final VoidCallback onSaveAll;

  const BulkEditBottomBar({
    super.key,
    required this.modifiedCount,
    required this.rememberRules,
    required this.onRememberChanged,
    required this.onSaveAll,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      child: Row(
        children: [
          Text(
            '$modifiedCount modified',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const Spacer(),
          Row(
            children: [
              Checkbox(
                value: rememberRules,
                onChanged: (val) => onRememberChanged(val ?? true),
              ),
              const Text('Remember rules', style: TextStyle(fontSize: 13)),
            ],
          ),
          const SizedBox(width: 16),
          FilledButton.icon(
            onPressed: modifiedCount == 0 ? null : onSaveAll,
            icon: const Icon(Icons.save),
            label: const Text('Save All'),
          ),
        ],
      ),
    );
  }
}
