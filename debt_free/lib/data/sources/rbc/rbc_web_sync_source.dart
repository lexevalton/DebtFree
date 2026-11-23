import 'package:flutter/material.dart';
import '../../../domain/entities/transaction.dart';
import '../../../presentation/pages/rbc_webview_page.dart';
import '../transaction_source.dart';
import 'rbc_csv_parser.dart';

class RbcWebSyncSource implements TransactionSource {
  final GlobalKey<NavigatorState> navigatorKey;
  final RbcCsvParser _parser;

  RbcWebSyncSource({
    required this.navigatorKey,
    RbcCsvParser? parser,
  }) : _parser = parser ?? RbcCsvParser();

  @override
  String get sourceName => 'RBC Online Banking Sync';

  @override
  Future<List<Transaction>> fetchTransactions() async {
    final nav = navigatorKey.currentState;
    if (nav == null) return [];

    final csvContents = await nav.push<List<String>>(
      MaterialPageRoute(builder: (_) => const RbcWebViewPage()),
    );

    if (csvContents == null || csvContents.isEmpty) return [];
    return _parser.parseMultipleContents(csvContents);
  }
}
