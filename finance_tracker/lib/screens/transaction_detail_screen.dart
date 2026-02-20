import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../models/transaction.dart';
import '../providers/transaction_provider.dart';

class TransactionDetailScreen extends ConsumerWidget {
  final String transactionId;

  const TransactionDetailScreen({super.key, required this.transactionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txState = ref.watch(transactionNotifierProvider);

    // Look up the transaction in already-loaded state — avoids an extra API
    // call. If we navigated here from the list, it's always present.
    final transaction = txState.transactions
        .where((t) => t.id == transactionId)
        .firstOrNull;

    if (txState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (transaction == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off_rounded,
                  size: 72, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              const Text('Transaction not found'),
              const SizedBox(height: 16),
              FilledButton(
                  onPressed: () => context.go('/'),
                  child: const Text('Back to Home')),
            ],
          ),
        ),
      );
    }

    return _DetailView(transaction: transaction);
  }
}

// ─── Detail view ──────────────────────────────────────────────────────────────

class _DetailView extends ConsumerWidget {
  final Transaction transaction;

  const _DetailView({required this.transaction});

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: Text(
          'Delete "${transaction.title}"?\nThis cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final error = await ref
        .read(transactionNotifierProvider.notifier)
        .deleteTransaction(transaction.id);

    if (!context.mounted) return;

    if (error == null) {
      context.go('/');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction deleted')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isIncome = transaction.type == 'income';
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final date = DateTime.tryParse(transaction.date);
    final dateStr = date != null
        ? DateFormat('MMMM d, y').format(date)
        : transaction.date;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Details'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: 'Delete',
            onPressed: () => _delete(context, ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Amount hero card ─────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isIncome
                      ? [Colors.green.shade700, Colors.green.shade400]
                      : [Colors.red.shade700, Colors.red.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white.withValues(alpha: 0.16),
                    child: Icon(
                      isIncome
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${isIncome ? '+' : '-'}${fmt.format(transaction.amount)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    transaction.type.toUpperCase(),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.78),
                      letterSpacing: 2,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Detail rows ──────────────────────────────────────────────────
            _DetailCard(
              children: [
                _DetailRow(icon: Icons.title, label: 'Title', value: transaction.title),
                _DetailRow(icon: Icons.category_outlined, label: 'Category', value: transaction.category),
                _DetailRow(icon: Icons.calendar_today_outlined, label: 'Date', value: dateStr),
                if (transaction.note != null && transaction.note!.isNotEmpty)
                  _DetailRow(icon: Icons.notes_outlined, label: 'Note', value: transaction.note!),
              ],
            ),

            const SizedBox(height: 32),

            // ── Delete button ────────────────────────────────────────────────
            OutlinedButton.icon(
              onPressed: () => _delete(context, ref),
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              label: const Text(
                'Delete Transaction',
                style: TextStyle(color: Colors.red, fontSize: 15),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ─── Detail card + row ────────────────────────────────────────────────────────

class _DetailCard extends StatelessWidget {
  final List<Widget> children;

  const _DetailCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.24)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: _insertDividers(children),
        ),
      ),
    );
  }

  List<Widget> _insertDividers(List<Widget> items) {
    final result = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      result.add(items[i]);
      if (i < items.length - 1) result.add(const Divider(height: 1));
    }
    return result;
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(height: 2),
                Text(value, style: theme.textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
