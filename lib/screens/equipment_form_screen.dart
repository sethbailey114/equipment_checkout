import 'package:flutter/material.dart';

import '../database/db_helper.dart';
import '../models/equipment.dart';
import '../utils/helpers.dart';
import '../widgets/status_chip.dart';

class EquipmentFormScreen extends StatefulWidget {
  final Equipment? equipment;

  const EquipmentFormScreen({super.key, this.equipment});

  @override
  State<EquipmentFormScreen> createState() => _EquipmentFormScreenState();
}

class _EquipmentFormScreenState extends State<EquipmentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late String _category;
  late String _condition;

  bool get _isEditing => widget.equipment != null;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.equipment?.name ?? '');
    _category = widget.equipment?.category ?? equipmentCategories.first;
    _condition = widget.equipment?.condition ?? 'Good';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final item = Equipment(
      id: widget.equipment?.id,
      name: _nameController.text.trim(),
      category: _category,
      condition: _condition,
    );

    try {
      if (_isEditing) {
        await DatabaseHelper.updateEquipment(item);
      } else {
        await DatabaseHelper.insertEquipment(item);
      }
      if (!mounted) return;
      showMessage(
        context,
        _isEditing ? 'Equipment updated.' : 'Equipment added.',
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
        title: Text(_isEditing ? 'Edit Equipment' : 'Add Equipment'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Equipment name'),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Equipment name is required'
                  : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: equipmentCategories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _condition,
              decoration: const InputDecoration(labelText: 'Condition'),
              items: equipmentConditions
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _condition = v!),
            ),
            if (_isEditing) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  const Text('Availability: '),
                  StatusChip(widget.equipment!.isCheckedOut
                      ? 'Checked Out'
                      : 'Available'),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Availability is set automatically from checkout records.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: Text(_isEditing ? 'Save Changes' : 'Add Equipment'),
            ),
          ],
        ),
      ),
    );
  }
}