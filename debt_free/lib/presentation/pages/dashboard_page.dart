import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';

enum DashboardPeriod {
  currentMonth('Current Month'),
  last6Months('Last 6 Months'),
  lastYear('Last Year'),
  all('All Time');

  final String label;
  const DashboardPeriod(this.label);
}

class DashboardPage extends StatefulWidget {
  final TransactionRepository repository;

  const DashboardPage({super.key, required this.repository});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List<Transaction> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final items = await widget.repository.getLastTwelveMonthsTransactions();
    setState(() {
      _transactions = items;
      _isLoading = false;
    });
  }

  DashboardPeriod _selectedPeriod = DashboardPeriod.currentMonth;
  int _touchedIndex = -1;

   static const Map<String, Color> _categoryColors = {
    // Grey
    'Uncategorized': Color(0xFF78909C),        

    // Shades of Green
    'Groceries': Color(0xFF2E7D32),            
    'Personal & Household': Color(0xFF66BB6A), 
    'Health & Pharmacy': Color(0xFF00897B),    

    // Shades of Red
    'Dining Out': Color(0xFFD32F2F),           
    'Subscriptions': Color(0xFF8E0000),        
    'Personal Activities': Color(0xFFFF5252),  
    'My Clothing & Jewelry': Color(0xFFC2185B),

    // Shades of Blue
    'Car, Gas & Auto Ins.': Color(0xFF1565C0), 
    'Bills & Utilities': Color(0xFF0288D1),    

    // Shades of Purple
    'Taxes & Gov': Color(0xFF4A148C),          
    'Housing': Color(0xFF7B1FA2),              
    'Insurance': Color(0xFF9575CD),            

    // Shades of Yellow
    'School Fees': Color(0xFFF57F17),          
    'Kids Activities': Color(0xFFFBC02D),      
    'Kids Clothing & Gear': Color(0xFFFFA000), 
  };


  Color _getCategoryColor(String category, int fallbackIndex) {
    return _categoryColors[category] ??
        Colors.primaries[fallbackIndex % Colors.primaries.length];
  }


  Widget _buildPieChartCard(List<Transaction> allExpenses, NumberFormat currency) {
    final now = DateTime.now();

    final filtered = allExpenses.where((tx) {
      switch (_selectedPeriod) {
        case DashboardPeriod.currentMonth:
          return tx.date.year == now.year && tx.date.month == now.month;
        case DashboardPeriod.last6Months:
          final cutoff = DateTime(now.year, now.month - 5, 1);
          return !tx.date.isBefore(cutoff);
        case DashboardPeriod.lastYear:
          final cutoff = DateTime(now.year - 1, now.month, now.day);
          return !tx.date.isBefore(cutoff);
        case DashboardPeriod.all:
          return true;
      }
    }).toList();

    final periodTotal = filtered.fold<double>(0.0, (sum, tx) => sum + tx.absoluteAmount);

    final Map<String, double> byCat = {};
    for (final tx in filtered) {
      byCat[tx.category] = (byCat[tx.category] ?? 0.0) + tx.absoluteAmount;
    }
    final sorted = byCat.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Expenses by Category',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                DropdownButton<DashboardPeriod>(
                  value: _selectedPeriod,
                  underline: const SizedBox(),
                  items: DashboardPeriod.values
                      .map((p) => DropdownMenuItem(value: p, child: Text(p.label)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedPeriod = val;
                        _touchedIndex = -1;
                      });
                    }
                  },
                ),
              ],
            ),
            Text(
              '-${currency.format(periodTotal)}',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 16),
            if (sorted.isEmpty)
              const SizedBox(
                height: 220,
                child: Center(child: Text('No expenses for this period.')),
              )
            else
              SizedBox(
                height: 240,
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 36,
                          pieTouchData: PieTouchData(
                            touchCallback: (FlTouchEvent event, pieTouchResponse) {
                              setState(() {
                                if (!event.isInterestedForInteractions ||
                                    pieTouchResponse == null ||
                                    pieTouchResponse.touchedSection == null) {
                                  _touchedIndex = -1;
                                  return;
                                }
                                _touchedIndex =
                                    pieTouchResponse.touchedSection!.touchedSectionIndex;
                              });
                            },
                          ),
                          sections: List.generate(sorted.length, (i) {
                            final entry = sorted[i];
                            final isTouched = i == _touchedIndex;
                            final pct = (entry.value / periodTotal) * 100;
                            final color = _getCategoryColor(entry.key, i);

                            return PieChartSectionData(
                              value: entry.value,
                              color: color,
                              radius: isTouched ? 65 : 55,
                              title: pct >= 5 || isTouched ? '${pct.toStringAsFixed(1)}%' : '',
                              titleStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              // Badge affichant le montant exact au survol (hover)
                              badgeWidget: isTouched
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.black87,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '${entry.key}: ${currency.format(entry.value)}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    )
                                  : null,
                              badgePositionPercentageOffset: 1.25,
                            );
                          }),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ListView.builder(
                        itemCount: sorted.length,
                        itemBuilder: (context, i) {
                          final entry = sorted[i];
                          final isTouched = i == _touchedIndex;
                          final color = _getCategoryColor(entry.key, i);
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              children: [
                                Container(width: 10, height: 10, color: color),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    entry.key,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight:
                                          isTouched ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                Text(
                                  currency.format(entry.value),
                                  style: TextStyle(
                                    fontWeight:
                                        isTouched ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'en_CA', symbol: '\$');
    final expenses = _transactions.where((tx) => tx.isExpense).toList();

    final Map<String, double> byCategory = {};
    for (final tx in expenses) {
      byCategory[tx.category] = (byCategory[tx.category] ?? 0.0) + tx.absoluteAmount;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard — Expenses by Category')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : expenses.isEmpty
              ? const Center(
                  child: Text('No expenses yet. Go to "All Transactions" to import your CSVs.'),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      const spacing = 16.0;
                      // 2 colonnes max sur Desktop (>= 800px), 1 colonne sur mobile
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
                            child: _buildPieChartCard(expenses, currency),
                          ),
                          // Tes futurs widgets iront ici avec SizedBox(width: cardWidth, child: ...)
                        ],
                      );
                    },
                  ),
                ),
                );
  }
}
