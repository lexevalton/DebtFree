enum AccountType {
  rbcChequing('RBC Chequing'),
  rbcVisa('RBC Visa'),
  wealthsimpleCash('Wealthsimple Cash'),
  unknown('Other Account');

  final String displayName;
  const AccountType(this.displayName);

  static AccountType fromStorageKey(String key) {
    return AccountType.values.firstWhere(
      (e) => e.name == key,
      orElse: () => AccountType.unknown,
    );
  }
}
