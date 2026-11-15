import 'package:flutter/material.dart';

import '../database/db_helper.dart';
import '../models/equipment.dart';
import '../utils/helpers.dart';
import '../widgets/empty_state.dart';
import '../widgets/status_chip.dart';
import 'equipment_form_screen.dart';

class EquipmentScreen extends StatefulWidget {
  const EquipmentScreen({super.key});

  @override
  State<EquipmentScreen> createState() => _EquipmentScreenState();
}

class _EquipmentScreenState extends State<EquipmentScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Equipment> _all = [];
  bool _loading = true;
  String _category = 'All';
  String _availability = 'All';

  @override
  void initState() {
    super.initState();
    _load();
    DatabaseHelper.changes.addListener(_load);
  }

  @override
  void dispose() {
    DatabaseHelper.changes.removeListener(_load);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final data = await DatabaseHelper.getEquipment();
    if (!mounted) return;
    setState(() {
      _all = data;
      _loading = false;
    });
  }

  List<Equipment> get _filtered {
    final query = _searchController.text.trim().toLowerCase();
    return _all.where((e) {
      if (query.isNotEmpty && !e.name.toLowerCase().contains(query)) {
        return false;
      }
      if (_category != 'All' && e.category != _category) return false;
      if (_availability == 'Available' && e.isCheckedOut) return false;
      if (_availability == 'Checked Out' && !e.isCheckedOut) return false;
      return true;
    }).toList();
  }

  void _openForm([Equipment? equipment]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EquipmentFormScreen(equipment: equipment),
      ),
    );
  }

  Future<void> _delete(Equipment e) async {
    if (e.checkoutCount > 0) {
      showMessage(
        context,
        '"${e.name}" has checkout history and cannot be deleted.',
        isError: true,
      );
      return;
    }
    final ok = await confirmDialog(
      context,
      title: 'Delete equipment?',
      message: 'Delete "${e.name}"? This cannot be undone.',
      confirmLabel: 'Delete',
    );
    if (!ok) return;
    try {
      await DatabaseHelper.deleteEquipment(e.id!);
      if (mounted) showMessage(context, 'Equipment deleted.');
    } on DbException catch (ex) {
      if (mounted) showMessage(context, ex.message, isError: true);
    }
  }

  Widget _buildList() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_all.isEmpty) {
      return const EmptyState(
        icon: Icons.devices_other,
        message: 'No equipment yet.\nTap "Add Equipment" to get started.',
      );
    }
    final items = _filtered;
    if (items.isEmpty) {
      return const EmptyState(
        icon: Icons.search_off,
        message: 'No equipment matches your search or filters.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 88),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final e = items[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(child: Icon(categoryIcon(e.category))),
            title: Text(
              e.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('${e.category} • ${e.condition}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                StatusChip(e.isCheckedOut ? 'Checked Out' : 'Available'),
                PopupMenuButton<String>(
                  onSelected: (value) =>
                      value == 'edit' ? _openForm(e) : _delete(e),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
            onTap: () => _openForm(e),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Equipment')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add Equipment'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search equipment by name',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _category,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      isDense: true,
                    ),
                    items: ['All', ...equipmentCategories]
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => _category = v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _availability,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Availability',
                      isDense: true,
                    ),
                    items: const ['All', 'Available', 'Checked Out']
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => _availability = v!),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }
}