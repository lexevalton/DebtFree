import 'package:flutter/material.dart';

enum ImportMethod { webSync, csvFile, openAccountsSetup }

class ImportSelection {
  final ImportMethod method;
  final bool replaceExisting;

  const ImportSelection({
    required this.method,
    required this.replaceExisting,
  });
}

Future<ImportSelection?> showImportSourceDialog(
  BuildContext context, {
  required bool hasExistingData,
  required bool hasActiveBankProfiles,
}) async {
  final method = await showDialog<ImportMethod>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Sync or Import Transactions'),
      content: const Text(
        'Connect to RBC Online Banking to capture your configured accounts, '
        'or import a CSV statement manually.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, null),
          child: const Text('Cancel'),
        ),
        OutlinedButton.icon(
          onPressed: () => Navigator.pop(ctx, ImportMethod.csvFile),
          icon: const Icon(Icons.upload_file),
          label: const Text('Import CSV'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.pop(ctx, ImportMethod.webSync),
          icon: const Icon(Icons.account_balance),
          label: const Text('RBC Online Sync'),
        ),
      ],
    ),
  );

  if (method == null || !context.mounted) return null;

  if (method == ImportMethod.webSync && !hasActiveBankProfiles) {
    final goSetup = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('No Active Bank Accounts'),
        content: const Text(
          'Please add and activate at least one RBC account or credit card in "Accounts" first '
          'so DebtFree knows which accounts to open and download.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.account_balance_outlined),
            label: const Text('Go to Accounts'),
          ),
        ],
      ),
    );
    if (goSetup == true) {
      return const ImportSelection(method: ImportMethod.openAccountsSetup, replaceExisting: false);
    }
    return null;
  }

  if (method == ImportMethod.webSync || !hasExistingData) {
    return ImportSelection(method: method, replaceExisting: false);
  }

  final replaceExisting = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('CSV Import Mode'),
      content: const Text(
        'Do you want to append new transactions to existing data or replace everything?',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('Cancel')),
        OutlinedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Replace all')),
        FilledButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Append')),
      ],
    ),
  );

  if (replaceExisting == null) return null;
  return ImportSelection(method: method, replaceExisting: replaceExisting);
}
