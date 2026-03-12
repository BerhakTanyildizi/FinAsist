import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; // iOS tarzı ikonlar için
import '../theme/app_theme.dart';
import 'settings/settings_screen.dart';
import 'home/home_screen.dart';
import 'add_transaction/add_transaction_screen.dart';
import 'reports/reports_screen.dart';
import 'ai_advisor/ai_advisor_screen.dart';

// İleride buraya gerçek sayfaları import edeceğiz
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        title,
        style: const TextStyle(fontSize: 24, color: AppTheme.textPrimary),
      ),
    );
  }
}

class MainLayoutScreen extends StatefulWidget {
  const MainLayoutScreen({super.key});

  static void changeTab(BuildContext context, int index) {
    final _MainLayoutScreenState? state = context.findAncestorStateOfType<_MainLayoutScreenState>();
    state?.changeTab(index);
  }

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  int _currentIndex = 0;

  void changeTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  // 5 Ana Sayfamızın Listesi
  final List<Widget> _screens = [
    const HomeScreen(), // Ana Sayfa (0)
    const AiAdvisorScreen(), // AI (1)
    const AddTransactionScreen(), // Ekle (2)
    const ReportsScreen(), // Raporlar (3)
    const SettingsScreen(), // Ayarlar (4)
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      
      // Kayan Buton (Floating Action Button) - İşlem Ekleme (+)
      floatingActionButton: FloatingActionButton(
        onPressed: () => changeTab(2),
        backgroundColor: AppTheme.cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.textSecondary, width: 0.5),
        ),
        child: const Icon(CupertinoIcons.add, color: AppTheme.textPrimary),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // Alt Gezinme Çubuğu (Bottom Navigation Bar)
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppTheme.cardColor, width: 2)),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              if (index != 2) changeTab(index);
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: AppTheme.backgroundDark,
            selectedItemColor: AppTheme.primaryPurple,
            unselectedItemColor: AppTheme.textSecondary,
            showSelectedLabels: false,
            showUnselectedLabels: false,
            items: [
              const BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.home),
                activeIcon: Icon(CupertinoIcons.house_fill, color: AppTheme.primaryPurple),
                label: 'Ana Sayfa',
              ),
              const BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.chat_bubble),
                activeIcon: Icon(CupertinoIcons.chat_bubble_fill, color: AppTheme.primaryPurple),
                label: 'AI',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.circle, color: Colors.transparent),
                label: '',
              ),
              const BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.chart_bar),
                activeIcon: Icon(CupertinoIcons.chart_bar_fill, color: AppTheme.primaryPurple),
                label: 'Rapor',
              ),
              const BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.settings),
                activeIcon: Icon(CupertinoIcons.settings_solid, color: AppTheme.primaryPurple),
                label: 'Ayarlar',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
