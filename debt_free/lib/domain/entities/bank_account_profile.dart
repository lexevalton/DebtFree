import 'account_type.dart';

class BankAccountProfile {
  final String id;
  final String institution;
  final String accountName;
  final AccountType accountType;
  final String lastFourDigits;
  final bool isActive;
  final DateTime? lastSyncedAt;

  const BankAccountProfile({
    required this.id,
    required this.institution,
    required this.accountName,
    required this.accountType,
    this.lastFourDigits = '',
    this.isActive = true,
    this.lastSyncedAt,
  });

  BankAccountProfile copyWith({
    bool? isActive,
    DateTime? lastSyncedAt,
  }) {
    return BankAccountProfile(
      id: id,
      institution: institution,
      accountName: accountName,
      accountType: accountType,
      lastFourDigits: lastFourDigits,
      isActive: isActive ?? this.isActive,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }
}
