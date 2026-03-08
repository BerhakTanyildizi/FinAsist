import 'package:flutter/material.dart';

class Category {
  final int id;
  final String name;
  final String? iconName;
  final String type;

  const Category({
    required this.id,
    required this.name,
    this.iconName,
    required this.type,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      iconName: json['icon_name'],
      type: json['type'],
    );
  }

  bool get isExpense => type == 'expense';
  bool get isIncome => type == 'income';

  IconData get icon => _iconMap[iconName] ?? Icons.category;
  Color get color => _colorMap[iconName] ?? Colors.grey;

  static const _iconMap = <String, IconData>{
    'shopping_cart': Icons.shopping_cart,
    'receipt_long': Icons.receipt_long,
    'directions_car': Icons.directions_car,
    'movie': Icons.movie,
    'local_hospital': Icons.local_hospital,
    'school': Icons.school,
    'checkroom': Icons.checkroom,
    'more_horiz': Icons.more_horiz,
    'account_balance': Icons.account_balance,
    'laptop': Icons.laptop,
    'trending_up': Icons.trending_up,
    'card_giftcard': Icons.card_giftcard,
  };

  static const _colorMap = <String, Color>{
    'shopping_cart': Colors.orange,
    'receipt_long': Colors.blue,
    'directions_car': Colors.teal,
    'movie': Colors.purple,
    'local_hospital': Colors.red,
    'school': Colors.indigo,
    'checkroom': Colors.pink,
    'more_horiz': Colors.grey,
    'account_balance': Colors.green,
    'laptop': Colors.teal,
    'trending_up': Colors.blue,
    'card_giftcard': Colors.amber,
  };
}
