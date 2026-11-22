import 'package:flutter/material.dart';
import '../../../domain/entities/goal.dart';

class GoalCreationCard extends StatefulWidget {
  final List<String> categories;
  final ValueChanged<Goal> onCreateGoal;

  const GoalCreationCard({
    super.key,
    required this.categories,
    required this.onCreateGoal,
  });

  @override
  State<GoalCreationCard> createState() => _GoalCreationCardState();
}

class _GoalCreationCardState extends State<GoalCreationCard> {
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  GoalType _type = GoalType.saving;
  String? _selectedCategory;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    final target = double.tryParse(_amountCtrl.text.trim().replaceAll(',', '.'));
    if (name.isEmpty || target == null || target <= 0) return;
    if (_type == GoalType.restriction && _selectedCategory == null) return;

    final goal = Goal(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      type: _type,
      targetAmount: target,
      categoryName: _type == GoalType.restriction ? _selectedCategory : null,
      notes: _notesCtrl.text.trim(),
    );

    widget.onCreateGoal(goal);
    _nameCtrl.clear();
    _amountCtrl.clear();
    _notesCtrl.clear();
    setState(() => _selectedCategory = null);
  }

  @override
  Widget build(BuildContext context) {
    final selectableCats = widget.categories.where((c) => c != 'Uncategorized').toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Create New Goal',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SegmentedButton<GoalType>(
              segments: const [
                ButtonSegment(
                  value: GoalType.saving,
                  icon: Icon(Icons.savings_outlined),
                  label: Text('Saving Target'),
                ),
                ButtonSegment(
                  value: GoalType.restriction,
                  icon: Icon(Icons.block),
                  label: Text('Spending Restriction'),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Goal Name (e.g., Vacations, Dining Limit)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Target Amount (\$)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            if (_type == GoalType.restriction) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category (Required)',
                  border: OutlineInputBorder(),
                ),
                items: selectableCats
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedCategory = val),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _notesCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Notes (shown on Dashboard hover)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.add),
                label: const Text('Add Goal'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
