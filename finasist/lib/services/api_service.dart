import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// API hataları için özel Exception sınıfı
class ApiException implements Exception {
  final String message;
  const ApiException(this.message);
  @override
  String toString() => message;
}

class ApiService {
  // Bilgisayardan çalıştırılan Chrome Web sürümü için yerel IP (localhost)
  static const String baseUrl = 'http://127.0.0.1:8000';
  
  // Kullanıcı Girişi
  static Future<bool> login({required String email, required String password}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['access_token'];
        
        // Token'ı cihaza kaydet (SharedPrefs)
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        return true;
      }
      return false;
    } catch (e) {
      print('Login Exception: $e');
      return false;
    }
  }

  // Kullanıcı Kaydı
  static Future<bool> register({required String fullName, required String email, required String password}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'full_name': fullName,
          'email': email,
          'password': password,
        }),
      );

      return response.statusCode == 201;
    } catch (e) {
      print('Register Exception: $e');
      return false;
    }
  }

  // Çıkış Yap
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // İşlem oluşturma isteği
  static Future<bool> addTransaction({
    required int categoryId,
    required double amount,
    required String type,
    String? merchant,
    String? description,
    required String transactionDate,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');
      
      // Eğer token yoksa direkt başarısız dön (artık auto-login yok)
      if (token == null) {
        return false;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/transactions/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'category_id': categoryId,
          'amount': amount,
          'type': type,
          'merchant': merchant ?? '',
          'description': description ?? '',
          'transaction_date': transactionDate,
        }),
      );

      return response.statusCode == 201;
    } catch (e) {
      print('Add Transaction Exception: $e');
      return false;
    }
  }

  // İşlem silme isteği
  static Future<bool> deleteTransaction(int transactionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');
      
      if (token == null) return false;

      final response = await http.delete(
        Uri.parse('$baseUrl/transactions/$transactionId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // İşlem yoksa veya silindiyse 204 No Content veya 200 döner
      return response.statusCode == 204 || response.statusCode == 200;
    } catch (e) {
      print('Delete Transaction Exception: $e');
      return false;
    }
  }

  // Düzenli işlem oluşturma isteği
  static Future<bool> addRecurringTransaction({
    required int categoryId,
    required double amount,
    required String type,
    required String frequency,
    required String startDate,
    String? endDate,
    String? description,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');
      
      if (token == null) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/recurring/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'category_id': categoryId,
          'amount': amount,
          'type': type,
          'frequency': frequency,
          'start_date': startDate,
          'end_date': endDate,
          'description': description ?? '',
        }),
      );

      return response.statusCode == 201;
    } catch (e) {
      print('Add Recurring Exception: $e');
      return false;
    }
  }

  // İşlemleri listeleme ve getirme
  static Future<List<dynamic>> getTransactions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');
      
      if (token == null) {
        return [];
      }

      final response = await http.get(
        Uri.parse('$baseUrl/transactions/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // Gelen JSON string'i listeye çeviriyoruz (UTF8 decoding eklenebilir)
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
      return [];
    } catch (e) {
      print('Get Transactions Exception: $e');
      return [];
    }
  }

  // Kategorileri getirme
  static Future<List<dynamic>> getCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');
      
      if (token == null) {
        return [];
      }

      final response = await http.get(
        Uri.parse('$baseUrl/categories/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
      return [];
    } catch (e) {
      print('Get Categories Exception: $e');
      return [];
    }
  }

  // Yeni kategori oluşturma
  static Future<Map<String, dynamic>?> createCategory({
    required String name,
    required String type, // 'income' or 'expense'
    String? iconName,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');
      if (token == null) return null;

      final response = await http.post(
        Uri.parse('$baseUrl/categories/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': name,
          'type': type,
          'icon_name': iconName,
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
      return null;
    } catch (e) {
      print('Create Category Exception: $e');
      return null;
    }
  }

  // Kategori silme
  static Future<bool> deleteCategory(int categoryId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');
      if (token == null) return false;

      final response = await http.delete(
        Uri.parse('$baseUrl/categories/$categoryId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 204;
    } catch (e) {
      print('Delete Category Exception: $e');
      return false;
    }
  }

  // İşlemlerden yola çıkarak toplam bakiyeyi hesaplama
  static Future<double> getTotalBalance() async {
    List<dynamic> txs = await getTransactions();
    double balance = 0.0;
    
    for (var tx in txs) {
      double amount = double.parse(tx['amount'].toString());
      if (tx['type'] == 'income') {
        balance += amount;
      } else if (tx['type'] == 'expense') {
        balance -= amount;
      }
    }
    
    return balance;
  }

  // Token var mı kontrol eder
  static Future<bool> hasToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    return token != null && token.isNotEmpty;
  }

  // Token'ı siler (çıkış)
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // Mevcut kullanıcı bilgisini getirir
  static Future<Map<String, dynamic>> getMe() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) throw const ApiException('Token bulunamadı');

    final response = await http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    }
    throw ApiException('Kullanıcı bilgileri alınamadı (${response.statusCode})');
  }
}
