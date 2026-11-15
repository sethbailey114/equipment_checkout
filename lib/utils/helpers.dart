import 'package:flutter/material.dart';

const List<String> equipmentCategories = ['Laptop', 'Camera', 'Tablet', 'Other'];
const List<String> equipmentConditions = ['Excellent', 'Good', 'Fair', 'Damaged'];

/// Dates are stored as 'yyyy-MM-dd' so they compare correctly as strings.
String formatDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

String todayString() => formatDate(DateTime.now());

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

bool isValidEmail(String value) => RegExp(
      r'^[A-Za-z0-9._%+\-]+@[A-Za-z0-9\-]+(\.[A-Za-z0-9\-]+)+$',
    ).hasMatch(value.trim());

IconData categoryIcon(String category) => switch (category) {
      'Laptop' => Icons.laptop,
      'Camera' => Icons.photo_camera,
      'Tablet' => Icons.tablet_mac,
      _ => Icons.devices_other,
    };

void showMessage(BuildContext context, String message, {bool isError = false}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: TextStyle(color: isError ? Colors.white : null),
      ),
      backgroundColor: isError ? Colors.red.shade700 : null,
    ),
  );
}

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}