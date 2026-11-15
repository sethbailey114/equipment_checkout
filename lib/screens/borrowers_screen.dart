import 'package:flutter/material.dart';

import '../database/db_helper.dart';
import '../models/borrower.dart';
import '../utils/helpers.dart';
import '../widgets/empty_state.dart';
import 'borrower_detail_screen.dart';
import 'borrower_form_screen.dart';

class BorrowersScreen extends StatefulWidget {
  const BorrowersScreen({super.key});

  @override
  State<BorrowersScreen> createState() => _BorrowersScreenState();
}

class _BorrowersScreenState extends State<BorrowersScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Borrower> _all = [];
  bool _loading = true;

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
    final data = await DatabaseHelper.getBorrowers();
    if (!mounted) return;
    setState(() {
      _all = data;
      _loading = false;
    });
  }

  List<Borrower> get _filtered {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _all;
    return _all
        .where(
          (b) =>
              b.name.toLowerCase().contains(query) ||
              b.email.toLowerCase().contains(query) ||
              b.department.toLowerCase().contains(query),
        )
        .toList();
  }

  void _openForm([Borrower? borrower]) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BorrowerFormScreen(borrower: borrower)),
    );
  }

  void _openDetail(Borrower borrower) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BorrowerDetailScreen(borrowerId: borrower.id!),
      ),
    );
  }

  Future<void> _delete(Borrower b) async {
    if (b.historyCount > 0) {
      showMessage(
        context,
        '${b.name} has checkout history and cannot be deleted.',
        isError: true,
      );
      return;
    }
    final ok = await confirmDialog(
      context,
      title: 'Delete borrower?',
      message: 'Delete ${b.name}? This cannot be undone.',
      confirmLabel: 'Delete',
    );
    if (!ok) return;
    try {
      await DatabaseHelper.deleteBorrower(b.id!);
      if (mounted) showMessage(context, 'Borrower deleted.');
    } on DbException catch (ex) {
      if (mounted) showMessage(context, ex.message, isError: true);
    }
  }

  String _checkedOutText(int count) =>
      '$count item${count == 1 ? '' : 's'} checked out';

  Widget _buildList() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_all.isEmpty) {
      return const EmptyState(
        icon: Icons.people_outline,
        message:
            'No registered borrowers.\nTap "Add Borrower" to register one.',
      );
    }
    final items = _filtered;
    if (items.isEmpty) {
      return const EmptyState(
        icon: Icons.search_off,
        message: 'No borrowers match your search.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 88),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final b = items[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              child: Text(b.name.isEmpty ? '?' : b.name[0].toUpperCase()),
            ),
            title: Text(
              b.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${b.department}\n${_checkedOutText(b.activeCount)}',
            ),
            isThreeLine: true,
            trailing: PopupMenuButton<String>(
              onSelected: (value) =>
                  value == 'edit' ? _openForm(b) : _delete(b),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
            onTap: () => _openDetail(b),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Borrowers')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.person_add),
        label: const Text('Add Borrower'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search by name, email, or department',
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
          Expanded(child: _buildList()),
        ],
      ),
    );
  }
}
