import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../models/summary.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txState = ref.watch(transactionNotifierProvider);
    final filtered = ref.watch(filteredTransactionsProvider);
    final filter = ref.watch(filterProvider);
    final summaryAsync = ref.watch(summaryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Anie Finance Tracker'),
        centerTitle: false,
        elevation: 0,
      ),
      body: RefreshIndicator(
        // Pull-to-refresh re-fetches from the API
        onRefresh: () =>
            ref.read(transactionNotifierProvider.notifier).loadTransactions(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── Summary bar ──────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: summaryAsync.when(
                data: (s) => _SummaryBar(summary: s),
                loading: () => _SummaryBar(summary: Summary.empty()),
                error: (_, __) => _SummaryErrorBanner(
                  onRetry: () => ref.invalidate(summaryProvider),
                ),
              ),
            ),

            // ── Filter chips ─────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _FilterBar(
                selected: filter,
                onChanged: (f) => ref.read(filterProvider.notifier).state = f,
              ),
            ),

            // ── Content ──────────────────────────────────────────────────────
            if (txState.isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (txState.error != null)
              SliverFillRemaining(
                child: _ErrorView(
                  message: txState.error!,
                  onRetry: () => ref
                      .read(transactionNotifierProvider.notifier)
                      .loadTransactions(),
                ),
              )
            else if (filtered.isEmpty)
              const SliverFillRemaining(child: _EmptyView())
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _TransactionTile(
                    transaction: filtered[i],
                    onTap: () =>
                        ctx.push('/transactions/${filtered[i].id}'),
                  ),
                  childCount: filtered.length,
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add'),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
    );
  }
}

// ─── Summary Bar ──────────────────────────────────────────────────────────────

class _SummaryBar extends StatelessWidget {
  final Summary summary;
  const _SummaryBar({required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.78),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.31),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Net Balance',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: 13,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            fmt.format(summary.netBalance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _SummaryChip(
                  label: 'Income',
                  value: fmt.format(summary.totalIncome),
                  icon: Icons.arrow_upward_rounded,
                  color: Colors.greenAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryChip(
                  label: 'Expenses',
                  value: fmt.format(summary.totalExpenses),
                  icon: Icons.arrow_downward_rounded,
                  color: Colors.redAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.20),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.71),
                  fontSize: 11,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Summary Error Banner ─────────────────────────────────────────────────────

class _SummaryErrorBanner extends StatelessWidget {
  final VoidCallback onRetry;

  const _SummaryErrorBanner({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        border: Border.all(color: Colors.orange.shade200),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Could not load summary',
              style: TextStyle(color: Colors.orange.shade800),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

// ─── Filter Bar ───────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _FilterBar({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          _Chip(label: 'All', value: 'all', selected: selected, onTap: onChanged),
          const SizedBox(width: 8),
          _Chip(label: 'Income', value: 'income', selected: selected, onTap: onChanged),
          const SizedBox(width: 8),
          _Chip(label: 'Expense', value: 'expense', selected: selected, onTap: onChanged),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final String value;
  final String selected;
  final ValueChanged<String> onTap;

  const _Chip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(value),
      showCheckmark: false,
    );
  }
}

// ─── Transaction List Tile ────────────────────────────────────────────────────

class _TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback onTap;

  const _TransactionTile({required this.transaction, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isIncome = transaction.type == 'income';
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final date = DateTime.tryParse(transaction.date);
    final dateStr =
        date != null ? DateFormat('MMM d, y').format(date) : transaction.date;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: (isIncome ? Colors.green : Colors.red).withValues(alpha: 0.12),
        child: Icon(
          isIncome ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
          color: isIncome ? Colors.green : Colors.red,
          size: 20,
        ),
      ),
      title: Text(
        transaction.title,
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${transaction.category} • $dateStr',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
        ),
      ),
      trailing: Text(
        '${isIncome ? '+' : '-'}${fmt.format(transaction.amount)}',
        style: theme.textTheme.bodyLarge?.copyWith(
          color: isIncome ? Colors.green : Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ─── Empty / Error states ─────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No transactions yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to add your first one',
            style: TextStyle(color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded, size: 72, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Could not load transactions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
