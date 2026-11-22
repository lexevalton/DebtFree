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
    return _reconcileCardTransfers(allTransactions);
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
      final accountType = _mapAccountType(rawAccountType);

      results.add(Transaction(
        id: id,
        account: accountType,
        date: parsedDate,
        amount: amount,
        merchant: cleanMerchant,
        type: _classifyTransactionType(cleanMerchant, amount, accountType),
      ));
    }

    return results;
  }

  List<Transaction> _reconcileCardTransfers(List<Transaction> txs) {
    final visaCredits = txs
        .where((t) => t.account == AccountType.rbcVisa && t.amount > 0)
        .toList();

    return txs.map((tx) {
      if (tx.account == AccountType.rbcChequing && tx.amount < 0) {
        final upper = tx.merchant.toUpperCase();
        final isOnlineTransfer = upper.contains('VIREMENT PAR BANQUE EN DIRECT') ||
            upper.contains('VIREMENT BANQUE EN DIRECT') ||
            upper.contains('ONLINE BANKING TRANSFER');

        if (isOnlineTransfer) {
          final hasMatchingVisaCredit = visaCredits.any((visaTx) {
            final sameAmount = (visaTx.amount - tx.absoluteAmount).abs() < 0.01;
            final dayDiff = visaTx.date.difference(tx.date).inDays.abs();
            return sameAmount && dayDiff <= 3;
          });

          if (hasMatchingVisaCredit) {
            return tx.copyWith(type: TransactionType.transfer);
          }
        }
      }
      return tx;
    }).toList();
  }

  TransactionType _classifyTransactionType(
    String merchant,
    double amount,
    AccountType account,
  ) {
    final upper = merchant.toUpperCase();

    const definiteTransferKeywords = [
      'PAIEMENT - MERCI',
      'PAIEMENT RECU',
      'PAYMENT - THANK YOU',
      'PAYMENT THANK YOU',
      'WEALTHSIMPLE',
    ];

    if (definiteTransferKeywords.any((kw) => upper.contains(kw))) {
      return TransactionType.transfer;
    }

    // Visa positive credits from bill payments are transfers (keep merchant refunds as income)
    if (account == AccountType.rbcVisa && amount > 0) {
      if (upper.contains('PAIEMENT') || upper.contains('PAYMENT')) {
        return TransactionType.transfer;
      }
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
