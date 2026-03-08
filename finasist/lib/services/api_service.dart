import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String _baseUrl = 'http://localhost:8000';

  static String get baseUrl => _baseUrl;

  // ── Token yönetimi ──

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
  }

  static Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // ── HTTP yardımcıları ──

  static Map<String, String> _headers({String? token}) {
    final h = <String, String>{'Content-Type': 'application/json'};
    if (token != null) h['Authorization'] = 'Bearer $token';
    return h;
  }

  static Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    return _headers(token: token);
  }

  /// Yanıtı kontrol eder; hata varsa exception fırlatır.
  static dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(utf8.decode(response.bodyBytes));
    }

    String message;
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      message = body['detail'] ?? 'Bilinmeyen hata';
    } catch (_) {
      message = 'Sunucu hatası (${response.statusCode})';
    }
    throw ApiException(message, response.statusCode);
  }

  // ── Auth ──

  static Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/register'),
      headers: _headers(),
      body: jsonEncode({
        'full_name': fullName,
        'email': email,
        'password': password,
      }),
    );
    return _handleResponse(response);
  }

  static Future<String> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: _headers(),
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = _handleResponse(response);
    final token = data['access_token'] as String;
    await saveToken(token);
    return token;
  }

  static Future<Map<String, dynamic>> getMe() async {
    final headers = await _authHeaders();
    final response = await http.get(
      Uri.parse('$_baseUrl/auth/me'),
      headers: headers,
    );
    return _handleResponse(response);
  }

  // ── Transactions ──

  static Future<List<dynamic>> getTransactions() async {
    final headers = await _authHeaders();
    final response = await http.get(
      Uri.parse('$_baseUrl/transactions/'),
      headers: headers,
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> createTransaction({
    required int categoryId,
    required double amount,
    required String type,
    required String transactionDate,
    String? merchant,
    String? description,
  }) async {
    final headers = await _authHeaders();
    final body = <String, dynamic>{
      'category_id': categoryId,
      'amount': amount,
      'type': type,
      'transaction_date': transactionDate,
    };
    if (merchant != null && merchant.isNotEmpty) body['merchant'] = merchant;
    if (description != null && description.isNotEmpty) {
      body['description'] = description;
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/transactions/'),
      headers: headers,
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updateTransaction({
    required int id,
    int? categoryId,
    double? amount,
    String? type,
    String? transactionDate,
    String? merchant,
    String? description,
  }) async {
    final headers = await _authHeaders();
    final body = <String, dynamic>{};
    if (categoryId != null) body['category_id'] = categoryId;
    if (amount != null) body['amount'] = amount;
    if (type != null) body['type'] = type;
    if (transactionDate != null) body['transaction_date'] = transactionDate;
    if (merchant != null) body['merchant'] = merchant;
    if (description != null) body['description'] = description;

    final response = await http.put(
      Uri.parse('$_baseUrl/transactions/$id'),
      headers: headers,
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  static Future<void> deleteTransaction(int id) async {
    final headers = await _authHeaders();
    final response = await http.delete(
      Uri.parse('$_baseUrl/transactions/$id'),
      headers: headers,
    );
    _handleResponse(response);
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  const ApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}
