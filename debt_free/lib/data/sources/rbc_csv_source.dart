import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import '../../domain/entities/account_type.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/transaction_type.dart';
import 'transaction_source.dart';

class RbcCsvSource implements TransactionSource {
  @override
  String get sourceName => 'RBC CSV File Import';

  @override
  Future<List<Transaction>> fetchTransactions() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      allowMultiple: true,
    );

    if (result == null || result.files.isEmpty) return [];

    final List<Transaction> allTransactions = [];
    for (final file in result.files) {
      if (file.path == null) continue;
      final rawContent = await File(file.path!).readAsString();
      allTransactions.addAll(_parseCsvContent(rawContent));
    }
    return allTransactions;
  }

  List<Transaction> _parseCsvContent(String csvContent) {
    final normalized = csvContent.replaceAll('\r\n', '\n');
    final rows = const CsvToListConverter(eol: '\n').convert(normalized);
    final List<Transaction> results = [];
    final Map<String, int> dailyOccurrence = {};

    for (int i = 1; i < rows.length; i++) {
      final row = rows.elementAt(i);
      if (row.length < 7) continue;

      final rawAccountType = row.elementAt(0).toString().trim();
      final accountNum = row.elementAt(1).toString().trim();
      final rawDate = row.elementAt(2).toString().trim();
      final desc1 = row.elementAt(4).toString().trim();
      final desc2 = row.elementAt(5).toString().trim();

      final cadStr = row
          .elementAt(6)
          .toString()
          .replaceAll(RegExp(r'[\s\u00A0]'), '')
          .replaceAll(',', '.');
      final usdStr = row.length > 7
          ? row
              .elementAt(7)
              .toString()
              .replaceAll(RegExp(r'[\s\u00A0]'), '')
              .replaceAll(',', '.')
          : '';

      final amount = double.tryParse(cadStr) ?? double.tryParse(usdStr);
      if (amount == null || rawDate.isEmpty) continue;

      final parsedDate = _parseRbcDate(rawDate);
      if (parsedDate == null) continue;

      final merchant = [desc1, desc2]
          .where((s) => s.isNotEmpty)
          .join(' - ');
      final cleanMerchant = merchant.isEmpty ? 'RBC Transaction' : merchant;

      final baseKey = '$accountNum|$rawDate|$amount|$cleanMerchant';
      final occurrenceIndex = (dailyOccurrence[baseKey] ?? 0) + 1;
      dailyOccurrence[baseKey] = occurrenceIndex;

      final id = sha256.convert(utf8.encode('$baseKey#$occurrenceIndex')).toString();

      results.add(Transaction(
        id: id,
        account: _mapAccountType(rawAccountType),
        date: parsedDate,
        amount: amount,
        merchant: cleanMerchant,
        type: _classifyTransactionType(cleanMerchant, amount),
      ));
    }

    return results;
  }

  TransactionType _classifyTransactionType(String merchant, double amount) {
    final upper = merchant.toUpperCase();
    const transferKeywords = [
      'PAIEMENT - MERCI',
      'PAYMENT - THANK YOU',
      'VIREMENT BANQUE EN DIRECT',
      'ONLINE BANKING TRANSFER',
      'PAIEMENT FACTURE - VISA',
      'BILL PAYMENT - VISA',
      'WEALTHSIMPLE',
    ];

    if (transferKeywords.any((kw) => upper.contains(kw))) {
      return TransactionType.transfer;
    }
    return amount < 0 ? TransactionType.expense : TransactionType.income;
  }

  AccountType _mapAccountType(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('chequing') || lower.contains('chèques')) {
      return AccountType.rbcChequing;
    }
    if (lower.contains('visa')) {
      return AccountType.rbcVisa;
    }
    return AccountType.unknown;
  }

  DateTime? _parseRbcDate(String dateStr) {
    final parts = dateStr.split('/');
    if (parts.length != 3) return null;
    final month = int.tryParse(parts.elementAt(0));
    final day = int.tryParse(parts.elementAt(1));
    final year = int.tryParse(parts.elementAt(2));
    if (month == null || day == null || year == null) return null;
    return DateTime(year, month, day);
  }
}
