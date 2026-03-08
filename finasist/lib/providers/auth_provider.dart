import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;
  String? get error => _error;

  /// Uygulama açılışında token varsa kullanıcıyı yükler.
  Future<bool> tryAutoLogin() async {
    if (!await ApiService.hasToken()) return false;
    try {
      final data = await ApiService.getMe();
      _user = User.fromJson(data);
      notifyListeners();
      return true;
    } catch (_) {
      await ApiService.clearToken();
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await ApiService.login(email: email, password: password);
      final data = await ApiService.getMe();
      _user = User.fromJson(data);
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Sunucuya bağlanılamadı. Lütfen tekrar deneyin.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String fullName, String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await ApiService.register(
        fullName: fullName,
        email: email,
        password: password,
      );
      return await login(email, password);
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Sunucuya bağlanılamadı. Lütfen tekrar deneyin.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await ApiService.clearToken();
    _user = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
