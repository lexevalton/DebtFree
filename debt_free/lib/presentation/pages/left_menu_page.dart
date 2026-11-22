import 'package:flutter/material.dart';
import '../../domain/repositories/transaction_repository.dart';
import 'categories_page.dart';
import 'dashboard_page.dart';
import 'expenses_page.dart';

class LeftMenuPage extends StatefulWidget {
  final TransactionRepository repository;

  const LeftMenuPage({super.key, required this.repository});

  @override
  State<LeftMenuPage> createState() => _LeftMenuPageState();
}

class _LeftMenuPageState extends State<LeftMenuPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardPage(repository: widget.repository),
      ExpensesPage(repository: widget.repository),
      CategoriesPage(repository: widget.repository),
    ];

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
            extended: MediaQuery.of(context).size.width >= 800,
            leading: const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Icon(Icons.account_balance_wallet, size: 32, color: Colors.blue),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.pie_chart_outline),
                selectedIcon: Icon(Icons.pie_chart),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long),
                label: Text('All Transactions'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.category_outlined),
                selectedIcon: Icon(Icons.category),
                label: Text('Categories'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: pages[_selectedIndex]),
        ],
      ),
    );
  }
}
