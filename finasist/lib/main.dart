import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'screens/main_layout.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/lock_screen.dart';
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
  bool _dataLoaded = false;
  bool _isUnlocked = false;

  @override
  void initState() {
    super.initState();
    _tryAutoLogin();
  }

  Future<void> _tryAutoLogin() async {
    final auth = context.read<AuthProvider>();
    final loggedIn = await auth.tryAutoLogin();
    if (loggedIn && mounted) {
      await context.read<TransactionProvider>().loadData();
      _dataLoaded = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final settings = context.watch<SettingsProvider>();

    if (auth.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryPurple),
        ),
      );
    }

    if (auth.isLoggedIn && !_dataLoaded) {
      _dataLoaded = true;
      Future.microtask(() => context.read<TransactionProvider>().loadData());
    }

    if (!auth.isLoggedIn) {
      _dataLoaded = false;
      _isUnlocked = false;
    }

    if (auth.isLoggedIn && settings.isAppLocked && settings.hasPin && !_isUnlocked) {
      return LockScreen(onUnlocked: () => setState(() => _isUnlocked = true));
    }

    return auth.isLoggedIn ? const MainLayoutScreen() : const LoginScreen();
  }
}
