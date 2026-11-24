import 'package:flutter/material.dart';
import '../../../domain/entities/bank_account_profile.dart';
import '../../../domain/entities/transaction.dart';
import '../../../presentation/pages/rbc_webview_page.dart';
import '../transaction_source.dart';
import 'rbc_csv_parser.dart';

class RbcWebSyncSource implements TransactionSource {
  final GlobalKey<NavigatorState> navigatorKey;
  final RbcCsvParser _parser;
  Future<List<BankAccountProfile>> Function() profilesLoader;
  Future<void> Function(List<String> ids)? onProfilesSynced;

  RbcWebSyncSource({
    required this.navigatorKey,
    required Future<List<BankAccountProfile>> Function() getActiveProfiles,
    this.onProfilesSynced,
    RbcCsvParser? parser,
  })  : profilesLoader = getActiveProfiles,
        _parser = parser ?? RbcCsvParser();

  @override
  String get sourceName => 'RBC Online Banking Sync';

  @override
  Future<List<Transaction>> fetchTransactions() async {
    final nav = navigatorKey.currentState;
    if (nav == null) return [];

    final allProfiles = await profilesLoader();
    final activeRbc = allProfiles
        .where((p) => p.isActive && p.institution.toUpperCase() == 'RBC')
        .toList();

    final csvContents = await nav.push<List<String>>(
      MaterialPageRoute(
        builder: (_) => RbcWebViewPage(activeProfiles: activeRbc),
      ),
    );

    if (csvContents == null || csvContents.isEmpty) return [];

    if (onProfilesSynced != null && activeRbc.isNotEmpty) {
      await onProfilesSynced!(activeRbc.map((p) => p.id).toList());
    }

    return _parser.parseMultipleContents(csvContents);
  }
}
