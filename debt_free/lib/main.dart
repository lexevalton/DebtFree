import 'package:flutter/material.dart';
import 'core/database/app_database.dart';
import 'core/sync/cloud_sync_provider.dart';
import 'core/sync/oauth_credentials_loader.dart';
import 'data/repositories/sqlite_transaction_repository.dart';
import 'data/sources/rbc/rbc_csv_parser.dart';
import 'data/sources/rbc/rbc_csv_source.dart';
import 'data/sources/rbc/rbc_web_sync_source.dart';
import 'domain/repositories/transaction_repository.dart';
import 'presentation/pages/left_menu_page.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final navigatorKey = GlobalKey<NavigatorState>();
  final rbcParser = RbcCsvParser();
  final syncProvider = await OAuthCredentialsLoader.loadGoogleDriveProvider();

  await _syncFromCloudIfNewer(syncProvider);

  final repository = SqliteTransactionRepository(
    csvSource: RbcCsvSource(parser: rbcParser),
    webSyncSource: RbcWebSyncSource(
      navigatorKey: navigatorKey,
      getActiveProfiles: () => AppDatabase.instance.then((_) async => []),
      parser: rbcParser,
    ),
    syncProvider: syncProvider,
  );

  (repository.webSyncSource as RbcWebSyncSource).profilesLoader = repository.getBankProfiles;
  (repository.webSyncSource as RbcWebSyncSource).onProfilesSynced = repository.markProfilesSynced;

  runApp(
    DebtFreeApp(
      repository: repository,
      syncProvider: syncProvider,
      navigatorKey: navigatorKey,
    ),
  );
}

Future<void> _syncFromCloudIfNewer(CloudSyncProvider provider) async {
  try {
    final remoteModified = await provider.getRemoteLastModified();
    if (remoteModified == null) return; // First-time user or not signed in yet

    final localFile = await AppDatabase.getDatabaseFile();
    if (!await localFile.exists()) {
      await provider.pullDatabase(localFile);
      return;
    }

    final localModified = (await localFile.stat()).modified;
    if (remoteModified.isAfter(localModified.add(const Duration(seconds: 5)))) {
      await provider.pullDatabase(localFile);
    }
  } catch (_) {
    // Offline or not yet connected: continue seamlessly with local SQLite
  }
}

class DebtFreeApp extends StatelessWidget {
  final TransactionRepository repository;
  final CloudSyncProvider syncProvider;
  final GlobalKey<NavigatorState> navigatorKey;

  const DebtFreeApp({
    super.key,
    required this.repository,
    required this.syncProvider,
    required this.navigatorKey,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'DebtFree',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: LeftMenuPage(repository: repository, syncProvider: syncProvider),
    );
  }
}
