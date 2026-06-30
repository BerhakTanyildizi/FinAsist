import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/settings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../services/pdf_report_service.dart';
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
          _buildSectionTitle(context, 'Özelleştirme'),
          _buildSettingsGroup(context, [
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
                  builder: (BuildContext dialogContext) => SimpleDialog(
                    title: const Text('Para Birimi Seç'),
                    backgroundColor: AppTheme.cardColorOf(dialogContext),
                    children: <Widget>[
                      SimpleDialogOption(
                        onPressed: () { Navigator.pop(dialogContext, 'TRY'); },
                        child: Text('Türk Lirası (TRY)', style: TextStyle(color: AppTheme.textPrimaryOf(dialogContext))),
                      ),
                      SimpleDialogOption(
                        onPressed: () { Navigator.pop(dialogContext, 'USD'); },
                        child: Text('Amerikan Doları (USD)', style: TextStyle(color: AppTheme.textPrimaryOf(dialogContext))),
                      ),
                      SimpleDialogOption(
                        onPressed: () { Navigator.pop(dialogContext, 'EUR'); },
                        child: Text('Euro (EUR)', style: TextStyle(color: AppTheme.textPrimaryOf(dialogContext))),
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
                    backgroundColor: AppTheme.cardColorOf(ctx),
                    children: <Widget>[
                      SimpleDialogOption(
                        onPressed: () => Navigator.pop(ctx, ThemeMode.dark),
                        child: Row(children: [
                          Text('🌙 Koyu Tema', style: TextStyle(color: AppTheme.textPrimaryOf(ctx))),
                          const Spacer(),
                          if (settingsProvider.themeMode == ThemeMode.dark)
                            const Icon(CupertinoIcons.checkmark_alt, color: AppTheme.primaryPurple, size: 18),
                        ]),
                      ),
                      SimpleDialogOption(
                        onPressed: () => Navigator.pop(ctx, ThemeMode.light),
                        child: Row(children: [
                          Text('☀️ Aydınlık Tema', style: TextStyle(color: AppTheme.textPrimaryOf(ctx))),
                          const Spacer(),
                          if (settingsProvider.themeMode == ThemeMode.light)
                            const Icon(CupertinoIcons.checkmark_alt, color: AppTheme.primaryPurple, size: 18),
                        ]),
                      ),
                      SimpleDialogOption(
                        onPressed: () => Navigator.pop(ctx, ThemeMode.system),
                        child: Row(children: [
                          Text('⚙️ Sistem', style: TextStyle(color: AppTheme.textPrimaryOf(ctx))),
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

          const SizedBox(height: 24),
          _buildSectionTitle(context, 'Güvenlik ve Veri'),
          _buildSettingsGroup(context, [
            _buildSettingsItem(
              context: context,
              icon: CupertinoIcons.lock,
              iconBgColor: Colors.indigo.shade900,
              iconColor: Colors.indigoAccent,
              title: 'Uygulama Kilidi',
              subtitle: settingsProvider.isAppLocked
                  ? 'Açık — 4 haneli PIN ile korunuyor'
                  : 'Kapalı',
              trailingWidget: Switch(
                value: settingsProvider.isAppLocked,
                activeThumbColor: AppTheme.primaryPurple,
                onChanged: (value) async {
                  if (value) {
                    await _setupAppLock(context, settingsProvider);
                  } else {
                    await settingsProvider.toggleAppLock(false);
                  }
                },
              ),
              onTap: () async {
                if (settingsProvider.isAppLocked) {
                  await _setupAppLock(context, settingsProvider, isChangingPin: true);
                } else {
                  await _setupAppLock(context, settingsProvider);
                }
              },
            ),
            _buildSettingsItem(
              context: context,
              icon: CupertinoIcons.arrow_down_doc_fill,
              iconBgColor: Colors.green.shade900,
              iconColor: Colors.greenAccent,
              title: 'Verilerimi Dışa Aktar',
              subtitle: 'Tüm işlemlerini PDF olarak indir',
              onTap: () async {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PDF hazırlanıyor...')),
                );
                try {
                  final txProvider = context.read<TransactionProvider>();
                  final auth = context.read<AuthProvider>();
                  await PdfReportService.generateAndShare(
                    transactions: txProvider.transactions,
                    currencySymbol: settingsProvider.currencySymbol,
                    userName: auth.user?.fullName ?? 'Finasist Kullanıcısı',
                    days: null, // tüm zamanlar
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Dışa aktarılamadı: $e')),
                  );
                }
              },
            ),
            _buildSettingsItem(
              context: context,
              icon: CupertinoIcons.info,
              iconBgColor: Colors.blueGrey.shade900,
              iconColor: Colors.blueGrey.shade100,
              title: 'Hakkında',
              subtitle: 'Sürüm 1.0.0 — TÜBİTAK 2209-A',
              isLast: true,
              onTap: () => showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppTheme.cardColorOf(ctx),
                  title: Text('Finasist Hakkında', style: TextStyle(color: AppTheme.textPrimaryOf(ctx))),
                  content: Text(
                    'Finasist, TÜBİTAK 2209-A Üniversite Öğrencileri Araştırma Projeleri '
                    'Destek Programı kapsamında geliştirilen yapay zeka destekli kişisel '
                    'finans yönetimi uygulamasıdır.\n\nSürüm: 1.0.0',
                    style: TextStyle(color: AppTheme.textSecondaryOf(ctx), fontSize: 13, height: 1.5),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Kapat', style: TextStyle(color: AppTheme.primaryPurple)),
                    ),
                  ],
                ),
              ),
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
                      backgroundColor: AppTheme.cardColorOf(ctx),
                      title: Text('Çıkış Yap', style: TextStyle(color: AppTheme.textPrimaryOf(ctx))),
                      content: Text('Hesabınızdan çıkmak istediğinize emin misiniz?', style: TextStyle(color: AppTheme.textSecondaryOf(ctx))),
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
                // Bu buton her zaman kırmızı arkaplanlıdır (tema fark etmez),
                // bu yüzden üzerindeki metin/ikon sabit beyaz kalmalı.
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

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppTheme.textSecondaryOf(context),
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(BuildContext context, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColorOf(context),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
          title: Text(title, style: TextStyle(color: AppTheme.textPrimaryOf(context), fontWeight: FontWeight.w600, fontSize: 15)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(subtitle, style: TextStyle(color: AppTheme.textSecondaryOf(context), fontSize: 13)),
          ),
          trailing: trailingWidget ?? Icon(CupertinoIcons.chevron_right, color: AppTheme.textSecondaryOf(context), size: 18),
          onTap: onTap ?? () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$title özelliği yakında eklenecektir!')),
            );
          },
        ),
        if (!isLast)
          Divider(
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
            height: 1,
            indent: 64, // Çizgi ikonun solundan değil de yazının hizasından başlıyor
          ),
      ],
    );
  }
}

/// Uygulama kilidi için 4 haneli PIN belirleme/değiştirme diyaloğu.
/// Başarılı kurulumda PIN kaydedilir ve kilit otomatik olarak açılır (true) yapılır.
Future<void> _setupAppLock(
  BuildContext context,
  SettingsProvider settings, {
  bool isChangingPin = false,
}) async {
  final pin1Controller = TextEditingController();
  final pin2Controller = TextEditingController();
  String? error;

  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        final textColor = AppTheme.textPrimaryOf(ctx);
        final secondaryColor = AppTheme.textSecondaryOf(ctx);
        return AlertDialog(
          backgroundColor: AppTheme.cardColorOf(ctx),
          title: Text(
            isChangingPin ? 'PIN\'i Değiştir' : 'Uygulama Kilidi Kur',
            style: TextStyle(color: textColor),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: pin1Controller,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: 'Yeni 4 haneli PIN',
                  labelStyle: TextStyle(color: secondaryColor),
                  counterText: '',
                ),
              ),
              TextField(
                controller: pin2Controller,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: 'PIN\'i Onayla',
                  labelStyle: TextStyle(color: secondaryColor),
                  counterText: '',
                ),
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(error!, style: const TextStyle(color: AppTheme.expenseRed, fontSize: 12)),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () {
                final p1 = pin1Controller.text.trim();
                final p2 = pin2Controller.text.trim();
                if (p1.length != 4 || int.tryParse(p1) == null) {
                  setState(() => error = 'PIN tam olarak 4 rakam olmalı.');
                  return;
                }
                if (p1 != p2) {
                  setState(() => error = 'PIN\'ler eşleşmiyor.');
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: const Text('Kaydet', style: TextStyle(color: AppTheme.primaryPurple, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    ),
  );

  if (confirmed == true) {
    await settings.setAppPin(pin1Controller.text.trim());
    if (!settings.isAppLocked) {
      await settings.toggleAppLock(true);
    }
  }
}
