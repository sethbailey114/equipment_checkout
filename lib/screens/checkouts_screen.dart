import 'package:flutter/material.dart';

import '../database/db_helper.dart';
import '../models/checkout.dart';
import '../utils/helpers.dart';
import '../widgets/checkout_card.dart';
import '../widgets/empty_state.dart';
import 'new_checkout_screen.dart';

class CheckoutsScreen extends StatefulWidget {
  const CheckoutsScreen({super.key});

  @override
  State<CheckoutsScreen> createState() => _CheckoutsScreenState();
}

class _CheckoutsScreenState extends State<CheckoutsScreen> {
  List<Checkout> _active = [];
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
    super.dispose();
  }

  Future<void> _load() async {
    final data = await DatabaseHelper.getCheckouts(activeOnly: true);
    if (!mounted) return;
    setState(() {
      _active = data;
      _loading = false;
    });
  }

  Future<void> _return(Checkout c) async {
    final ok = await confirmDialog(
      context,
      title: 'Mark as returned?',
      message: '${c.equipmentName} returned by ${c.borrowerName}?',
      confirmLabel: 'Mark Returned',
    );
    if (!ok) return;
    try {
      await DatabaseHelper.returnCheckout(c.id!);
      if (mounted) showMessage(context, 'Equipment returned.');
    } on DbException catch (e) {
      if (mounted) showMessage(context, e.message, isError: true);
    }
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_active.isEmpty) {
      return const EmptyState(
        icon: Icons.assignment_outlined,
        message:
            'No active checkouts.\nTap "New Checkout" to assign equipment.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 88),
      itemCount: _active.length,
      itemBuilder: (context, index) {
        final c = _active[index];
        return CheckoutCard(checkout: c, onReturn: () => _return(c));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Active Checkouts')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NewCheckoutScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('New Checkout'),
      ),
      body: _buildBody(),
    );
  }
}
