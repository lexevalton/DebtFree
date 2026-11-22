import '../entities/transaction.dart';
import '../entities/transaction_type.dart';

abstract interface class TransactionRepository {
  Future<int> syncFromSource({bool replaceExisting = false});
  Future<List<Transaction>> getLastTwelveMonthsTransactions();
  Future<void> updateTransactionType(String id, TransactionType newType);
    Future<List<String>> getCategories();
  Future<void> addCategory(String name);
  Future<void> deleteCategory(String name);
  Future<Map<String, String>> getCategoryRules();
  Future<void> deleteCategoryRule(String merchantPattern);

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
