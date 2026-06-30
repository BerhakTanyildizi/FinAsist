import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; // iOS tarzı ikonlar için
import '../theme/app_theme.dart';
import 'settings/settings_screen.dart';
import 'home/home_screen.dart';
import 'add_transaction/add_transaction_screen.dart';
import 'reports/reports_screen.dart';
import 'ai_advisor/ai_advisor_screen.dart';
import 'scan/scan_receipt_screen.dart';

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

  // Sekmelerin Listesi. İndeks 2 (Evrak Tara) bir tab değil, push edilen bir
  // ekran olduğu için burada hiç gösterilmeyecek bir yer tutucudur.
  final List<Widget> _screens = [
    const HomeScreen(), // Ana Sayfa (0)
    const AiAdvisorScreen(), // AI (1)
    const SizedBox.shrink(), // Evrak Tara (2) — push ile açılır, tab değil
    const AddTransactionScreen(), // Ekle (3) — FAB hedefi
    const ReportsScreen(), // Raporlar (4)
    const SettingsScreen(), // Ayarlar (5)
  ];

  void _openScanScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ScanReceiptScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack: tüm sekmeler aynı anda mount edilmiş kalır, sadece
      // aktif olan gösterilir. Bu sayede sekme değiştirince AI sohbeti,
      // form girdileri vb. ekran state'i SİLİNMEZ (eski `_screens[index]`
      // yaklaşımı her geçişte State'i dispose edip sıfırdan oluşturuyordu).
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),

      // Kayan Buton (Floating Action Button) - İşlem Ekleme (+)
      floatingActionButton: FloatingActionButton(
        onPressed: () => changeTab(3),
        backgroundColor: AppTheme.cardColorOf(context),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppTheme.textSecondaryOf(context), width: 0.5),
        ),
        child: Icon(CupertinoIcons.add, color: AppTheme.textPrimaryOf(context)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // Alt Gezinme Çubuğu (Bottom Navigation Bar)
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: AppTheme.cardColorOf(context), width: 2)),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              if (index == 2) {
                _openScanScreen();
                return;
              }
              if (index != 3) changeTab(index);
            },
            type: BottomNavigationBarType.fixed,
            // backgroundColor/selectedItemColor/unselectedItemColor BİLEREK
            // verilmiyor — Theme'deki bottomNavigationBarTheme'den (app_theme.dart)
            // tema-duyarlı olarak miras alınır.
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
              const BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.doc_text_viewfinder),
                label: 'Tara',
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
