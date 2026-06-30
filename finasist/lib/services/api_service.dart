import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;
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

  /// Backend'in 4xx/5xx yanıtlarındaki `detail` alanını okunabilir bir
  /// Türkçe mesaja çevirir. FastAPI/Pydantic doğrulama hataları (422)
  /// `detail: [{"loc": [...], "msg": "...", "type": "...", "ctx": {...}}]`
  /// formatında gelir; düz hatalar (400/401) `detail: "..."` formatındadır.
  static String _extractErrorMessage(http.Response response) {
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      final detail = body is Map ? body['detail'] : null;

      if (detail is String) return detail;

      if (detail is List && detail.isNotEmpty) {
        final first = detail.first;
        final loc = first['loc'];
        final fieldRaw = (loc is List && loc.isNotEmpty) ? loc.last.toString() : '';
        final field = _fieldNameTr(fieldRaw);
        final type = first['type']?.toString() ?? '';
        final ctx = first['ctx'];

        if (type == 'string_too_short' && ctx is Map && ctx['min_length'] != null) {
          return '$field en az ${ctx['min_length']} karakter olmalı.';
        }
        if (type == 'string_too_long' && ctx is Map && ctx['max_length'] != null) {
          return '$field en fazla ${ctx['max_length']} karakter olabilir.';
        }
        if (type.contains('email')) {
          return 'Geçerli bir e-posta adresi girin.';
        }
        final msg = first['msg']?.toString();
        return (msg != null && msg.isNotEmpty) ? '$field: $msg' : 'Girdiğiniz bilgiler geçersiz.';
      }
    } catch (_) {
      // JSON parse edilemedi, aşağıdaki genel mesaja düş
    }
    return 'Bir hata oluştu (${response.statusCode}).';
  }

  static String _fieldNameTr(String field) {
    switch (field) {
      case 'password': return 'Şifre';
      case 'email': return 'E-posta';
      case 'full_name': return 'Ad Soyad';
      default: return field.isEmpty ? 'Girdi' : field;
    }
  }

  // Kullanıcı Girişi — başarısızlıkta backend'in gerçek hata mesajıyla ApiException fırlatır.
  static Future<void> login({required String email, required String password}) async {
    final http.Response response;
    try {
      response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );
    } catch (e) {
      debugPrint('Login Exception: $e');
      throw const ApiException('Sunucuya bağlanılamadı. Lütfen tekrar deneyin.');
    }

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final token = data['access_token'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      return;
    }
    throw ApiException(_extractErrorMessage(response));
  }

  // Kullanıcı Kaydı — başarısızlıkta backend'in gerçek hata mesajıyla ApiException fırlatır.
  static Future<void> register({required String fullName, required String email, required String password}) async {
    final http.Response response;
    try {
      response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'full_name': fullName,
          'email': email,
          'password': password,
        }),
      );
    } catch (e) {
      debugPrint('Register Exception: $e');
      throw const ApiException('Sunucuya bağlanılamadı. Lütfen tekrar deneyin.');
    }

    if (response.statusCode == 201) return;
    throw ApiException(_extractErrorMessage(response));
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
      debugPrint('Add Transaction Exception: $e');
      return false;
    }
  }

  static Future<bool> updateTransaction({
    required int transactionId,
    int? categoryId,
    double? amount,
    String? type,
    String? merchant,
    String? description,
    String? transactionDate,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');
      if (token == null) return false;

      final body = <String, dynamic>{};
      if (categoryId != null) body['category_id'] = categoryId;
      if (amount != null) body['amount'] = amount;
      if (type != null) body['type'] = type;
      if (merchant != null) body['merchant'] = merchant;
      if (description != null) body['description'] = description;
      if (transactionDate != null) body['transaction_date'] = transactionDate;

      final response = await http.put(
        Uri.parse('$baseUrl/transactions/$transactionId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Update Transaction Exception: $e');
      return false;
    }
  }

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
      debugPrint('Delete Transaction Exception: $e');
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
      debugPrint('Add Recurring Exception: $e');
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
      debugPrint('Get Transactions Exception: $e');
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
      debugPrint('Get Categories Exception: $e');
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
      debugPrint('Create Category Exception: $e');
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
      debugPrint('Delete Category Exception: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>?> scanReceiptBase64(String base64Image) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');
      if (token == null) return null;

      final response = await http.post(
        Uri.parse('$baseUrl/scan/base64'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'image_base64': base64Image}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
      debugPrint('Scan Receipt Error: ${response.statusCode} - ${response.body}');
      return null;
    } catch (e) {
      debugPrint('Scan Receipt Exception: $e');
      return null;
    }
  }

  /// Multipart/form-data ile fiş görüntüsü yükler (dosya seçici için)
  static Future<Map<String, dynamic>?> scanReceiptFile(List<int> fileBytes, String fileName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');
      if (token == null) return null;

      final ext = fileName.split('.').last.toLowerCase();
      final mimeTypes = {
        'jpg': 'image/jpeg',
        'jpeg': 'image/jpeg',
        'png': 'image/png',
        'webp': 'image/webp',
      };
      final contentType = mimeTypes[ext] ?? 'image/jpeg';

      final uri = Uri.parse('$baseUrl/scan/upload');
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..files.add(http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: fileName,
          contentType: MediaType.parse(contentType),
        ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
      debugPrint('Scan File Error: ${response.statusCode} - ${response.body}');
      return null;
    } catch (e) {
      debugPrint('Scan File Exception: $e');
      return null;
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

  /// AI Finansal Danışman ile sohbet eder.
  /// history: [{'role': 'user'|'assistant', 'content': '...'}] (eskiden yeniye sıralı)
  static Future<String?> sendAdvisorMessage(
    String message,
    List<Map<String, String>> history,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');
      if (token == null) return null;

      final response = await http.post(
        Uri.parse('$baseUrl/advisor/chat'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'message': message,
          'history': history,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['reply'] as String?;
      }
      debugPrint('Advisor Chat Error: ${response.statusCode} - ${response.body}');
      return null;
    } catch (e) {
      debugPrint('Advisor Chat Exception: $e');
      return null;
    }
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
