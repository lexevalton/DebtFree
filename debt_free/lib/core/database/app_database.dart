import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class AppDatabase {
  static Database? _db;

  static Future<File> getDatabaseFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(join(dir.path, 'debt_free.sqlite'));
  }

  static Future<Database> get instance async {
    if (_db != null) return _db!;

    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbFile = await getDatabaseFile();

    _db = await openDatabase(
      dbFile.path,
      version: 5,
      onConfigure: (db) async {
        await db.execute('PRAGMA journal_mode = DELETE;');
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE transactions (
            id TEXT PRIMARY KEY,
            account TEXT NOT NULL,
            date TEXT NOT NULL,
            amount REAL NOT NULL,
            merchant TEXT NOT NULL,
            type TEXT NOT NULL DEFAULT 'expense',
            category TEXT NOT NULL DEFAULT 'Uncategorized',
            goal_id TEXT
          )
        ''');
        await _createCategoryTables(db);
        await _createGoalsTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            "ALTER TABLE transactions ADD COLUMN type TEXT NOT NULL DEFAULT 'expense';",
          );
          await db.execute(
            "UPDATE transactions SET type = CASE WHEN amount < 0 THEN 'expense' ELSE 'income' END;",
          );
        }
        if (oldVersion < 3) {
          await _createCategoryTables(db);
        }
        if (oldVersion < 4) {
          await _createGoalsTable(db);
          await db.execute('ALTER TABLE transactions ADD COLUMN goal_id TEXT;');
        }
        if (oldVersion < 5) {
          await db.execute(
            'ALTER TABLE categories ADD COLUMN is_tracked INTEGER NOT NULL DEFAULT 0;',
          );
        }
      },
    );
    return _db!;
  }

  static Future<void> _createCategoryTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories (
        name TEXT PRIMARY KEY,
        color INTEGER NOT NULL DEFAULT 4286091420,
        is_tracked INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS category_rules (
        merchant_pattern TEXT PRIMARY KEY,
        category_name TEXT NOT NULL
      )
    ''');

    const defaults = [
      'Uncategorized',
      'Groceries',
      'Dining Out',
      'Personal & Household',
      'Car, Gas & Auto Ins.',
      'Bills & Utilities',
      'Subscriptions',
      'Taxes & Gov',
      'School Fees',
      'Kids Activities',
      'Kids Clothing & Gear',
      'Personal Activities',
      'My Clothing & Jewelry',
      'Housing',
      'Insurance',
      'Health & Pharmacy',
    ];

    for (final cat in defaults) {
      await db.insert(
        'categories',
        {'name': cat},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  static Future<void> _createGoalsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS goals (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        target_amount REAL NOT NULL,
        allocated_amount REAL NOT NULL DEFAULT 0,
        category_name TEXT,
        notes TEXT NOT NULL DEFAULT ''
      )
    ''');
  }
}
