import 'package:flutter/material.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../widgets/gradiant_color_slider.dart';

class CategoriesPage extends StatefulWidget {
  final TransactionRepository repository;

  const CategoriesPage({super.key, required this.repository});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  final _controller = TextEditingController();
  List<String> _categories = [];
  Map<String, String> _rules = {};
  bool _isLoading = true;
  double _hue = 180.0;        // 0..360

  Color get _selectedColor =>
      HSLColor.fromAHSL(1.0, _hue, 0.78, 0.45).toColor();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final cats = await widget.repository.getCategories();
    final rules = await widget.repository.getCategoryRules();
    setState(() {
      _categories = cats;
      _rules = rules;
      _isLoading = false;
    });
  }

  Future<void> _createCategory() async {
    if (_controller.text.trim().isEmpty) return;
    await widget.repository.addCategory(_controller.text.trim());
    _controller.clear();
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categories & Auto-Rules')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            decoration: const InputDecoration(
                              labelText: 'New Category Name',
                              border: OutlineInputBorder(),
                            ),
                            onSubmitted: (_) => _createCategory(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        FilledButton.icon(
                          onPressed: _createCategory,
                          icon: const Icon(Icons.add),
                          label: const Text('Add'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                                       const SizedBox(height: 10),
                    Row(
                      children: [
                        // Live color preview
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: _selectedColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black26, width: 1.5),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: 
                              // Hue gradient bar (0 to 360)
                              GradientColorSlider(
                                value: _hue / 360.0,
                                colors: const [
                                  Color(0xFFFF0000),
                                  Color(0xFFFFFF00),
                                  Color(0xFF00FF00),
                                  Color(0xFF00FFFF),
                                  Color(0xFF0000FF),
                                  Color(0xFFFF00FF),
                                  Color(0xFFFF0000),
                                ],
                                onChanged: (v) => setState(() => _hue = v * 360.0),
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Available Categories',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _categories.map((cat) {
                    return Chip(
                      label: Text(cat),
                      onDeleted: cat == 'Uncategorized'
                          ? null
                          : () async {
                              await widget.repository.deleteCategory(cat);
                              await _loadData();
                            },
                    );
                  }).toList(),
                ),
                const Divider(height: 32),
                const Text(
                  'Memorized Merchant Rules',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (_rules.isEmpty)
                  const Text(
                    'No rules yet. Click any transaction in "All Transactions" to assign a category and memorize it.',
                    style: TextStyle(color: Colors.grey),
                  )
                else
                  ..._rules.entries.map((entry) {
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.auto_awesome, size: 18),
                      title: Text(entry.key),
                      subtitle: Text('→ ${entry.value}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18),
                        onPressed: () async {
                          await widget.repository.deleteCategoryRule(entry.key);
                          await _loadData();
                        },
                      ),
                    );
                  }),
              ],
            ),
    );
  }
}
