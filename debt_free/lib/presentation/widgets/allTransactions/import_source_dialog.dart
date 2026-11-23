import 'package:flutter/material.dart';

enum ImportMethod { webSync, csvFile }

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
}) async {
  final method = await showDialog<ImportMethod>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Sync or Import Transactions'),
      content: const Text(
        'Connect directly to RBC Online Banking to capture latest transactions, '
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

  // WebView sync always appends safely with SHA-256 deduplication
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
        TextButton(
          onPressed: () => Navigator.pop(ctx, null),
          child: const Text('Cancel'),
        ),
        OutlinedButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Replace all'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Append'),
        ),
      ],
    ),
  );

  if (replaceExisting == null) return null;
  return ImportSelection(method: method, replaceExisting: replaceExisting);
}
