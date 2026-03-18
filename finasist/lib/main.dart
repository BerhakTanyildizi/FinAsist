import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'screens/main_layout.dart';
import 'screens/auth/login_screen.dart';
import 'providers/transaction_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/auth_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: const FinasistApp(),
    ),
  );
}

class FinasistApp extends StatelessWidget {
  const FinasistApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    final lightWithFont = AppTheme.lightTheme.copyWith(
      textTheme: GoogleFonts.interTextTheme(AppTheme.lightTheme.textTheme),
    );
    final darkWithFont = AppTheme.darkTheme.copyWith(
      textTheme: GoogleFonts.interTextTheme(
        AppTheme.darkTheme.textTheme.apply(
          bodyColor: AppTheme.textPrimary,
          displayColor: AppTheme.textPrimary,
        ),
      ),
    );

    return MaterialApp(
      title: 'FinAsist',
      debugShowCheckedModeBanner: false,
      theme: lightWithFont,
      darkTheme: darkWithFont,
      themeMode: settings.themeMode,
      home: const AuthWrapper(),
    );
  }
}

/// Uygulama açılışında token kontrolü yapar ve yönlendirir
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final auth = context.read<AuthProvider>();
    // AuthProvider constructor'ında _checkAuthStatus() zaten çağrılıyor,
    // isLoggedIn true ise veri de yüklüyoruz
    if (auth.isLoggedIn) {
      await context.read<TransactionProvider>().loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // Token kontrolü bitene kadar loading göster
    if (auth.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryPurple),
        ),
      );
    }

    // Token varsa → Ana Sayfa, yoksa → Login
    return auth.isLoggedIn ? const MainLayoutScreen() : const LoginScreen();
  }
}
