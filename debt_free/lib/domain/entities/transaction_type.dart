enum TransactionType {
  expense,
  income,
  transfer;

  static TransactionType fromStorageKey(String key) {
    return TransactionType.values.firstWhere(
      (e) => e.name == key,
      orElse: () => TransactionType.expense,
    );
  }
}
