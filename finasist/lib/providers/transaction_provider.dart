import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../services/api_service.dart';

class TransactionProvider with ChangeNotifier {
  List<Transaction> _transactions = [];
  bool _isLoading = false;
  String? _error;

  List<Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  double get totalIncome => _transactions
      .where((t) => t.isIncome)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get totalExpense => _transactions
      .where((t) => t.isExpense)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get balance => totalIncome - totalExpense;

  List<Transaction> get recentTransactions {
    final sorted = List<Transaction>.from(_transactions)
      ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
    return sorted.take(5).toList();
  }

  /// Kategori bazlı gider dağılımı (pie chart için)
  Map<String, double> get expenseByCategory {
    final map = <String, double>{};
    for (final t in _transactions.where((t) => t.isExpense)) {
      map[t.category.name] = (map[t.category.name] ?? 0) + t.amount;
    }
    return map;
  }

  Future<void> loadTransactions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await ApiService.getTransactions();
      _transactions = data.map((j) => Transaction.fromJson(j)).toList();
      _isLoading = false;
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Veriler yüklenemedi: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addTransaction({
    required int categoryId,
    required double amount,
    required String type,
    required String transactionDate,
    String? merchant,
    String? description,
  }) async {
    try {
      await ApiService.createTransaction(
        categoryId: categoryId,
        amount: amount,
        type: type,
        transactionDate: transactionDate,
        merchant: merchant,
        description: description,
      );
      await loadTransactions();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'İşlem kaydedilemedi.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateTransaction({
    required int id,
    int? categoryId,
    double? amount,
    String? type,
    String? transactionDate,
    String? merchant,
    String? description,
  }) async {
    try {
      await ApiService.updateTransaction(
        id: id,
        categoryId: categoryId,
        amount: amount,
        type: type,
        transactionDate: transactionDate,
        merchant: merchant,
        description: description,
      );
      await loadTransactions();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'İşlem güncellenemedi.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteTransaction(int id) async {
    try {
      await ApiService.deleteTransaction(id);
      _transactions.removeWhere((t) => t.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'İşlem silinemedi.';
      notifyListeners();
      return false;
    }
  }

  void clear() {
    _transactions = [];
    notifyListeners();
  }
}
