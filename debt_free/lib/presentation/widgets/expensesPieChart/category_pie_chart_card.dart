import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/transaction.dart';

enum DashboardPeriod {
  currentMonth('Current Month'),
  last6Months('Last 6 Months'),
  lastYear('Last Year'),
  all('All Time');

  final String label;
  const DashboardPeriod(this.label);
}

class CategoryPieChartCard extends StatefulWidget {
  final List<Transaction> expenses;
  final DashboardPeriod period;
  final String? selectedCategory;
  final Map<String, Color> dbCategoryColors;
  final ValueChanged<DashboardPeriod> onPeriodChanged;
  final ValueChanged<String?> onCategorySelected;

  const CategoryPieChartCard({
    super.key,
    required this.expenses,
    required this.period,
    required this.selectedCategory,
    required this.dbCategoryColors,
    required this.onPeriodChanged,
    required this.onCategorySelected,
  });

  static const Map<String, Color> defaultColors = {
    'Uncategorized': Color(0xFF78909C),
    'Groceries': Color(0xFF2E7D32),
    'Personal & Household': Color(0xFF66BB6A),
    'Health & Pharmacy': Color(0xFF00897B),
    'Dining Out': Color(0xFFD32F2F),
    'Subscriptions': Color(0xFF8E0000),
    'Personal Activities': Color(0xFFFF5252),
    'My Clothing & Jewelry': Color(0xFFC2185B),
    'Car, Gas & Auto Ins.': Color(0xFF1565C0),
    'Bills & Utilities': Color(0xFF0288D1),
    'Taxes & Gov': Color(0xFF4A148C),
    'Housing': Color(0xFF7B1FA2),
    'Insurance': Color(0xFF9575CD),
    'School Fees': Color(0xFFF57F17),
    'Kids Activities': Color(0xFFFBC02D),
    'Kids Clothing & Gear': Color(0xFFFFA000),
  };

  @override
  State<CategoryPieChartCard> createState() => _CategoryPieChartCardState();
}

class _CategoryPieChartCardState extends State<CategoryPieChartCard> {
  int _hoveredIndex = -1;

  Color _getColor(String category, int fallbackIndex) {
    return CategoryPieChartCard.defaultColors[category] ??
        widget.dbCategoryColors[category] ??
        Colors.primaries[fallbackIndex % Colors.primaries.length];
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'en_CA', symbol: '\$');
    final periodTotal = widget.expenses.fold<double>(0.0, (s, tx) => s + tx.absoluteAmount);

    final Map<String, double> byCat = {};
    for (final tx in widget.expenses) {
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
                  value: widget.period,
                  underline: const SizedBox(),
                  items: DashboardPeriod.values
                      .map((p) => DropdownMenuItem(value: p, child: Text(p.label)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) widget.onPeriodChanged(val);
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
              const Expanded(
                child: Center(child: Text('No expenses for this period.')),
              )
            else
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 36,
                          pieTouchData: PieTouchData(
                            touchCallback: (FlTouchEvent event, response) {
                              final idx = response?.touchedSection?.touchedSectionIndex ?? -1;
                              setState(() {
                                _hoveredIndex = event.isInterestedForInteractions ? idx : -1;
                              });
                              if (event is FlTapUpEvent && idx >= 0 && idx < sorted.length) {
                                final clickedCat = sorted[idx].key;
                                // Second click on same slice deselects it
                                widget.onCategorySelected(
                                  widget.selectedCategory == clickedCat ? null : clickedCat,
                                );
                              }
                            },
                          ),
                          sections: List.generate(sorted.length, (i) {
                            final entry = sorted[i];
                            final isSelected = entry.key == widget.selectedCategory;
                            final isHovered = i == _hoveredIndex;
                            final pct = (entry.value / periodTotal) * 100;

                            return PieChartSectionData(
                              value: entry.value,
                              color: _getColor(entry.key, i),
                              radius: (isSelected || isHovered) ? 65 : 55,
                              title: pct >= 5 || isHovered || isSelected
                                  ? '${pct.toStringAsFixed(1)}%'
                                  : '',
                              titleStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              badgeWidget: isHovered
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                              badgePositionPercentageOffset: 0.85,
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
                          final isSelected = entry.key == widget.selectedCategory;
                          return InkWell(
                            onTap: () => widget.onCategorySelected(
                              isSelected ? null : entry.key,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 3),
                              child: Row(
                                children: [
                                  Container(width: 10, height: 10, color: _getColor(entry.key, i)),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      entry.key,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    currency.format(entry.value),
                                    style: TextStyle(
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
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
}
