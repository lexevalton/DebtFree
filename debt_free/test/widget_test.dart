import 'package:debt_free/core/sync/local_only_sync.dart';
import 'package:debt_free/data/sources/transaction_source.dart';
import 'package:debt_free/domain/entities/bank_account_profile.dart';
import 'package:debt_free/domain/entities/goal.dart';
import 'package:debt_free/domain/entities/transaction.dart';
import 'package:debt_free/domain/entities/transaction_type.dart';
import 'package:debt_free/domain/repositories/transaction_repository.dart';
import 'package:debt_free/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeTransactionSource implements TransactionSource {
  @override
  String get sourceName => 'Fake Source';

  @override
  Future<List<Transaction>> fetchTransactions() async => [];
}

class FakeTransactionRepository implements TransactionRepository {
  @override
  TransactionSource get csvSource => FakeTransactionSource();

  @override
  TransactionSource get webSyncSource => FakeTransactionSource();

  @override
  Future<int> syncFromSource({TransactionSource? source, bool replaceExisting = false}) async => 0;

  @override
  Future<List<Transaction>> getLastTwelveMonthsTransactions() async => [];

  @override
  Future<void> updateTransactionType(String id, TransactionType newType) async {}

  @override
  Future<List<String>> getCategories() async => ['Uncategorized'];

  @override
  Future<void> addCategory(String name, {int? color}) async {}

  @override
  Future<void> deleteCategory(String name) async {}

  @override
  Future<Map<String, String>> getCategoryRules() async => {};

  @override
  Future<void> deleteCategoryRule(String merchantPattern) async {}

  @override
  Future<void> assignCategoryToMerchant({
    required String transactionId,
    required String merchant,
    required String category,
    bool rememberForFuture = true,
  }) async {}

  @override
  Future<void> bulkAssignCategory({
    required List<Transaction> transactions,
    required String category,
    bool rememberRules = true,
  }) async {}

  @override
  Future<void> saveBulkCategoryMap({required Map<Transaction, String> updates, bool rememberRules = true}) async {}

  @override
  Future<Map<String, int>> getCategoryColors() async => {};

  @override
  Future<Set<String>> getTrackedCategories() async => {};

  @override
  Future<void> setCategoryTracked(String categoryName, bool isTracked) async {}

  @override
  Future<List<Goal>> getGoals() async => [];

  @override
  Future<void> addGoal(Goal goal) async {}

  @override
  Future<void> allocateToGoal(String goalId, double amountToAdd) async {}

  @override
  Future<void> deleteGoal(String goalId) async {}

  @override
  Future<void> assignGoalToTransaction(String transactionId, String? goalId) async {}

  @override
  Future<List<BankAccountProfile>> getBankProfiles() async => [];

  @override
  Future<void> addBankProfile(BankAccountProfile profile) async {}

  @override
  Future<void> toggleBankProfileActive(String id, bool isActive) async {}

  @override
  Future<void> deleteBankProfile(String id) async {}

  @override
  Future<void> markProfilesSynced(List<String> ids) async {}
}

void main() {
  testWidgets('DebtFreeApp renders Dashboard and Accounts menu', (WidgetTester tester) async {
    final navigatorKey = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      DebtFreeApp(
        repository: FakeTransactionRepository(),
        syncProvider: LocalOnlySync(),
        navigatorKey: navigatorKey,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Dashboard'), findsOneWidget);
    expect(find.text('Accounts'), findsOneWidget);
  });
}
