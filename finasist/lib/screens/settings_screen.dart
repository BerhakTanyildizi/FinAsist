import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/transaction_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profil & Ayarlar',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 16),
            CircleAvatar(
              radius: 50,
              backgroundColor: const Color(0xFF00B4D8).withValues(alpha: 0.25),
              child: const Icon(
                Icons.person,
                size: 60,
                color: Color(0xFF00B4D8),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user?.fullName ?? 'Kullanıcı',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              user?.email ?? '',
              style: TextStyle(color: isDark ? Colors.white54 : Colors.grey),
            ),
            const SizedBox(height: 32),
            _buildSettingsMenuItem(
              context,
              Icons.account_circle_outlined,
              'Hesap Bilgileri',
              onTap: () => _showInfoDialog(
                context,
                'Hesap Bilgileri',
                'Ad: ${user?.fullName ?? '-'}\nE-posta: ${user?.email ?? '-'}\nKayıt: ${user != null ? '${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}' : '-'}',
              ),
            ),
            _buildSettingsMenuItem(
              context,
              Icons.palette_outlined,
              'Görünüm ve Tema',
              onTap: () => _showThemeBottomSheet(context),
            ),
            _buildSettingsMenuItem(
              context,
              Icons.notifications_active_outlined,
              'Bildirimler',
              onTap: () => _showInfoDialog(
                context,
                'Bildirimler',
                'Harcama uyarıları ve yapay zeka tavsiyeleri için bildirim tercihlerinizi buradan yapılandırabilirsiniz.',
              ),
            ),
            _buildSettingsMenuItem(
              context,
              Icons.security_outlined,
              'Gizlilik ve Güvenlik',
              onTap: () => _showInfoDialog(
                context,
                'Gizlilik',
                'Finasist, verilerinizi uçtan uca şifreler. Gizlilik sözleşmemizi web sitemizden inceleyebilirsiniz.',
              ),
            ),
            Divider(
              height: 32,
              color: isDark ? Colors.white24 : Colors.grey.shade300,
            ),
            _buildSettingsMenuItem(
              context,
              Icons.help_outline,
              'Yardım ve Destek',
              onTap: () => _showInfoDialog(
                context,
                'Destek',
                'İletişim: destek@finasist.com\nTelefon: 0850 XXX XX XX',
              ),
            ),
            _buildSettingsMenuItem(
              context,
              Icons.logout,
              'Çıkış Yap',
              isDestructive: true,
              onTap: () => _showLogoutDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showInfoDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(color: Color(0xFF00B4D8))),
        content: Text(content),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Tamam',
              style: TextStyle(
                color: Color(0xFF00B4D8),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showThemeBottomSheet(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Görünümü Seçin',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00B4D8),
                ),
              ),
              const SizedBox(height: 16),
              _themeOption(ctx, themeProvider, ThemeMode.light, Icons.light_mode, Colors.orange, 'Açık Tema'),
              _themeOption(ctx, themeProvider, ThemeMode.dark, Icons.dark_mode, Colors.indigo, 'Karanlık Tema'),
              _themeOption(ctx, themeProvider, ThemeMode.system, Icons.settings_system_daydream, Colors.grey, 'Sistem Varsayılanı'),
            ],
          ),
        );
      },
    );
  }

  Widget _themeOption(
    BuildContext context,
    ThemeProvider tp,
    ThemeMode mode,
    IconData icon,
    Color iconColor,
    String label,
  ) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(label),
      trailing: tp.themeMode == mode ? const Icon(Icons.check, color: Colors.green) : null,
      onTap: () {
        tp.setThemeMode(mode);
        Navigator.pop(context);
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Çıkış Yap', style: TextStyle(color: Colors.red)),
        content: const Text('Hesabınızdan çıkış yapmak istediğinize emin misiniz?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final auth = context.read<AuthProvider>();
              final txProvider = context.read<TransactionProvider>();
              final router = GoRouter.of(context);
              Navigator.pop(ctx);
              await auth.logout();
              txProvider.clear();
              router.go('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Çıkış Yap', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsMenuItem(
    BuildContext context,
    IconData icon,
    String title, {
    bool isDestructive = false,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDestructive ? Colors.red : const Color(0xFF00B4D8);
    final bgColor = isDestructive
        ? Colors.red.withValues(alpha: 0.12)
        : const Color(0xFF00B4D8).withValues(alpha: isDark ? 0.15 : 0.1);

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: primaryColor),
      ),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w500, color: isDestructive ? Colors.red : null),
      ),
      trailing: Icon(Icons.chevron_right, color: isDark ? Colors.white38 : Colors.grey),
      onTap: onTap,
    );
  }
}
