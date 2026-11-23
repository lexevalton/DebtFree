import '../entities/transaction.dart';

class CategoryDelta {
  final String category;
  final double currentAmount;
  final double previousAmount;
  final double difference;

  const CategoryDelta({
    required this.category,
    required this.currentAmount,
    required this.previousAmount,
    required this.difference,
  });
}

class MonthComparisonResult {
  final double currentToDate;
  final double previousToDate;
  final double difference;
  final double percentChange;
  final int comparisonDay;
  final bool hasPreviousMonthData;
  final List<CategoryDelta> topCategoryChanges;

  const MonthComparisonResult({
    required this.currentToDate,
    required this.previousToDate,
    required this.difference,
    required this.percentChange,
    required this.comparisonDay,
    required this.hasPreviousMonthData,
    required this.topCategoryChanges,
  });

  bool get isSpendingLess => difference <= 0;
}

class CompareMonthlySpending {
  MonthComparisonResult call(List<Transaction> transactions, {DateTime? now}) {
    final current = now ?? DateTime.now();
    final prevMonthDate = DateTime(current.year, current.month - 1, 1);
    final daysInPrevMonth =
        DateTime(prevMonthDate.year, prevMonthDate.month + 1, 0).day;
    final cappedPrevDay =
        current.day > daysInPrevMonth ? daysInPrevMonth : current.day;

    final currentExpenses = transactions.where(
      (tx) =>
          tx.isExpense &&
          tx.date.year == current.year &&
          tx.date.month == current.month &&
          tx.date.day <= current.day,
    );

    final previousExpenses = transactions.where(
      (tx) =>
          tx.isExpense &&
          tx.date.year == prevMonthDate.year &&
          tx.date.month == prevMonthDate.month &&
          tx.date.day <= cappedPrevDay,
    );

    final currentByCategory = <String, double>{};
    double currentTotal = 0.0;
    for (final tx in currentExpenses) {
      currentTotal += tx.absoluteAmount;
      currentByCategory[tx.category] =
          (currentByCategory[tx.category] ?? 0.0) + tx.absoluteAmount;
    }

    final prevByCategory = <String, double>{};
    double previousTotal = 0.0;
    for (final tx in previousExpenses) {
      previousTotal += tx.absoluteAmount;
      prevByCategory[tx.category] =
          (prevByCategory[tx.category] ?? 0.0) + tx.absoluteAmount;
    }

    final hasPrevData = previousTotal > 0.009;
    final difference = currentTotal - previousTotal;
    final percentChange =
        hasPrevData ? (difference / previousTotal) * 100 : 0.0;

    final allCategories = <String>{
      ...currentByCategory.keys,
      ...prevByCategory.keys,
    };

    final deltas = allCategories.map((cat) {
      final curr = currentByCategory[cat] ?? 0.0;
      final prev = prevByCategory[cat] ?? 0.0;
      return CategoryDelta(
        category: cat,
        currentAmount: curr,
        previousAmount: prev,
        difference: curr - prev,
      );
    }).where((d) => d.difference.abs() >= 1.0).toList();

    deltas.sort((a, b) => b.difference.compareTo(a.difference));

    return MonthComparisonResult(
      currentToDate: currentTotal,
      previousToDate: previousTotal,
      difference: difference,
      percentChange: percentChange,
      comparisonDay: current.day,
      hasPreviousMonthData: hasPrevData,
      topCategoryChanges: deltas.take(4).toList(),
    );
  }
}
