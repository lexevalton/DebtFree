import 'presentation/pages/left_menu_page.dart';
import 'package:flutter/material.dart';
import 'core/sync/local_only_sync.dart';
import 'data/repositories/sqlite_transaction_repository.dart';
import 'data/sources/rbc_csv_source.dart';
import 'domain/repositories/transaction_repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final repository = SqliteTransactionRepository(
    source: RbcCsvSource(),
    syncProvider: LocalOnlySync(),
  );

  runApp(DebtFreeApp(repository: repository));
}

class DebtFreeApp extends StatelessWidget {
  final TransactionRepository repository;

  const DebtFreeApp({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DebtFree',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      home: LeftMenuPage(repository: repository),
    );
  }
}
