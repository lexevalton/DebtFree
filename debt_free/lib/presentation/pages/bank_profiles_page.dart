import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/account_type.dart';
import '../../domain/entities/bank_account_profile.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../theme/app_theme.dart';

class BankProfilesPage extends StatefulWidget {
  final TransactionRepository repository;

  const BankProfilesPage({super.key, required this.repository});

  @override
  State<BankProfilesPage> createState() => _BankProfilesPageState();
}

class _BankProfilesPageState extends State<BankProfilesPage> {
  List<BankAccountProfile> _profiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final items = await widget.repository.getBankProfiles();
    if (!mounted) return;
    setState(() {
      _profiles = items;
      _isLoading = false;
    });
  }

  Future<void> _openAddDialog() async {
    String institution = 'RBC';
    final nameCtrl = TextEditingController();
    final digitsCtrl = TextEditingController();
    AccountType selectedType = AccountType.rbcChequing;

    final created = await showDialog<BankAccountProfile>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Bank Account or Credit Card'),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: institution,
                  decoration: const InputDecoration(labelText: 'Institution'),
                  items: ['RBC', 'Wealthsimple', 'CIBC', 'Desjardins', 'TD', 'Other']
                      .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => institution = v ?? 'RBC'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<AccountType>(
                  initialValue: selectedType,
                  decoration: const InputDecoration(labelText: 'Account Category'),
                  items: const [
                    DropdownMenuItem(value: AccountType.rbcChequing, child: Text('Chequing Account')),
                    DropdownMenuItem(value: AccountType.rbcVisa, child: Text('Credit Card (Visa / MC)')),
                    DropdownMenuItem(value: AccountType.unknown, child: Text('Savings / Investment')),
                  ],
                  onChanged: (v) => setDialogState(() => selectedType = v ?? AccountType.rbcChequing),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Account Label (e.g. RBC Chequing, Avion Visa)',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: digitsCtrl,
                  maxLength: 4,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Last 4 digits (optional, helps auto-match)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final label = nameCtrl.text.trim();
                if (label.isEmpty) return;
                Navigator.pop(
                  ctx,
                  BankAccountProfile(
                    id: 'acct_${DateTime.now().millisecondsSinceEpoch}',
                    institution: institution,
                    accountName: label,
                    accountType: selectedType,
                    lastFourDigits: digitsCtrl.text.trim(),
                  ),
                );
              },
              child: const Text('Save Account'),
            ),
          ],
        ),
      ),
    );

    if (created != null) {
      await widget.repository.addBankProfile(created);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bank Accounts & Sync'),
        actions: [
          FilledButton.icon(
            onPressed: _openAddDialog,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primaryDark,
            ),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Account'),
          ),
          const SizedBox(width: 24),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Active accounts and credit cards monitored during bank sync:',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _profiles.isEmpty
                        ? const Center(
                            child: Text(
                              'No bank accounts configured yet.\nClick "Add Account" to add your Chequing or Credit Card.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _profiles.length,
                            itemBuilder: (context, i) {
                              final item = _profiles[i];
                              final syncText = item.lastSyncedAt == null
                                  ? 'Never synced yet'
                                  : 'Last synced: ${DateFormat('yyyy-MM-dd HH:mm').format(item.lastSyncedAt!)}';
                              final digits = item.lastFourDigits.isEmpty ? '' : ' •••• ${item.lastFourDigits}';

                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                child: ListTile(
                                  leading: Icon(
                                    item.accountType == AccountType.rbcVisa
                                        ? Icons.credit_card
                                        : Icons.account_balance,
                                    color: item.isActive ? AppColors.primary : Colors.grey,
                                  ),
                                  title: Text(
                                    '${item.institution} — ${item.accountName}$digits',
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  subtitle: Text(syncText),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Switch(
                                        value: item.isActive,
                                        activeThumbColor: AppColors.primary,
                                        onChanged: (val) async {
                                          await widget.repository.toggleBankProfileActive(item.id, val);
                                          await _load();
                                        },
                                      ),
                                      IconButton(
                                        tooltip: 'Remove account',
                                        icon: const Icon(Icons.delete_outline, color: AppColors.error),
                                        onPressed: () async {
                                          await widget.repository.deleteBankProfile(item.id);
                                          await _load();
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
