import '../entities/transaction.dart';

class SafeToSpendResult {
  final double dailyAllowance;
  final double safeToday;
  final double spentToday;
  final double priorDebt;
  final double currentMonthIncome;
  final double carryOver;
  final double availableFunds;
  final double allowedToDate;
  final double spentThisMonth;
  final int daysInMonth;
  final int currentDay;
  final int daysToRecover;
  final bool hasAvailableFunds;

  const SafeToSpendResult({
    required this.dailyAllowance,
    required this.safeToday,
    required this.spentToday,
    required this.priorDebt,
    required this.currentMonthIncome,
    required this.carryOver,
    required this.availableFunds,
    required this.allowedToDate,
    required this.spentThisMonth,
    required this.daysInMonth,
    required this.currentDay,
    required this.daysToRecover,
    required this.hasAvailableFunds,
  });

  bool get isOnTrack => safeToday > 0.009;
  double get overAmount => safeToday < 0 ? safeToday.abs() : 0.0;
}

class CalculateSafeToSpend {
  bool _isOutflow(Transaction tx) =>
      tx.isExpense || (tx.isTransfer && tx.goalId != null);

  SafeToSpendResult call(List<Transaction> transactions, {DateTime? now}) {
    final current = now ?? DateTime.now();
    final startOfCurrentMonth = DateTime(current.year, current.month, 1);
    final daysInMonth = DateTime(current.year, current.month + 1, 0).day;

    // Cumulative balance from all months prior to the current month
    final priorTxs = transactions.where(
      (tx) => tx.date.isBefore(startOfCurrentMonth),
    );
    final priorIncome = priorTxs
        .where((tx) => tx.isIncome)
        .fold(0.0, (sum, tx) => sum + tx.absoluteAmount);
    final priorOutflows = priorTxs
        .where(_isOutflow)
        .fold(0.0, (sum, tx) => sum + tx.absoluteAmount);

    final carryOver = priorIncome - priorOutflows;
    final priorDebt = carryOver < 0 ? carryOver.abs() : 0.0;

    final currentMonthTxs = transactions.where(
      (tx) => tx.date.year == current.year && tx.date.month == current.month,
    );

    final currentMonthIncome = currentMonthTxs
        .where((tx) => tx.isIncome)
        .fold(0.0, (sum, tx) => sum + tx.absoluteAmount);

    final spentThisMonth = currentMonthTxs
        .where(_isOutflow)
        .fold(0.0, (sum, tx) => sum + tx.absoluteAmount);

    final spentToday = currentMonthTxs
        .where((tx) => _isOutflow(tx) && tx.date.day == current.day)
        .fold(0.0, (sum, tx) => sum + tx.absoluteAmount);

    final availableFunds = currentMonthIncome + carryOver;

    if (availableFunds <= 0) {
      return SafeToSpendResult(
        dailyAllowance: 0.0,
        safeToday: availableFunds - spentThisMonth,
        spentToday: spentToday,
        priorDebt: priorDebt,
        currentMonthIncome: currentMonthIncome,
        carryOver: carryOver,
        availableFunds: availableFunds,
        allowedToDate: 0.0,
        spentThisMonth: spentThisMonth,
        daysInMonth: daysInMonth,
        currentDay: current.day,
        daysToRecover: 0,
        hasAvailableFunds: false,
      );
    }

    final dailyAllowance = availableFunds / daysInMonth;
    final allowedToDate = dailyAllowance * current.day;
    final safeToday = allowedToDate - spentThisMonth;

    int daysToRecover = 0;
    if (safeToday <= 0.009 && dailyAllowance > 0) {
      final deficit = safeToday < 0 ? safeToday.abs() : 0.0;
      daysToRecover = (deficit / dailyAllowance).floor() + 1;
    }

    return SafeToSpendResult(
      dailyAllowance: dailyAllowance,
      safeToday: safeToday,
      spentToday: spentToday,
      priorDebt: priorDebt,
      currentMonthIncome: currentMonthIncome,
      carryOver: carryOver,
      availableFunds: availableFunds,
      allowedToDate: allowedToDate,
      spentThisMonth: spentThisMonth,
      daysInMonth: daysInMonth,
      currentDay: current.day,
      daysToRecover: daysToRecover,
      hasAvailableFunds: true,
    );
  }
}
