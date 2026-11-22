import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide Transaction;
import '../../core/database/app_database.dart';
import '../../core/sync/cloud_sync_provider.dart';
import '../../domain/entities/account_type.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/transaction_type.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../sources/transaction_source.dart';
import 'sqlite_category_mixin.dart';
import 'sqlite_goals_mixin.dart';

class SqliteTransactionRepository
    with SqliteCategoryMixin, SqliteGoalMixin
    implements TransactionRepository {
  final TransactionSource _source;

  @override
  final CloudSyncProvider syncProvider;

  SqliteTransactionRepository({
    required TransactionSource source,
    required CloudSyncProvider syncProvider,
  })  : _source = source,
        syncProvider = syncProvider;

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
      await syncProvider.pushDatabase(await AppDatabase.getDatabaseFile());
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
    await syncProvider.pushDatabase(await AppDatabase.getDatabaseFile());
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
      'goal_id': tx.goalId,
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
      goalId: map['goal_id'] as String?,
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
}
