import '../entities/transaction.dart';

class RecurringSubscription {
  final String title;
  final String subtitle;
  final String? categoryName;
  final double monthlyAmount;
  final double yearlyAmount;
  final int monthsCount;
  final bool isTrackedCategory;

  const RecurringSubscription({
    required this.title,
    required this.subtitle,
    this.categoryName,
    required this.monthlyAmount,
    required this.yearlyAmount,
    required this.monthsCount,
    required this.isTrackedCategory,
  });
}

class RecurringSummary {
  final List<RecurringSubscription> items;
  final double totalMonthly;
  final double totalYearly;

  const RecurringSummary({
    required this.items,
    required this.totalMonthly,
    required this.totalYearly,
  });
}

class DetectRecurringSubscriptions {
  String _normalizeMerchant(String raw) {
    final cleaned = raw
        .toLowerCase()
        .replaceAll(RegExp(r'[0-9#*_-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return cleaned.isEmpty ? raw.toLowerCase().trim() : cleaned;
  }

  RecurringSummary call(
    List<Transaction> transactions, {
    Set<String> trackedCategories = const {},
  }) {
    final expenses = transactions.where((tx) => tx.isExpense).toList();
    if (expenses.isEmpty && trackedCategories.isEmpty) {
      return const RecurringSummary(items: [], totalMonthly: 0, totalYearly: 0);
    }

    // Count distinct active months across all imported expenses for realistic monthly averages
    final allMonths = expenses
        .map((tx) => '${tx.date.year}-${tx.date.month}')
        .toSet();
    final activeMonthsCount = allMonths.isEmpty ? 1 : allMonths.length;

    final items = <RecurringSubscription>[];

    // 1. Pinned / Tracked Essential Categories (variable monthly averages)
    for (final cat in trackedCategories) {
      final catExpenses =
          expenses.where((tx) => tx.category == cat).toList();
      final totalSpent =
          catExpenses.fold(0.0, (sum, tx) => sum + tx.absoluteAmount);
      final avgMonthly = totalSpent / activeMonthsCount;

      items.add(
        RecurringSubscription(
          title: cat,
          subtitle: 'Tracked category avg (${catExpenses.length} txs / $activeMonthsCount mo)',
          categoryName: cat,
          monthlyAmount: avgMonthly,
          yearlyAmount: avgMonthly * 12,
          monthsCount: activeMonthsCount,
          isTrackedCategory: true,
        ),
      );
    }

    // 2. Auto-detected Fixed Subscriptions (excluding categories already tracked above)
    final groupedByMerchant = <String, List<Transaction>>{};
    for (final tx in expenses) {
      if (trackedCategories.contains(tx.category)) continue;
      final key = _normalizeMerchant(tx.merchant);
      groupedByMerchant.putIfAbsent(key, () => []).add(tx);
    }

    for (final entry in groupedByMerchant.entries) {
      final txs = entry.value;
      if (txs.length < 2) continue;

      final byMonth = <String, List<Transaction>>{};
      for (final tx in txs) {
        final monthKey = '${tx.date.year}-${tx.date.month}';
        byMonth.putIfAbsent(monthKey, () => []).add(tx);
      }
      if (byMonth.length < 2) continue;

      final monthlyTotals = byMonth.values
          .map((list) => list.fold(0.0, (sum, tx) => sum + tx.absoluteAmount))
          .toList();
      final avgMonthly =
          monthlyTotals.reduce((a, b) => a + b) / monthlyTotals.length;
      if (avgMonthly <= 0) continue;

      final isConsistent = monthlyTotals.every(
        (amount) => (amount - avgMonthly).abs() <= avgMonthly * 0.15,
      );
      if (!isConsistent) continue;

      txs.sort((a, b) => b.date.compareTo(a.date));
      final latest = txs.first;

      items.add(
        RecurringSubscription(
          title: latest.merchant,
          subtitle: '${latest.category} • Auto-detected (${byMonth.length} mo)',
          monthlyAmount: avgMonthly,
          yearlyAmount: avgMonthly * 12,
          monthsCount: byMonth.length,
          isTrackedCategory: false,
        ),
      );
    }

    items.sort((a, b) => b.monthlyAmount.compareTo(a.monthlyAmount));

    final totalMonthly =
        items.fold(0.0, (sum, item) => sum + item.monthlyAmount);

    return RecurringSummary(
      items: items,
      totalMonthly: totalMonthly,
      totalYearly: totalMonthly * 12,
    );
  }
}
