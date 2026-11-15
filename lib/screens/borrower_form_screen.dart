import 'package:flutter/material.dart';

import '../database/db_helper.dart';
import '../models/borrower.dart';
import '../utils/helpers.dart';

class BorrowerFormScreen extends StatefulWidget {
  final Borrower? borrower;

  const BorrowerFormScreen({super.key, this.borrower});

  @override
  State<BorrowerFormScreen> createState() => _BorrowerFormScreenState();
}

class _BorrowerFormScreenState extends State<BorrowerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _departmentController;

  bool get _isEditing => widget.borrower != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.borrower?.name ?? '');
    _emailController = TextEditingController(
      text: widget.borrower?.email ?? '',
    );
    _departmentController = TextEditingController(
      text: widget.borrower?.department ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  String? _required(String? v, String label) =>
      (v == null || v.trim().isEmpty) ? '$label is required' : null;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final borrower = Borrower(
      id: widget.borrower?.id,
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      department: _departmentController.text.trim(),
    );

    try {
      if (_isEditing) {
        await DatabaseHelper.updateBorrower(borrower);
      } else {
        await DatabaseHelper.insertBorrower(borrower);
      }
      if (!mounted) return;
      showMessage(
        context,
        _isEditing ? 'Borrower updated.' : 'Borrower registered.',
      );
      Navigator.pop(context);
    } on DbException catch (e) {
      if (mounted) showMessage(context, e.message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Borrower' : 'Add Borrower'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Full name'),
              validator: (v) => _required(v, 'Full name'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email address'),
              validator: (v) {
                final required = _required(v, 'Email address');
                if (required != null) return required;
                return isValidEmail(v!) ? null : 'Enter a valid email address';
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _departmentController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Department'),
              validator: (v) => _required(v, 'Department'),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: Text(_isEditing ? 'Save Changes' : 'Register Borrower'),
            ),
          ],
        ),
      ),
    );
  }
}
