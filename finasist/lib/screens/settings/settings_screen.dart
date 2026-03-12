import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/settings_provider.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import 'manage_categories_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // Özelleştirme Bölümü
          _buildSectionTitle('Özelleştirme'),
          _buildSettingsGroup([
            _buildSettingsItem(
              context: context,
              icon: CupertinoIcons.square_on_circle,
              iconBgColor: Colors.purple.shade900,
              iconColor: Colors.purpleAccent,
              title: 'Kategoriler',
              subtitle: 'Kategorileri yönet',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ManageCategoriesScreen()),
              ),
            ),
            _buildSettingsItem(
              context: context,
              icon: CupertinoIcons.money_dollar_circle,
              iconBgColor: Colors.teal.shade900,
              iconColor: Colors.tealAccent,
              title: 'Ana Para Birimi',
              subtitle: 'Şu anki: ${settingsProvider.currency}',
              onTap: () async {
                final String? newCurrency = await showDialog<String>(
                  context: context,
                  builder: (BuildContext context) => SimpleDialog(
                    title: const Text('Para Birimi Seç'),
                    backgroundColor: AppTheme.cardColor,
                    children: <Widget>[
                      SimpleDialogOption(
                        onPressed: () { Navigator.pop(context, 'TRY'); },
                        child: const Text('Türk Lirası (TRY)', style: TextStyle(color: Colors.white)),
                      ),
                      SimpleDialogOption(
                        onPressed: () { Navigator.pop(context, 'USD'); },
                        child: const Text('Amerikan Doları (USD)', style: TextStyle(color: Colors.white)),
                      ),
                      SimpleDialogOption(
                        onPressed: () { Navigator.pop(context, 'EUR'); },
                        child: const Text('Euro (EUR)', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
                if (newCurrency != null) {
                  settingsProvider.setCurrency(newCurrency);
                }
              },
            ),
            _buildSettingsItem(
              context: context,
              icon: CupertinoIcons.paintbrush,
              iconBgColor: Colors.brown.shade900,
              iconColor: Colors.orangeAccent,
              title: 'Tema & Renk',
              subtitle: settingsProvider.themeMode == ThemeMode.dark
                  ? '🌙 Koyu Tema'
                  : settingsProvider.themeMode == ThemeMode.light
                      ? '☀️ Aydınlık Tema'
                      : '⚙️ Sistem',
              isLast: true,
              onTap: () async {
                final picked = await showDialog<ThemeMode>(
                  context: context,
                  builder: (ctx) => SimpleDialog(
                    title: const Text('Tema Seç'),
                    backgroundColor: AppTheme.cardColor,
                    children: <Widget>[
                      SimpleDialogOption(
                        onPressed: () => Navigator.pop(ctx, ThemeMode.dark),
                        child: Row(children: [
                          const Text('🌙 Koyu Tema', style: TextStyle(color: Colors.white)),
                          const Spacer(),
                          if (settingsProvider.themeMode == ThemeMode.dark)
                            const Icon(CupertinoIcons.checkmark_alt, color: AppTheme.primaryPurple, size: 18),
                        ]),
                      ),
                      SimpleDialogOption(
                        onPressed: () => Navigator.pop(ctx, ThemeMode.light),
                        child: Row(children: [
                          const Text('☀️ Aydınlık Tema', style: TextStyle(color: Colors.white)),
                          const Spacer(),
                          if (settingsProvider.themeMode == ThemeMode.light)
                            const Icon(CupertinoIcons.checkmark_alt, color: AppTheme.primaryPurple, size: 18),
                        ]),
                      ),
                      SimpleDialogOption(
                        onPressed: () => Navigator.pop(ctx, ThemeMode.system),
                        child: Row(children: [
                          const Text('⚙️ Sistem', style: TextStyle(color: Colors.white)),
                          const Spacer(),
                          if (settingsProvider.themeMode == ThemeMode.system)
                            const Icon(CupertinoIcons.checkmark_alt, color: AppTheme.primaryPurple, size: 18),
                        ]),
                      ),
                    ],
                  ),
                );
                if (picked != null) {
                  settingsProvider.setThemeMode(picked);
                }
              },
            ),
          ]),

          // Çıkış Yap Butonu
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: AppTheme.cardColor,
                      title: const Text('Çıkış Yap', style: TextStyle(color: Colors.white)),
                      content: const Text('Hesabınızdan çıkmak istediğinize emin misiniz?', style: TextStyle(color: AppTheme.textSecondary)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('İptal'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Çıkış Yap', style: TextStyle(color: AppTheme.expenseRed, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true && context.mounted) {
                    await context.read<AuthProvider>().logout();
                    if (!context.mounted) return;
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                },
                icon: const Icon(CupertinoIcons.square_arrow_left, color: Colors.white),
                label: const Text('Çıkış Yap', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.expenseRed,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSettingsItem({
    required BuildContext context,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? trailingWidget,
    bool isLast = false,
    VoidCallback? onTap,
  }) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          ),
          trailing: trailingWidget ?? const Icon(CupertinoIcons.chevron_right, color: AppTheme.textSecondary, size: 18),
          onTap: onTap ?? () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$title özelliği yakında eklenecektir!')),
            );
          },
        ),
        if (!isLast)
          Divider(
            color: Colors.white.withOpacity(0.05),
            height: 1,
            indent: 64, // Çizgi ikonun solundan değil de yazının hizasından başlıyor
          ),
      ],
    );
  }
}
