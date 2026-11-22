import 'package:debt_free/domain/entities/goal.dart';
import 'package:debt_free/domain/entities/transaction.dart';
import 'package:debt_free/domain/entities/transaction_type.dart';
import 'package:debt_free/domain/repositories/transaction_repository.dart';
import 'package:debt_free/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

class FakeTransactionRepository implements TransactionRepository {
  @override
  Future<int> syncFromSource({bool replaceExisting = false}) async => 0;

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
  Future<List<Goal>> getGoals() async => [];

  @override
  Future<void> addGoal(Goal goal) async {}

  @override
  Future<void> allocateToGoal(String goalId, double amountToAdd) async {}

  @override
  Future<void> deleteGoal(String goalId) async {}

  @override
  Future<void> assignGoalToTransaction(String transactionId, String? goalId) async {}
}


void main() {
  testWidgets('DebtFreeApp renders empty state and Refresh button', (WidgetTester tester) async {
    await tester.pumpWidget(DebtFreeApp(repository: FakeTransactionRepository()));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Dashboard'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.receipt_long_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Refresh'), findsOneWidget);
  });
}
