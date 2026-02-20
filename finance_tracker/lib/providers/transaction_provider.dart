import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction.dart';
import '../models/summary.dart';
import '../services/api_service.dart';

// ─── Service provider ─────────────────────────────────────────────────────────

final apiServiceProvider = Provider<ApiService>((_) => ApiService());

// ─── Filter state ─────────────────────────────────────────────────────────────

// Simple string: 'all' | 'income' | 'expense'
final filterProvider = StateProvider<String>((_) => 'all');

// ─── Transaction state model ──────────────────────────────────────────────────

class TransactionState {
  final List<Transaction> transactions;
  final bool isLoading;
  final String? error; // null means no error

  const TransactionState({
    this.transactions = const [],
    this.isLoading = false,
    this.error,
  });

  TransactionState copyWith({
    List<Transaction>? transactions,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return TransactionState(
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ─── StateNotifier ────────────────────────────────────────────────────────────

class TransactionNotifier extends StateNotifier<TransactionState> {
  final ApiService _api;
  final Ref _ref;

  TransactionNotifier(this._api, this._ref)
      : super(const TransactionState(isLoading: true)) {
    loadTransactions();
  }

  // Fetch all transactions from the API and sort newest-first
  Future<void> loadTransactions() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final list = await _api.getTransactions();
      // Backend already sorts but we sort locally too for safety
      list.sort((a, b) => b.date.compareTo(a.date));
      state = TransactionState(transactions: list, isLoading: false);
      // Keep summary in sync
      _ref.invalidate(summaryProvider);
    } catch (e) {
      state = TransactionState(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Returns null on success, or an error message on failure.
  Future<String?> addTransaction(Map<String, dynamic> data) async {
    try {
      final created = await _api.createTransaction(data);
      final updated = [created, ...state.transactions];
      updated.sort((a, b) => b.date.compareTo(a.date));
      state = state.copyWith(transactions: updated);
      _ref.invalidate(summaryProvider);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // Returns null on success, or an error message on failure.
  Future<String?> deleteTransaction(String id) async {
    try {
      await _api.deleteTransaction(id);
      state = state.copyWith(
        transactions: state.transactions.where((t) => t.id != id).toList(),
      );
      _ref.invalidate(summaryProvider);
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────

final transactionNotifierProvider =
    StateNotifierProvider<TransactionNotifier, TransactionState>((ref) {
  return TransactionNotifier(ref.watch(apiServiceProvider), ref);
});

// Derived provider — filters the list without a new API call
final filteredTransactionsProvider = Provider<List<Transaction>>((ref) {
  final txState = ref.watch(transactionNotifierProvider);
  final filter = ref.watch(filterProvider);

  if (filter == 'all') return txState.transactions;
  return txState.transactions.where((t) => t.type == filter).toList();
});

// Summary is fetched independently from its own endpoint.
// Invalidated whenever transactions change (add / delete).
final summaryProvider = FutureProvider<Summary>((ref) {
  return ref.watch(apiServiceProvider).getSummary();
});
