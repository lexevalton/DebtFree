import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide Transaction;
import '../../core/database/app_database.dart';
import '../../core/sync/cloud_sync_provider.dart';
import '../../domain/entities/account_type.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/transaction_type.dart';

mixin SqliteCategoryMixin {
  CloudSyncProvider get syncProvider;

  Future<List<String>> getCategories() async {
    final db = await AppDatabase.instance;
    final rows = await db.query('categories', orderBy: 'name ASC');
    return rows.map((r) => r['name'] as String).toList();
  }

  Future<void> addCategory(String name, {int? color}) async {
    final db = await AppDatabase.instance;
    await db.insert(
      'categories',
      {'name': name, 'color': color ?? 0xFF78909C},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    await syncProvider.pushDatabase(await AppDatabase.getDatabaseFile());
  }

  Future<Map<String, int>> getCategoryColors() async {
    final db = await AppDatabase.instance;
    final rows = await db.query('categories');
    return {
      for (final row in rows)
        row['name'] as String: (row['color'] as int?) ?? 0xFF78909C,
    };
  }

  Future<void> deleteCategory(String name) async {
    if (name == 'Uncategorized') return;
    final db = await AppDatabase.instance;
    await db.transaction((txn) async {
      await txn.delete('categories', where: 'name = ?', whereArgs: [name]);
      await txn.delete('category_rules', where: 'category_name = ?', whereArgs: [name]);
      await txn.update(
        'transactions',
        {'category': 'Uncategorized'},
        where: 'category = ?',
        whereArgs: [name],
      );
    });
    await syncProvider.pushDatabase(await AppDatabase.getDatabaseFile());
  }

  Future<Map<String, String>> getCategoryRules() async {
    final db = await AppDatabase.instance;
    final rows = await db.query('category_rules', orderBy: 'merchant_pattern ASC');
    return {
      for (final r in rows) r['merchant_pattern'] as String: r['category_name'] as String
    };
  }

  Future<void> deleteCategoryRule(String merchantPattern) async {
    final db = await AppDatabase.instance;
    await db.delete('category_rules', where: 'merchant_pattern = ?', whereArgs: [merchantPattern]);
    await syncProvider.pushDatabase(await AppDatabase.getDatabaseFile());
  }

  Future<void> assignCategoryToMerchant({
    required String transactionId,
    required String merchant,
    required String category,
    bool rememberForFuture = true,
  }) async {
    await bulkAssignCategory(
      transactions: [
        Transaction(
          id: transactionId,
          account: AccountType.unknown,
          date: DateTime.now(),
          amount: 0,
          merchant: merchant,
          type: TransactionType.expense,
        ),
      ],
      category: category,
      rememberRules: rememberForFuture,
    );
  }

  Future<void> bulkAssignCategory({
    required List<Transaction> transactions,
    required String category,
    bool rememberRules = true,
  }) async {
    final updates = {for (final tx in transactions) tx: category};
    await saveBulkCategoryMap(updates: updates, rememberRules: rememberRules);
  }

  Future<void> saveBulkCategoryMap({
    required Map<Transaction, String> updates,
    bool rememberRules = true,
  }) async {
    if (updates.isEmpty) return;
    final db = await AppDatabase.instance;

    await db.transaction((txn) async {
      for (final entry in updates.entries) {
        final tx = entry.key;
        final category = entry.value;

        await txn.update(
          'transactions',
          {'category': category},
          where: 'id = ?',
          whereArgs: [tx.id],
        );

        if (rememberRules && tx.merchant.trim().isNotEmpty) {
          final pattern = tx.merchant.trim();
          await txn.insert(
            'category_rules',
            {'merchant_pattern': pattern, 'category_name': category},
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          await txn.update(
            'transactions',
            {'category': category},
            where: 'UPPER(merchant) LIKE ?',
            whereArgs: ['%${pattern.toUpperCase()}%'],
          );
        }
      }
    });

    await syncProvider.pushDatabase(await AppDatabase.getDatabaseFile());
  }
}
