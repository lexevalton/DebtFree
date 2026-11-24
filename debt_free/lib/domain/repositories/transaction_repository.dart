import '../../data/sources/transaction_source.dart';
import '../entities/bank_account_profile.dart';
import '../entities/goal.dart';
import '../entities/transaction.dart';
import '../entities/transaction_type.dart';

abstract interface class TransactionRepository {
  TransactionSource get csvSource;
  TransactionSource get webSyncSource;

  Future<int> syncFromSource({
    TransactionSource? source,
    bool replaceExisting = false,
  });

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

  Future<List<BankAccountProfile>> getBankProfiles();
  Future<void> addBankProfile(BankAccountProfile profile);
  Future<void> toggleBankProfileActive(String id, bool isActive);
  Future<void> deleteBankProfile(String id);
  Future<void> markProfilesSynced(List<String> ids);

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
