class Summary {
  final double totalIncome;
  final double totalExpenses;
  final double netBalance;

  const Summary({
    required this.totalIncome,
    required this.totalExpenses,
    required this.netBalance,
  });

  factory Summary.fromJson(Map<String, dynamic> json) {
    return Summary(
      totalIncome: (json['totalIncome'] as num).toDouble(),
      totalExpenses: (json['totalExpenses'] as num).toDouble(),
      netBalance: (json['netBalance'] as num).toDouble(),
    );
  }

  // Used while the real fetch is loading
  factory Summary.empty() {
    return const Summary(totalIncome: 0, totalExpenses: 0, netBalance: 0);
  }
}
