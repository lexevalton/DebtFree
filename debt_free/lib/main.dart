import '../theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'core/sync/local_only_sync.dart';
import 'data/repositories/sqlite_transaction_repository.dart';
import 'data/sources/rbc/rbc_csv_parser.dart';
import 'data/sources/rbc/rbc_csv_source.dart';
import 'data/sources/rbc/rbc_web_sync_source.dart';
import 'domain/repositories/transaction_repository.dart';
import 'presentation/pages/left_menu_page.dart';


void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final navigatorKey = GlobalKey<NavigatorState>();
  final rbcParser = RbcCsvParser();

  final repository = SqliteTransactionRepository(
    csvSource: RbcCsvSource(parser: rbcParser),
    webSyncSource: RbcWebSyncSource(
      navigatorKey: navigatorKey,
      parser: rbcParser,
    ),
    syncProvider: LocalOnlySync(),
  );

  runApp(DebtFreeApp(repository: repository, navigatorKey: navigatorKey));
}

class DebtFreeApp extends StatelessWidget {
  final TransactionRepository repository;
  final GlobalKey<NavigatorState> navigatorKey;

  const DebtFreeApp({
    super.key,
    required this.repository,
    required this.navigatorKey,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'DebtFree',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: LeftMenuPage(repository: repository),
    );
  }
}
