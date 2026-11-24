import 'package:flutter/material.dart';
import '../../core/database/app_database.dart';
import '../../core/sync/cloud_sync_provider.dart';
import '../../core/sync/local_only_sync.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../theme/app_theme.dart';
import 'bank_profiles_page.dart';
import 'categories_page.dart';
import 'dashboard_page.dart';
import 'expenses_page.dart';
import 'goals_page.dart';

class LeftMenuPage extends StatefulWidget {
  final TransactionRepository repository;
  final CloudSyncProvider? syncProvider;

  const LeftMenuPage({super.key, required this.repository, this.syncProvider});

  @override
  State<LeftMenuPage> createState() => _LeftMenuPageState();
}

class _LeftMenuPageState extends State<LeftMenuPage> {
  int _selectedIndex = 0;
  bool _isMenuExtended = true;
  bool _isSyncingCloud = false;
  DatabaseProfile _activeProfile = AppDatabase.currentProfile;
  int _reloadTick = 0;

  CloudSyncProvider get _cloud => widget.syncProvider ?? LocalOnlySync();

  Future<void> _onProfileChanged(DatabaseProfile? profile) async {
    if (profile == null || profile == _activeProfile) return;
    await AppDatabase.switchProfile(profile);
    if (!mounted) return;
    setState(() {
      _activeProfile = profile;
      _reloadTick++;
    });
  }

  Future<void> _handleCloudSyncTap() async {
    if (_isSyncingCloud) return;
    setState(() => _isSyncingCloud = true);
    try {
      final ok = await _cloud.connect();
      if (!ok) return;

      final localFile = await AppDatabase.getDatabaseFile();
      final remoteModified = await _cloud.getRemoteLastModified();

      if (remoteModified != null &&
          (!await localFile.exists() || remoteModified.isAfter((await localFile.stat()).modified))) {
        await AppDatabase.switchProfile(DatabaseProfile.real);
        await _cloud.pullDatabase(localFile);
        if (mounted) setState(() => _reloadTick++);
      } else if (await localFile.exists()) {
        await _cloud.pushDatabase(localFile);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google Drive synchronized!')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncingCloud = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardPage(key: ValueKey('dash_$_reloadTick'), repository: widget.repository),
      ExpensesPage(key: ValueKey('exp_$_reloadTick'), repository: widget.repository),
      CategoriesPage(key: ValueKey('cat_$_reloadTick'), repository: widget.repository),
      GoalsPage(key: ValueKey('goal_$_reloadTick'), repository: widget.repository),
      BankProfilesPage(key: ValueKey('bank_$_reloadTick'), repository: widget.repository),
    ];

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
            extended: _isMenuExtended,
            backgroundColor: AppColors.surface,
            indicatorColor: AppColors.menuSelected,
            selectedIconTheme: const IconThemeData(color: AppColors.primaryDark),
            unselectedIconTheme: const IconThemeData(color: AppColors.textSecondary),
            selectedLabelTextStyle: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w600),
            unselectedLabelTextStyle: const TextStyle(color: AppColors.textSecondary),
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isMenuExtended) ...[
                    const Icon(Icons.account_balance_wallet, size: 30, color: AppColors.primary),
                    const SizedBox(width: 8),
                    const Text('DebtFree', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                    const SizedBox(width: 8),
                  ],
                  IconButton(
                    icon: Icon(_isMenuExtended ? Icons.menu_open : Icons.menu),
                    color: AppColors.textSecondary,
                    tooltip: _isMenuExtended ? 'Collapse menu' : 'Expand menu',
                    onPressed: () => setState(() => _isMenuExtended = !_isMenuExtended),
                  ),
                ],
              ),
            ),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 14, left: 8, right: 8),
                  child: _isMenuExtended
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _isSyncingCloud ? null : _handleCloudSyncTap,
                              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                              icon: _isSyncingCloud
                                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Icon(Icons.cloud_sync_outlined, size: 18),
                              label: const Text('Drive Sync', style: TextStyle(fontSize: 12.5)),
                            ),
                            const SizedBox(height: 8),
                            _buildProfileSelector(),
                          ],
                        )
                      : IconButton(
                          tooltip: 'Google Drive Sync',
                          icon: const Icon(Icons.cloud_sync_outlined, color: AppColors.primary),
                          onPressed: _handleCloudSyncTap,
                        ),
                ),
              ),
            ),
            destinations: const [
              NavigationRailDestination(icon: Icon(Icons.pie_chart_outline), selectedIcon: Icon(Icons.pie_chart), label: Text('Dashboard')),
              NavigationRailDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: Text('All Transactions')),
              NavigationRailDestination(icon: Icon(Icons.category_outlined), selectedIcon: Icon(Icons.category), label: Text('Categories')),
              NavigationRailDestination(icon: Icon(Icons.flag_outlined), selectedIcon: Icon(Icons.flag), label: Text('Goals')),
              NavigationRailDestination(icon: Icon(Icons.account_balance_outlined), selectedIcon: Icon(Icons.account_balance), label: Text('Accounts')),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1, color: AppColors.border),
          Expanded(
            child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: pages[_selectedIndex]),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: _activeProfile == DatabaseProfile.real ? AppColors.background : AppColors.warning.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _activeProfile == DatabaseProfile.real ? AppColors.border : AppColors.warning),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<DatabaseProfile>(
          value: _activeProfile,
          isDense: true,
          style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
          items: DatabaseProfile.values.map((p) => DropdownMenuItem(value: p, child: Text(p.label))).toList(),
          onChanged: _onProfileChanged,
        ),
      ),
    );
  }
}
