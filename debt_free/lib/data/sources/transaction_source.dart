import '../../domain/entities/transaction.dart';

abstract interface class TransactionSource {
  String get sourceName;
  Future<List<Transaction>> fetchTransactions();
}
