class Equipment {
  final int? id;
  final String name;
  final String category;
  final String condition;

  // Derived from checkout records (not stored in the equipment table).
  final bool isCheckedOut;
  final int checkoutCount;

  const Equipment({
    this.id,
    required this.name,
    required this.category,
    required this.condition,
    this.isCheckedOut = false,
    this.checkoutCount = 0,
  });

  factory Equipment.fromMap(Map<String, dynamic> map) => Equipment(
        id: map['id'] as int?,
        name: map['name'] as String,
        category: map['category'] as String,
        condition: map['condition'] as String,
        isCheckedOut: (map['is_checked_out'] as int? ?? 0) == 1,
        checkoutCount: map['checkout_count'] as int? ?? 0,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'category': category,
        'condition': condition,
      };
}