import 'package:flutter/material.dart';

class StatusChip extends StatelessWidget {
  final String label;

  const StatusChip(this.label, {super.key});

  Color get _color => switch (label) {
        'Available' => Colors.green.shade700,
        'Checked Out' => Colors.orange.shade800,
        'Active' => Colors.blue.shade700,
        'Returned' => Colors.teal.shade700,
        'Overdue' => Colors.red.shade700,
        _ => Colors.grey.shade700,
      };

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}