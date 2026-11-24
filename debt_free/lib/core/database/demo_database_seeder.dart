import 'package:sqflite/sqflite.dart';

class DemoDatabaseSeeder {
  static Future<void> seedIfEmpty(Database db, {required bool isHealthy}) async {
    final existing = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM transactions'),
    );
    if ((existing ?? 0) > 0) return;

    final now = DateTime.now();
    await db.transaction((txn) async {
      // Pin essential categories for Recurring & Essential Bills widget
      await txn.update('categories', {'is_tracked': 1}, where: 'name = ?', whereArgs: ['Car, Gas & Auto Ins.']);
      await txn.update('categories', {'is_tracked': 1}, where: 'name = ?', whereArgs: ['Bills & Utilities']);

      // Seed goals
      await txn.insert('goals', {
        'id': 'demo_goal_emergency',
        'name': 'Emergency Fund',
        'type': 'saving',
        'target_amount': 3000.0,
        'allocated_amount': isHealthy ? 1850.0 : 250.0,
        'category_name': null,
        'notes': '3 months of essential living expenses',
      });
      await txn.insert('goals', {
        'id': 'demo_goal_dining',
        'name': 'Dining Out Limit',
        'type': 'restriction',
        'target_amount': 250.0,
        'allocated_amount': 0.0,
        'category_name': 'Dining Out',
        'notes': 'Keep restaurant spending under \$250/month',
      });

      final txs = _buildTransactions(now, isHealthy: isHealthy);
      for (final tx in txs) {
        await txn.insert('transactions', tx, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    });
  }

  static List<Map<String, dynamic>> _buildTransactions(DateTime now, {required bool isHealthy}) {
    final list = <Map<String, dynamic>>[];
    int seq = 1;

    String fmt(DateTime d) => d.toIso8601String().split('T').first;
    void add(DateTime date, String account, double amount, String merchant, String type, String cat, [String? goalId]) {
      list.add({
        'id': 'demo_tx_${seq++}',
        'account': account,
        'date': fmt(date),
        'amount': amount,
        'merchant': merchant,
        'type': type,
        'category': cat,
        'goal_id': goalId,
      });
    }

    for (int offset = 2; offset >= 0; offset--) {
      final m = DateTime(now.year, now.month - offset, 1);
      final maxDay = offset == 0 ? now.day : 28;

      // Bi-weekly paychecks
      add(DateTime(m.year, m.month, 1), 'rbcChequing', 2400.0, 'PAYROLL DEPOSIT', 'income', 'Uncategorized');
      if (maxDay >= 15) {
        add(DateTime(m.year, m.month, 15), 'rbcChequing', 2400.0, 'PAYROLL DEPOSIT', 'income', 'Uncategorized');
      }

      // Fixed housing & recurring subscriptions
      add(DateTime(m.year, m.month, 2), 'rbcChequing', -1350.0, 'MORTGAGE / RENT PAYMENT', 'expense', 'Housing');
      if (maxDay >= 5) {
        add(DateTime(m.year, m.month, 5), 'rbcVisa', -18.99, 'NETFLIX.COM', 'expense', 'Subscriptions');
        add(DateTime(m.year, m.month, 5), 'rbcVisa', -12.99, 'SPOTIFY CANADA', 'expense', 'Subscriptions');
      }
      if (maxDay >= 10) {
        add(DateTime(m.year, m.month, 10), 'rbcChequing', -115.0, 'HYDRO-QUEBEC', 'expense', 'Bills & Utilities');
      }

      // Variable essentials & lifestyle spending
      final groceryAmt = isHealthy ? -145.0 : -260.0;
      final gasAmt = isHealthy ? -65.0 : -110.0;
      final diningAmt = isHealthy ? -45.0 : -165.0;

      if (maxDay >= 4) {
        add(DateTime(m.year, m.month, 4), 'rbcVisa', groceryAmt, 'IGA EXTRA LAVAL', 'expense', 'Groceries');
        add(DateTime(m.year, m.month, 4), 'rbcVisa', gasAmt, 'SHELL STATION', 'expense', 'Car, Gas & Auto Ins.');
      }
      if (maxDay >= 12) {
        add(DateTime(m.year, m.month, 12), 'rbcVisa', groceryAmt, 'COSTCO WHOLESALE', 'expense', 'Groceries');
        add(DateTime(m.year, m.month, 12), 'rbcVisa', diningAmt, 'RESTAURANT LA BELLE PROVINCE', 'expense', 'Dining Out');
      }
      if (!isHealthy && maxDay >= 14) {
        add(DateTime(m.year, m.month, 14), 'rbcVisa', -680.0, 'BEST BUY ELECTRONICS', 'expense', 'Personal & Household');
        add(DateTime(m.year, m.month, 14), 'rbcVisa', -240.0, 'UBER EATS', 'expense', 'Dining Out');
      }
      if (isHealthy && maxDay >= 16) {
        add(DateTime(m.year, m.month, 16), 'rbcChequing', -300.0, 'WEALTHSIMPLE TFSA', 'transfer', 'Uncategorized', 'demo_goal_emergency');
      }
    }

    return list;
  }
}
