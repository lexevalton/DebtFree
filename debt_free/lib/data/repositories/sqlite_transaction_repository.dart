import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide Transaction;
import '../../core/database/app_database.dart';
import '../../core/sync/cloud_sync_provider.dart';
import '../../domain/entities/account_type.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/transaction_type.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../sources/transaction_source.dart';

class SqliteTransactionRepository implements TransactionRepository {
  final TransactionSource _source;
  final CloudSyncProvider _syncProvider;

  SqliteTransactionRepository({
    required TransactionSource source,
    required CloudSyncProvider syncProvider,
  })  : _source = source,
        _syncProvider = syncProvider;

  @override
  Future<int> syncFromSource({bool replaceExisting = false}) async {
    final incoming = await _source.fetchTransactions();
    if (incoming.isEmpty) return 0;

    final db = await AppDatabase.instance;
    int insertedCount = 0;

    final rules = await getCategoryRules();

    await db.transaction((txn) async {
      if (replaceExisting) {
        await txn.delete('transactions');
      }

      for (final item in incoming) {
        final matchedCategory = _findMatchingCategory(item.merchant, rules);
        final txToSave = matchedCategory != null
            ? item.copyWith(category: matchedCategory)
            : item;

        final result = await txn.insert(
          'transactions',
          _toDbMap(txToSave),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
        if (result != 0) insertedCount++;
      }
    });

    if (insertedCount > 0 || replaceExisting) {
      final dbFile = await AppDatabase.getDatabaseFile();
      await _syncProvider.pushDatabase(dbFile);
    }

    return insertedCount;
  }

  @override
  Future<void> updateTransactionType(String id, TransactionType newType) async {
    final db = await AppDatabase.instance;
    await db.update(
      'transactions',
      {'type': newType.name},
      where: 'id = ?',
      whereArgs: [id],
    );

    final dbFile = await AppDatabase.getDatabaseFile();
    await _syncProvider.pushDatabase(dbFile);
  }

  @override
  Future<List<Transaction>> getLastTwelveMonthsTransactions() async {
    final db = await AppDatabase.instance;
    final now = DateTime.now();
    final startOfMonthLastYear = DateTime(now.year - 1, now.month, 1);
    final cutoffDate = startOfMonthLastYear.toIso8601String().split('T').first;

    final rows = await db.query(
      'transactions',
      where: 'date >= ?',
      whereArgs: [cutoffDate],
      orderBy: 'date DESC',
    );

    return rows.map(_fromDbMap).toList();
  }

  Map<String, dynamic> _toDbMap(Transaction tx) {
    return {
      'id': tx.id,
      'account': tx.account.name,
      'date': tx.date.toIso8601String().split('T').first,
      'amount': tx.amount,
      'merchant': tx.merchant,
      'type': tx.type.name,
      'category': tx.category,
    };
  }

  Transaction _fromDbMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as String,
      account: AccountType.fromStorageKey(map['account'] as String),
      date: DateTime.parse(map['date'] as String),
      amount: (map['amount'] as num).toDouble(),
      merchant: map['merchant'] as String,
      type: TransactionType.fromStorageKey(map['type'] as String? ?? 'expense'),
      category: map['category'] as String,
    );
  }

    String? _findMatchingCategory(String merchant, Map<String, String> rules) {
    final upperMerchant = merchant.toUpperCase();
    for (final entry in rules.entries) {
      if (upperMerchant.contains(entry.key.toUpperCase())) {
        return entry.value;
      }
    }
    return null;
  }

  @override
  Future<List<String>> getCategories() async {
    final db = await AppDatabase.instance;
    final rows = await db.query('categories', orderBy: 'name ASC');
    return rows.map((r) => r['name'] as String).toList();
  }

  @override
  Future<void> addCategory(String name, {int? color}) async {
    final db = await AppDatabase.instance;
    await db.insert(
      'categories',
      {
        'name': name,
        'color': color ?? 0xFF78909C,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    await _syncProvider.pushDatabase(await AppDatabase.getDatabaseFile());
  }

  @override
  Future<Map<String, int>> getCategoryColors() async {
    final db = await AppDatabase.instance;
    final rows = await db.query('categories');
    return {
      for (final row in rows)
        row['name'] as String: (row['color'] as int?) ?? 0xFF78909C,
    };
  }

  @override
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
    await _syncProvider.pushDatabase(await AppDatabase.getDatabaseFile());
  }

  @override
  Future<Map<String, String>> getCategoryRules() async {
    final db = await AppDatabase.instance;
    final rows = await db.query('category_rules', orderBy: 'merchant_pattern ASC');
    return {
      for (final r in rows) r['merchant_pattern'] as String: r['category_name'] as String
    };
  }

  @override
  Future<void> deleteCategoryRule(String merchantPattern) async {
    final db = await AppDatabase.instance;
    await db.delete('category_rules', where: 'merchant_pattern = ?', whereArgs: [merchantPattern]);
    await _syncProvider.pushDatabase(await AppDatabase.getDatabaseFile());
  }

  @override
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

  @override
  Future<void> bulkAssignCategory({
    required List<Transaction> transactions,
    required String category,
    bool rememberRules = true,
  }) async {
    if (transactions.isEmpty) return;
    final db = await AppDatabase.instance;

    await db.transaction((txn) async {
      for (final tx in transactions) {
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

    await _syncProvider.pushDatabase(await AppDatabase.getDatabaseFile());
  }

    @override
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

    await _syncProvider.pushDatabase(await AppDatabase.getDatabaseFile());
  }


}
