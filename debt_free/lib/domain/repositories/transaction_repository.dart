import '../entities/transaction.dart';
import '../entities/transaction_type.dart';
import '../entities/goal.dart';

abstract interface class TransactionRepository {
  Future<int> syncFromSource({bool replaceExisting = false});
  Future<List<Transaction>> getLastTwelveMonthsTransactions();
  Future<void> updateTransactionType(String id, TransactionType newType);
  Future<List<String>> getCategories();
  Future<void> addCategory(String name, {int? color});
  Future<Map<String, int>> getCategoryColors();
  Future<Set<String>> getTrackedCategories();
  Future<void> setCategoryTracked(String categoryName, bool isTracked);
  Future<void> deleteCategory(String name);
  Future<Map<String, String>> getCategoryRules();
  Future<void> deleteCategoryRule(String merchantPattern);
  Future<List<Goal>> getGoals();
  Future<void> addGoal(Goal goal);
  Future<void> allocateToGoal(String goalId, double amountToAdd);
  Future<void> deleteGoal(String goalId);
  Future<void> assignGoalToTransaction(String transactionId, String? goalId);

  Future<void> assignCategoryToMerchant({
    required String transactionId,
    required String merchant,
    required String category,
    bool rememberForFuture = true,
  });

  Future<void> bulkAssignCategory({
    required List<Transaction> transactions,
    required String category,
    bool rememberRules = true,
  });

  Future<void> saveBulkCategoryMap({
    required Map<Transaction, String> updates,
    bool rememberRules = true,
  });
}
