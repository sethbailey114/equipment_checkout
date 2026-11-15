import '../utils/helpers.dart';

class Checkout {
  final int? id;
  final int equipmentId;
  final int borrowerId;
  final String checkoutDate;
  final String dueDate;
  final String? returnDate;
  final String status; // 'Active' or 'Returned'

  // Joined from the equipment and borrowers tables (never duplicated in storage).
  final String equipmentName;
  final String borrowerName;

  const Checkout({
    this.id,
    required this.equipmentId,
    required this.borrowerId,
    required this.checkoutDate,
    required this.dueDate,
    this.returnDate,
    this.status = 'Active',
    this.equipmentName = '',
    this.borrowerName = '',
  });

  factory Checkout.fromMap(Map<String, dynamic> map) => Checkout(
        id: map['id'] as int?,
        equipmentId: map['equipment_id'] as int,
        borrowerId: map['borrower_id'] as int,
        checkoutDate: map['checkout_date'] as String,
        dueDate: map['due_date'] as String,
        returnDate: map['return_date'] as String?,
        status: map['status'] as String,
        equipmentName: (map['equipment_name'] as String?) ?? '',
        borrowerName: (map['borrower_name'] as String?) ?? '',
      );

  bool get isReturned => status == 'Returned';

  /// Not returned and the due date is earlier than today.
  bool get isOverdue => !isReturned && dueDate.compareTo(todayString()) < 0;

  /// 'Active', 'Overdue', or 'Returned'.
  String get statusLabel =>
      isReturned ? 'Returned' : (isOverdue ? 'Overdue' : 'Active');
}