import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  bool _isAppLocked = false;
  bool _useTraditionalCalendar = true;
  String _currency = 'TRY';
  ThemeMode _themeMode = ThemeMode.dark; // Varsayılan: Karanlık tema
  String? _appPin;

  bool get isAppLocked => _isAppLocked;
  bool get useTraditionalCalendar => _useTraditionalCalendar;
  String get currency => _currency;
  ThemeMode get themeMode => _themeMode;
  bool get hasPin => _appPin != null && _appPin!.isNotEmpty;

  // Para birimi sembolü: TRY → ₺, USD → $, EUR → €
  String get currencySymbol {
    switch (_currency) {
      case 'USD': return '\$';
      case 'EUR': return '€';
      default: return '₺';
    }
  }

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isAppLocked = prefs.getBool('isAppLocked') ?? false;
    _useTraditionalCalendar = prefs.getBool('useTraditionalCalendar') ?? true;
    _currency = prefs.getString('currency') ?? 'TRY';
    _appPin = prefs.getString('appPin');
    
    // Tema: 'dark', 'light', 'system'
    final themeStr = prefs.getString('themeMode') ?? 'dark';
    if (themeStr == 'light') {
      _themeMode = ThemeMode.light;
    } else if (themeStr == 'system') {
      _themeMode = ThemeMode.system;
    } else {
      _themeMode = ThemeMode.dark;
    }
    
    notifyListeners();
  }

  Future<void> toggleAppLock(bool value) async {
    _isAppLocked = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isAppLocked', value);
    if (!value) {
      _appPin = null;
      await prefs.remove('appPin');
    }
    notifyListeners();
  }

  /// 4 haneli uygulama kilidi PIN'ini ayarlar/günceller.
  Future<void> setAppPin(String pin) async {
    _appPin = pin;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('appPin', pin);
    notifyListeners();
  }

  bool verifyAppPin(String pin) => _appPin != null && _appPin == pin;

  Future<void> setTraditionalCalendar(bool value) async {
    _useTraditionalCalendar = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('useTraditionalCalendar', value);
    notifyListeners();
  }

  Future<void> setCurrency(String newCurrency) async {
    _currency = newCurrency;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency', newCurrency);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    String themeStr = 'dark';
    if (mode == ThemeMode.light) themeStr = 'light';
    if (mode == ThemeMode.system) themeStr = 'system';
    await prefs.setString('themeMode', themeStr);
    notifyListeners();
  }
}
