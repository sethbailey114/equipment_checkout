class Borrower {
  final int? id;
  final String name;
  final String email;
  final String department;

  // Derived from checkout records.
  final int activeCount;
  final int historyCount;

  const Borrower({
    this.id,
    required this.name,
    required this.email,
    required this.department,
    this.activeCount = 0,
    this.historyCount = 0,
  });

  factory Borrower.fromMap(Map<String, dynamic> map) => Borrower(
        id: map['id'] as int?,
        name: map['name'] as String,
        email: map['email'] as String,
        department: map['department'] as String,
        activeCount: map['active_count'] as int? ?? 0,
        historyCount: map['history_count'] as int? ?? 0,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'department': department,
      };
}