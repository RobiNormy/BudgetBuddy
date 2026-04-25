class Transactions {
  final double? amount;
  final String name;
  final String category;
  final DateTime date;

  Transactions({
    required this.name,
    required this.amount,
    required this.date,
    required this.category
  });
}
