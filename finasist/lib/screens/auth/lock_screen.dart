import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/settings_provider.dart';
import '../../providers/auth_provider.dart';
import 'login_screen.dart';

/// Uygulama açılışında "Uygulama Kilidi" açıksa gösterilen 4 haneli PIN ekranı.
class LockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;
  const LockScreen({super.key, required this.onUnlocked});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  String _input = '';
  String? _error;

  void _onDigit(String digit) {
    if (_input.length >= 4) return;
    setState(() {
      _input += digit;
      _error = null;
    });
    if (_input.length == 4) _verify();
  }

  void _onBackspace() {
    if (_input.isEmpty) return;
    setState(() => _input = _input.substring(0, _input.length - 1));
  }

  void _verify() {
    final settings = context.read<SettingsProvider>();
    if (settings.verifyAppPin(_input)) {
      widget.onUnlocked();
    } else {
      setState(() {
        _error = 'Yanlış PIN, tekrar deneyin.';
        _input = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundOf(context),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primaryPurple.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(CupertinoIcons.lock_fill, color: AppTheme.primaryPurple, size: 36),
              ),
              const SizedBox(height: 24),
              Text(
                'Uygulama Kilitli',
                style: TextStyle(color: AppTheme.textPrimaryOf(context), fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Devam etmek için 4 haneli PIN\'inizi girin',
                style: TextStyle(color: AppTheme.textSecondaryOf(context), fontSize: 13),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) {
                  final filled = i < _input.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled ? AppTheme.primaryPurple : Colors.transparent,
                      border: Border.all(color: AppTheme.primaryPurple, width: 1.5),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 20,
                child: Text(
                  _error ?? '',
                  style: const TextStyle(color: AppTheme.expenseRed, fontSize: 12),
                ),
              ),
              const Spacer(),
              _buildKeypad(context),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () async {
                  await context.read<AuthProvider>().logout();
                  if (!context.mounted) return;
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
                child: Text(
                  'PIN\'imi unuttum, çıkış yap',
                  style: TextStyle(color: AppTheme.textSecondaryOf(context), fontSize: 13),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad(BuildContext context) {
    const keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', '⌫'];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: keys.map((k) {
        if (k.isEmpty) return const SizedBox.shrink();
        return GestureDetector(
          onTap: () => k == '⌫' ? _onBackspace() : _onDigit(k),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.cardColorOf(context),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: k == '⌫'
                ? Icon(CupertinoIcons.delete_left, color: AppTheme.textPrimaryOf(context), size: 20)
                : Text(k, style: TextStyle(color: AppTheme.textPrimaryOf(context), fontSize: 20, fontWeight: FontWeight.w600)),
          ),
        );
      }).toList(),
    );
  }
}
