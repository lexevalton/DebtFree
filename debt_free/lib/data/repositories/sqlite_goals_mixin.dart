import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide Transaction;
import '../../core/database/app_database.dart';
import '../../core/sync/cloud_sync_provider.dart';
import '../../domain/entities/goal.dart';

mixin SqliteGoalMixin {
  CloudSyncProvider get syncProvider;

  Future<List<Goal>> getGoals() async {
    final db = await AppDatabase.instance;
    final rows = await db.query('goals', orderBy: 'name ASC');
    return rows.map((r) {
      return Goal(
        id: r['id'] as String,
        name: r['name'] as String,
        type: GoalType.fromStorageKey(r['type'] as String),
        targetAmount: (r['target_amount'] as num).toDouble(),
        allocatedAmount: (r['allocated_amount'] as num?)?.toDouble() ?? 0.0,
        categoryName: r['category_name'] as String?,
        notes: (r['notes'] as String?) ?? '',
      );
    }).toList();
  }

  Future<void> addGoal(Goal goal) async {
    final db = await AppDatabase.instance;
    await db.insert(
      'goals',
      {
        'id': goal.id,
        'name': goal.name,
        'type': goal.type.name,
        'target_amount': goal.targetAmount,
        'allocated_amount': goal.allocatedAmount,
        'category_name': goal.categoryName,
        'notes': goal.notes,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await syncProvider.pushDatabase(await AppDatabase.getDatabaseFile());
  }

  Future<void> allocateToGoal(String goalId, double amountToAdd) async {
    final db = await AppDatabase.instance;
    await db.rawUpdate(
      'UPDATE goals SET allocated_amount = allocated_amount + ? WHERE id = ?',
      [amountToAdd, goalId],
    );
    await syncProvider.pushDatabase(await AppDatabase.getDatabaseFile());
  }

  Future<void> deleteGoal(String goalId) async {
    final db = await AppDatabase.instance;
    await db.transaction((txn) async {
      await txn.delete('goals', where: 'id = ?', whereArgs: [goalId]);
      await txn.update(
        'transactions',
        {'goal_id': null},
        where: 'goal_id = ?',
        whereArgs: [goalId],
      );
    });
    await syncProvider.pushDatabase(await AppDatabase.getDatabaseFile());
  }

  Future<void> assignGoalToTransaction(String transactionId, String? goalId) async {
    final db = await AppDatabase.instance;
    await db.update(
      'transactions',
      {'goal_id': goalId},
      where: 'id = ?',
      whereArgs: [transactionId],
    );
    await syncProvider.pushDatabase(await AppDatabase.getDatabaseFile());
  }
}
