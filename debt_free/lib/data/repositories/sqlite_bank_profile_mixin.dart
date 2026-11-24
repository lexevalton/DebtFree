import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide Transaction;
import '../../core/database/app_database.dart';
import '../../core/sync/cloud_sync_provider.dart';
import '../../domain/entities/account_type.dart';
import '../../domain/entities/bank_account_profile.dart';

mixin SqliteBankProfileMixin {
  CloudSyncProvider get syncProvider;

  Future<List<BankAccountProfile>> getBankProfiles() async {
    final db = await AppDatabase.instance;
    final rows = await db.query('bank_profiles', orderBy: 'institution ASC, account_name ASC');
    return rows.map((r) {
      final syncedStr = r['last_synced_at'] as String?;
      return BankAccountProfile(
        id: r['id'] as String,
        institution: r['institution'] as String,
        accountName: r['account_name'] as String,
        accountType: AccountType.fromStorageKey(r['account_type'] as String),
        lastFourDigits: (r['last_four'] as String?) ?? '',
        isActive: (r['is_active'] as int? ?? 1) == 1,
        lastSyncedAt: syncedStr != null ? DateTime.tryParse(syncedStr) : null,
      );
    }).toList();
  }

  Future<void> addBankProfile(BankAccountProfile profile) async {
    final db = await AppDatabase.instance;
    await db.insert(
      'bank_profiles',
      {
        'id': profile.id,
        'institution': profile.institution,
        'account_name': profile.accountName,
        'account_type': profile.accountType.name,
        'last_four': profile.lastFourDigits,
        'is_active': profile.isActive ? 1 : 0,
        'last_synced_at': profile.lastSyncedAt?.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await syncProvider.pushDatabase(await AppDatabase.getDatabaseFile());
  }

  Future<void> toggleBankProfileActive(String id, bool isActive) async {
    final db = await AppDatabase.instance;
    await db.update(
      'bank_profiles',
      {'is_active': isActive ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
    await syncProvider.pushDatabase(await AppDatabase.getDatabaseFile());
  }

  Future<void> deleteBankProfile(String id) async {
    final db = await AppDatabase.instance;
    await db.delete('bank_profiles', where: 'id = ?', whereArgs: [id]);
    await syncProvider.pushDatabase(await AppDatabase.getDatabaseFile());
  }

  Future<void> markProfilesSynced(List<String> ids) async {
    if (ids.isEmpty) return;
    final db = await AppDatabase.instance;
    final nowIso = DateTime.now().toIso8601String();
    for (final id in ids) {
      await db.update('bank_profiles', {'last_synced_at': nowIso}, where: 'id = ?', whereArgs: [id]);
    }
    await syncProvider.pushDatabase(await AppDatabase.getDatabaseFile());
  }
}
