import 'category.dart';

class Transaction {
  final int id;
  final int userId;
  final int categoryId;
  final double amount;
  final String type;
  final String? merchant;
  final String? description;
  final DateTime transactionDate;
  final DateTime createdAt;
  final Category category;

  const Transaction({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.amount,
    required this.type,
    this.merchant,
    this.description,
    required this.transactionDate,
    required this.createdAt,
    required this.category,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      userId: json['user_id'],
      categoryId: json['category_id'],
      amount: double.parse(json['amount'].toString()),
      type: json['type'],
      merchant: json['merchant'],
      description: json['description'],
      transactionDate: DateTime.parse(json['transaction_date']),
      createdAt: DateTime.parse(json['created_at']),
      category: Category.fromJson(json['category']),
    );
  }

  bool get isExpense => type == 'expense';
  bool get isIncome => type == 'income';

  String get formattedAmount {
    final prefix = isIncome ? '+' : '-';
    final parts = amount.toStringAsFixed(2).split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return '$prefix\u20BA $intPart,${parts[1]}';
  }
}
