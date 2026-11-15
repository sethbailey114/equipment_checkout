import 'package:flutter/material.dart';

import '../models/checkout.dart';
import 'status_chip.dart';

class CheckoutCard extends StatelessWidget {
  final Checkout checkout;
  final bool showBorrower;
  final VoidCallback? onReturn;

  const CheckoutCard({
    super.key,
    required this.checkout,
    this.showBorrower = true,
    this.onReturn,
  });

  Widget _line(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Expanded(child: Text(text)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final c = checkout;
    return Card(
      shape: c.isOverdue
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.red.shade300, width: 1.5),
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    c.equipmentName,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                StatusChip(c.statusLabel),
              ],
            ),
            if (showBorrower) _line(Icons.person_outline, c.borrowerName),
            _line(Icons.event, 'Checked out: ${c.checkoutDate}'),
            _line(Icons.schedule, 'Due: ${c.dueDate}'),
            if (c.returnDate != null)
              _line(Icons.assignment_turned_in_outlined,
                  'Returned: ${c.returnDate}'),
            if (onReturn != null && !c.isReturned)
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: FilledButton.tonalIcon(
                    onPressed: onReturn,
                    icon: const Icon(Icons.assignment_return),
                    label: const Text('Mark Returned'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}