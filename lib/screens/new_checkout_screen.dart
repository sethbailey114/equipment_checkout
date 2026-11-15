import 'package:flutter/material.dart';

import '../database/db_helper.dart';
import '../models/borrower.dart';
import '../models/equipment.dart';
import '../utils/helpers.dart';
import '../widgets/empty_state.dart';

class NewCheckoutScreen extends StatefulWidget {
  const NewCheckoutScreen({super.key});

  @override
  State<NewCheckoutScreen> createState() => _NewCheckoutScreenState();
}

class _NewCheckoutScreenState extends State<NewCheckoutScreen> {
  final _formKey = GlobalKey<FormState>();

  List<Borrower> _borrowers = [];
  List<Equipment> _available = [];
  bool _loading = true;

  int? _borrowerId;
  int? _equipmentId;
  DateTime _checkoutDate = dateOnly(DateTime.now());
  late DateTime _dueDate = _checkoutDate.add(const Duration(days: 7));

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final borrowers = await DatabaseHelper.getBorrowers();
    final available = await DatabaseHelper.getAvailableEquipment();
    if (!mounted) return;
    setState(() {
      _borrowers = borrowers;
      _available = available;
      _loading = false;
    });
  }

  Future<void> _pickCheckoutDate() async {
    final today = dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _checkoutDate,
      firstDate: today.subtract(const Duration(days: 365)),
      lastDate: today,
    );
    if (picked == null) return;
    setState(() {
      _checkoutDate = picked;
      if (!_dueDate.isAfter(_checkoutDate)) {
        _dueDate = _checkoutDate.add(const Duration(days: 7));
      }
    });
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: _checkoutDate.add(const Duration(days: 1)),
      lastDate: _checkoutDate.add(const Duration(days: 730)),
    );
    if (picked == null) return;
    setState(() => _dueDate = picked);
  }

  Future<void> _confirm() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_dueDate.isAfter(_checkoutDate)) {
      showMessage(
        context,
        'The due date must be later than the checkout date.',
        isError: true,
      );
      return;
    }

    try {
      await DatabaseHelper.createCheckout(
        equipmentId: _equipmentId!,
        borrowerId: _borrowerId!,
        checkoutDate: formatDate(_checkoutDate),
        dueDate: formatDate(_dueDate),
      );
      if (!mounted) return;
      showMessage(context, 'Checkout recorded.');
      Navigator.pop(context);
    } on DbException catch (e) {
      if (mounted) showMessage(context, e.message, isError: true);
    }
  }

  Widget _dateTile(String label, DateTime date, VoidCallback onTap) {
    return ListTile(
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(4),
      ),
      leading: const Icon(Icons.event),
      title: Text(label),
      subtitle: Text(formatDate(date)),
      trailing: const Icon(Icons.edit_calendar),
      onTap: onTap,
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_borrowers.isEmpty) {
      return const EmptyState(
        icon: Icons.people_outline,
        message: 'Register a borrower before creating a checkout.',
      );
    }
    if (_available.isEmpty) {
      return const EmptyState(
        icon: Icons.devices_other,
        message: 'No equipment is currently available for checkout.',
      );
    }

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<int>(
            initialValue: _borrowerId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Borrower'),
            items: _borrowers
                .map(
                  (b) => DropdownMenuItem<int>(
                    value: b.id!,
                    child: Text(
                      '${b.name} (${b.department})',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            validator: (v) => v == null ? 'Select a borrower' : null,
            onChanged: (v) => setState(() => _borrowerId = v),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            initialValue: _equipmentId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Available equipment'),
            items: _available
                .map(
                  (e) => DropdownMenuItem<int>(
                    value: e.id!,
                    child: Text(
                      '${e.name} (${e.category})',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            validator: (v) => v == null ? 'Select an equipment item' : null,
            onChanged: (v) => setState(() => _equipmentId = v),
          ),
          const SizedBox(height: 16),
          _dateTile('Checkout date', _checkoutDate, _pickCheckoutDate),
          const SizedBox(height: 16),
          _dateTile('Due date', _dueDate, _pickDueDate),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _confirm,
            icon: const Icon(Icons.check),
            label: const Text('Confirm Checkout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Checkout')),
      body: _buildBody(),
    );
  }
}
