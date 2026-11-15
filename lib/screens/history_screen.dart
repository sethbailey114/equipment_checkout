import 'package:flutter/material.dart';

import '../database/db_helper.dart';
import '../models/checkout.dart';
import '../widgets/checkout_card.dart';
import '../widgets/empty_state.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Checkout> _all = [];
  bool _loading = true;
  String _filter = 'All';

  static const List<String> _filters = ['All', 'Active', 'Returned', 'Overdue'];

  @override
  void initState() {
    super.initState();
    _load();
    DatabaseHelper.changes.addListener(_load);
  }

  @override
  void dispose() {
    DatabaseHelper.changes.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final data = await DatabaseHelper.getCheckouts();
    if (!mounted) return;
    setState(() {
      _all = data;
      _loading = false;
    });
  }

  List<Checkout> get _filtered => _all.where((c) {
    switch (_filter) {
      case 'Active':
        return !c.isReturned && !c.isOverdue;
      case 'Returned':
        return c.isReturned;
      case 'Overdue':
        return c.isOverdue;
      default:
        return true;
    }
  }).toList();

  Widget _buildList() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_all.isEmpty) {
      return const EmptyState(
        icon: Icons.history,
        message: 'No checkout history yet.',
      );
    }
    final items = _filtered;
    if (items.isEmpty) {
      return EmptyState(
        icon: Icons.filter_alt_off,
        message: 'No ${_filter.toLowerCase()} checkouts found.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
      itemCount: items.length,
      itemBuilder: (context, index) => CheckoutCard(checkout: items[index]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout History')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                showSelectedIcon: false,
                segments: _filters
                    .map((f) => ButtonSegment<String>(value: f, label: Text(f)))
                    .toList(),
                selected: {_filter},
                onSelectionChanged: (s) => setState(() => _filter = s.first),
              ),
            ),
          ),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }
}
