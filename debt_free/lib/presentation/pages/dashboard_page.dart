import 'package:flutter/material.dart';
import '../../domain/entities/goal.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../domain/usecases/calculate_safe_to_spend.dart';
import '../../domain/usecases/compare_monthly_spending.dart';
import '../../domain/usecases/detect_recurring_subscriptions.dart';
import '../widgets/dashboard/dashboard_goals_card.dart';
import '../widgets/dashboard/month_comparison_card.dart';
import '../widgets/dashboard/recurring_subscriptions_card.dart';
import '../widgets/dashboard/safe_to_spend_banner.dart';
import '../widgets/expensesPieChart/category_pie_chart_card.dart';
import '../widgets/expensesPieChart/category_transactions_card.dart';

class DashboardPage extends StatefulWidget {
  final TransactionRepository repository;

  const DashboardPage({super.key, required this.repository});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _calculateSafeToSpend = CalculateSafeToSpend();
  final _detectRecurring = DetectRecurringSubscriptions();
  final _compareMonthly = CompareMonthlySpending();

  List<Transaction> _transactions = [];
  List<Goal> _goals = [];
  List<String> _allCategories = [];
  Set<String> _trackedCategories = {};
  Map<String, Color> _dbCategoryColors = {};
  DashboardPeriod _selectedPeriod = DashboardPeriod.currentMonth;
  String? _selectedCategory;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final items = await widget.repository.getLastTwelveMonthsTransactions();
    final colors = await widget.repository.getCategoryColors();
    final goals = await widget.repository.getGoals();
    final categories = await widget.repository.getCategories();
    final tracked = await widget.repository.getTrackedCategories();
    if (!mounted) return;
    setState(() {
      _transactions = items;
      _dbCategoryColors = colors.map((k, v) => MapEntry(k, Color(v)));
      _goals = goals;
      _allCategories = categories;
      _trackedCategories = tracked;
      _isLoading = false;
    });
  }

  Future<void> _handleToggleTrackedCategory(String category, bool isTracked) async {
    await widget.repository.setCategoryTracked(category, isTracked);
    final updated = Set<String>.from(_trackedCategories);
    if (isTracked) {
      updated.add(category);
    } else {
      updated.remove(category);
    }
    if (!mounted) return;
    setState(() => _trackedCategories = updated);
  }

  List<Transaction> _filterExpensesByPeriod(List<Transaction> allExpenses) {
    final now = DateTime.now();
    return allExpenses.where((tx) {
      switch (_selectedPeriod) {
        case DashboardPeriod.currentMonth:
          return tx.date.year == now.year && tx.date.month == now.month;
        case DashboardPeriod.last6Months:
          return !tx.date.isBefore(DateTime(now.year, now.month - 5, 1));
        case DashboardPeriod.lastYear:
          return !tx.date.isBefore(DateTime(now.year - 1, now.month, now.day));
        case DashboardPeriod.all:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final allExpenses = _transactions.where((tx) => tx.isExpense).toList();
    final periodExpenses = _filterExpensesByPeriod(allExpenses);
    final selectedTxs = _selectedCategory == null
        ? <Transaction>[]
        : periodExpenses.where((tx) => tx.category == _selectedCategory).toList();

    final safeToSpend = _calculateSafeToSpend(_transactions);
    final recurringSummary = _detectRecurring(
      _transactions,
      trackedCategories: _trackedCategories,
    );
    final monthComparison = _compareMonthly(_transactions);

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : allExpenses.isEmpty
              ? const Center(
                  child: Text('No expenses yet. Go to "All Transactions" to import your CSVs.'),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SafeToSpendBanner(result: safeToSpend),
                      const SizedBox(height: 16),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          const spacing = 16.0;
                          const cardHeight = 360.0;
                          final isDesktop = constraints.maxWidth >= 800;
                          final cardWidth = isDesktop
                              ? (constraints.maxWidth - spacing) / 2
                              : constraints.maxWidth;

                          return Wrap(
                            spacing: spacing,
                            runSpacing: spacing,
                            children: [
                              SizedBox(
                                width: cardWidth,
                                height: cardHeight,
                                child: CategoryPieChartCard(
                                  expenses: periodExpenses,
                                  period: _selectedPeriod,
                                  selectedCategory: _selectedCategory,
                                  dbCategoryColors: _dbCategoryColors,
                                  onPeriodChanged: (p) => setState(() {
                                    _selectedPeriod = p;
                                    _selectedCategory = null;
                                  }),
                                  onCategorySelected: (cat) =>
                                      setState(() => _selectedCategory = cat),
                                ),
                              ),
                              SizedBox(
                                width: cardWidth,
                                height: cardHeight,
                                child: CategoryTransactionsCard(
                                  category: _selectedCategory,
                                  transactions: selectedTxs,
                                  onClear: () => setState(() => _selectedCategory = null),
                                ),
                              ),
                              SizedBox(
                                width: cardWidth,
                                height: cardHeight,
                                child: DashboardGoalsCard(
                                  goals: _goals,
                                  allTransactions: _transactions,
                                ),
                              ),
                              SizedBox(
                                width: cardWidth,
                                height: cardHeight,
                                child: RecurringSubscriptionsCard(
                                  summary: recurringSummary,
                                  allCategories: _allCategories,
                                  trackedCategories: _trackedCategories,
                                  onToggleCategory: _handleToggleTrackedCategory,
                                ),
                              ),
                              SizedBox(
                                width: cardWidth,
                                height: cardHeight,
                                child: MonthComparisonCard(
                                  comparison: monthComparison,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
    );
  }
}
