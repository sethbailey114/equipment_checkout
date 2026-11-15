import 'package:flutter/material.dart';

import '../database/db_helper.dart';
import '../models/borrower.dart';
import '../models/checkout.dart';
import '../widgets/checkout_card.dart';
import 'borrower_form_screen.dart';

class BorrowerDetailScreen extends StatefulWidget {
  final int borrowerId;

  const BorrowerDetailScreen({super.key, required this.borrowerId});

  @override
  State<BorrowerDetailScreen> createState() => _BorrowerDetailScreenState();
}

class _BorrowerDetailScreenState extends State<BorrowerDetailScreen> {
  Borrower? _borrower;
  List<Checkout> _checkouts = [];

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
    final borrower = await DatabaseHelper.getBorrower(widget.borrowerId);
    final checkouts = await DatabaseHelper.getBorrowerCheckouts(
      widget.borrowerId,
    );
    if (!mounted) return;
    setState(() {
      _borrower = borrower;
      _checkouts = checkouts;
    });
  }

  Widget _header(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 8),
    child: Text(
      text,
      style: Theme.of(context).textTheme.titleMedium
          ?.copyWith(fontWeight: FontWeight.bold),
    ),
  );

  Widget _emptyNote(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(text, style: TextStyle(color: Colors.grey.shade600)),
  );

  @override
  Widget build(BuildContext context) {
    final borrower = _borrower;
    final current = _checkouts.where((c) => !c.isReturned).toList();
    final previous = _checkouts.where((c) => c.isReturned).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(borrower?.name ?? 'Borrower'),
        actions: [
          if (borrower != null)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Edit borrower',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BorrowerFormScreen(borrower: borrower),
                ),
              ),
            ),
        ],
      ),
      body: borrower == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Contact Information',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.person_outline, size: 18),
                            const SizedBox(width: 8),
                            Text(borrower.name),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.email_outlined, size: 18),
                            const SizedBox(width: 8),
                            Expanded(child: Text(borrower.email)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.apartment, size: 18),
                            const SizedBox(width: 8),
                            Text(borrower.department),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                _header(context, 'Currently Borrowed (${current.length})'),
                if (current.isEmpty)
                  _emptyNote('No equipment currently checked out.')
                else
                  ...current.map(
                    (c) => CheckoutCard(checkout: c, showBorrower: false),
                  ),
                _header(context, 'Previous Checkouts (${previous.length})'),
                if (previous.isEmpty)
                  _emptyNote('No previous checkout transactions.')
                else
                  ...previous.map(
                    (c) => CheckoutCard(checkout: c, showBorrower: false),
                  ),
              ],
            ),
    );
  }
}
