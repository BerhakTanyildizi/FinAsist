import 'package:flutter/material.dart';
import '../services/api_service.dart';

class TransactionProvider extends ChangeNotifier {
  List<dynamic> _transactions = [];
  List<dynamic> _categories = [];
  double _totalBalance = 0.0;
  bool _isLoading = false;

  List<dynamic> get transactions => _transactions;
  List<dynamic> get categories => _categories;
  double get totalBalance => _totalBalance;
  bool get isLoading => _isLoading;

  // Tüm verileri baştan çeker ve hesaplar
  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners(); // Yükleniyor durumunu UI'a bildir

    try {
      _transactions = await ApiService.getTransactions();
      _categories = await ApiService.getCategories();
      _calculateTotalBalance();
    } catch (e) {
      debugPrint("TransactionProvider Load Error: $e");
    } finally {
      _isLoading = false;
      notifyListeners(); // Veri geldi, ekranları güncelle
    }
  }

  // Yeni işlem eklendiğinde API'ye atar ve listeyi günceller
  Future<bool> addTransaction({
    required int categoryId,
    required double amount,
    required String type,
    String? merchant,
    String? description,
    required String transactionDate,
  }) async {
    _isLoading = true;
    notifyListeners();

    bool success = await ApiService.addTransaction(
      categoryId: categoryId,
      amount: amount,
      type: type,
      merchant: merchant,
      description: description,
      transactionDate: transactionDate,
    );

    if (success) {
      // Başarılıysa verileri tekrar çekerek tüm uygulamamızın güncellenmesini sağla
      await loadData();
    } else {
      _isLoading = false;
      notifyListeners();
    }

    return success;
  }

  // Yeni düzenli işlem (taksit/maaş) eklendiğinde API'ye atar ve listeyi günceller
  Future<bool> addRecurringTransaction({
    required int categoryId,
    required double amount,
    required String type,
    required String frequency,
    required String startDate,
    String? endDate,
    String? description,
  }) async {
    _isLoading = true;
    notifyListeners();

    bool success = await ApiService.addRecurringTransaction(
      categoryId: categoryId,
      amount: amount,
      type: type,
      frequency: frequency,
      startDate: startDate,
      endDate: endDate,
      description: description,
    );

    if (success) {
      await loadData();
    } else {
      _isLoading = false;
      notifyListeners();
    }

    return success;
  }

  Future<bool> updateTransaction({
    required int transactionId,
    int? categoryId,
    double? amount,
    String? type,
    String? merchant,
    String? description,
    String? transactionDate,
  }) async {
    _isLoading = true;
    notifyListeners();

    bool success = await ApiService.updateTransaction(
      transactionId: transactionId,
      categoryId: categoryId,
      amount: amount,
      type: type,
      merchant: merchant,
      description: description,
      transactionDate: transactionDate,
    );

    if (success) {
      await loadData();
    } else {
      _isLoading = false;
      notifyListeners();
    }

    return success;
  }

  Future<bool> deleteTransaction(int transactionId) async {
    // Silme işleminden önce UI'ı anında güncelle ki Dismissible (Kaydırma ile silme) widget'ı hata vermesin
    int index = _transactions.indexWhere((tx) => tx['id'] == transactionId);
    var backup;
    if (index != -1) {
      backup = _transactions[index];
      _transactions.removeAt(index);
      _calculateTotalBalance();
      notifyListeners(); // UI anında güncellenir ve widget ağacından çöp kutusu atılır
    }

    _isLoading = true;
    notifyListeners();

    bool success = await ApiService.deleteTransaction(transactionId);

    if (success) {
      await loadData(); // Arka planda tam liste onayı
    } else {
      // Başarısız olursa listeye geri al
      if (backup != null) {
        _transactions.insert(index, backup);
        _transactions.sort((a, b) => (b['transaction_date'] ?? '').compareTo(a['transaction_date'] ?? ''));
        _calculateTotalBalance();
      }
      _isLoading = false;
      notifyListeners();
    }

    return success;
  }

  // Kullanıcıya özel yeni bir kategori oluşturur
  Future<bool> createCategory({
    required String name,
    required String type,
    String? iconName,
  }) async {
    final result = await ApiService.createCategory(
      name: name,
      type: type,
      iconName: iconName,
    );
    if (result != null) {
      await loadData();
      return true;
    }
    return false;
  }

  // Kullanıcıya özel bir kategoriyi siler
  Future<bool> deleteCategory(int categoryId) async {
    final success = await ApiService.deleteCategory(categoryId);
    if (success) {
      await loadData();
    }
    return success;
  }

  // Sadece eldeki verilerden bakiyeyi hesaplar (API yapmaz)
  void _calculateTotalBalance() {
    double balance = 0.0;
    for (var tx in _transactions) {
      double amount = double.parse(tx['amount'].toString());
      if (tx['type'] == 'income') {
        balance += amount;
      } else if (tx['type'] == 'expense') {
        balance -= amount;
      }
    }
    _totalBalance = balance;
  }
}
