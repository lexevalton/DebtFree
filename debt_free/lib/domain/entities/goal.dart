enum GoalType {
  saving,
  restriction;

  static GoalType fromStorageKey(String key) {
    return key == 'restriction' ? GoalType.restriction : GoalType.saving;
  }
}

class Goal {
  final String id;
  final String name;
  final GoalType type;
  final double targetAmount;
  final double allocatedAmount; // Manual/virtual surplus allocated to a saving goal
  final String? categoryName;   // Required when type == GoalType.restriction
  final String notes;

  const Goal({
    required this.id,
    required this.name,
    required this.type,
    required this.targetAmount,
    this.allocatedAmount = 0.0,
    this.categoryName,
    this.notes = '',
  });
}
