import 'account_type.dart';
import 'transaction_type.dart';

class Transaction {
  final String id;
  final AccountType account;
  final DateTime date;
  final double amount;
  final String merchant;
  final String category;
  final TransactionType type;
  final String? goalId;

  const Transaction({
    required this.id,
    required this.account,
    required this.date,
    required this.amount,
    required this.merchant,
    required this.type,
    this.category = 'Uncategorized',
    this.goalId
  });

  bool get isExpense => type == TransactionType.expense;
  bool get isIncome => type == TransactionType.income;
  bool get isTransfer => type == TransactionType.transfer;
  double get absoluteAmount => amount.abs();

  Transaction copyWith({
    TransactionType? type,
    String? category,
    String? goalId,
  }) {
    return Transaction(
      id: id,
      account: account,
      date: date,
      amount: amount,
      merchant: merchant,
      type: type ?? this.type,
      category: category ?? this.category,
      goalId: goalId ?? this.goalId,
    );
  }
}
