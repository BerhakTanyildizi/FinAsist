import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/settings_provider.dart';
import '../main_layout.dart';
import '../transactions/transactions_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Aktif filtre durumları
  String _selectedPeriod = 'Hafta'; // 'Gün', 'Hafta', 'Ay'
  final List<String> _selectedTypes = ['income', 'expense']; // 'income', 'expense'

  @override
  Widget build(BuildContext context) {
    // Tüm uygulama genelindeki provider'ı dinliyoruz
    final provider = context.watch<TransactionProvider>();
    
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(CupertinoIcons.settings, color: AppTheme.textSecondary),
          onPressed: () => MainLayoutScreen.changeTab(context, 4),
        ),
        title: const Text('Kişisel Muhasebe'),
      ),
      body: provider.isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryPurple))
        : RefreshIndicator(
            onRefresh: provider.loadData,
            color: AppTheme.primaryPurple,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Hesap Bakiye Kartı (Provider'dan gelen güncel bakiye verilecek)
                  _buildBalanceCard(provider.totalBalance, context.watch<SettingsProvider>().currencySymbol),
                  const SizedBox(height: 16),
                  
                  // Hızlı İşlemler Kartı
                  _buildQuickActionsCard(context),
                  const SizedBox(height: 16),
                  
                  // Trend Analizi Kartı
                  _buildTrendAnalysisCard(context, provider),
                  const SizedBox(height: 16),
                  
                  // Son İşlemler Kartı
                  _buildRecentTransactionsCard(context, provider.transactions),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildBalanceCard(double balance, String currencySymbol) {
    // Bakiyemizi formatlıyoruz
    String balanceString = balance.toStringAsFixed(2);
    List<String> parts = balanceString.split('.');
    String integerPart = parts[0];
    String decimalPart = parts.length > 1 ? parts[1] : '00';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Hesaplarım', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
              Icon(CupertinoIcons.chevron_right, color: AppTheme.textSecondary, size: 18),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Genel', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(currencySymbol, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              Text(integerPart, style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold, height: 1.0)),
              Text(',$decimalPart', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Text('Son Güncelleme: ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          const SizedBox(height: 16),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.brown.shade800,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.brown.shade900,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.flash_on, color: AppTheme.textSecondary, size: 16),
              ),
              const SizedBox(width: 12),
              const Text('Hızlı İşlemler', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildQuickActionItem(
                icon: CupertinoIcons.doc_text_viewfinder,
                color: AppTheme.incomeGreen,
                bgColor: AppTheme.incomeGreen.withOpacity(0.1),
                label: 'Evrak Tara',
                isAi: true,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Evrak tarama özelliği yakında eklenecek!')));
                },
              ),
              _buildQuickActionItem(
                icon: CupertinoIcons.chat_bubble_2,
                color: Colors.brown.shade300,
                bgColor: Colors.brown.shade900.withOpacity(0.5),
                label: 'AI Finansal\nDanışman',
                isAi: true,
                onTap: () => MainLayoutScreen.changeTab(context, 1),
              ),
              _buildQuickActionItem(
                icon: CupertinoIcons.add,
                color: AppTheme.starYellow,
                bgColor: AppTheme.starYellow.withOpacity(0.1),
                label: 'Gelir/Gider Ekle',
                isAi: false,
                onTap: () => MainLayoutScreen.changeTab(context, 2),
              ),
              _buildQuickActionItem(
                icon: CupertinoIcons.chart_pie,
                color: Colors.blueAccent,
                bgColor: Colors.blueAccent.withOpacity(0.1),
                label: 'Finansal\nRaporlar',
                isAi: false,
                onTap: () => MainLayoutScreen.changeTab(context, 3),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionItem({
    required IconData icon,
    required Color color,
    required Color bgColor,
    required String label,
    required bool isAi,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topRight,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: color.withOpacity(0.3), width: 1),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                if (isAi)
                  Positioned(
                    top: -6,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.cardColor,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(CupertinoIcons.sparkles, color: Colors.white, size: 8),
                          SizedBox(width: 2),
                          Text('AI', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, height: 1.2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendAnalysisCard(BuildContext context, TransactionProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(CupertinoIcons.chart_bar_alt_fill, color: Colors.brown, size: 20),
              const SizedBox(width: 8),
              const Text('Trend Analizi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 16),
          // Toggle Buttons Row
          Row(
            children: [
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() => _selectedPeriod = 'Gün'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: _selectedPeriod == 'Gün' ? Colors.brown.shade900.withOpacity(0.5) : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('Gün', style: TextStyle(color: _selectedPeriod == 'Gün' ? Colors.white : AppTheme.textSecondary, fontSize: 13)),
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () => setState(() => _selectedPeriod = 'Hafta'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: _selectedPeriod == 'Hafta' ? Colors.brown.shade900.withOpacity(0.5) : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('Hafta', style: TextStyle(color: _selectedPeriod == 'Hafta' ? Colors.white : AppTheme.textSecondary, fontSize: 13)),
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () => setState(() => _selectedPeriod = 'Ay'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: _selectedPeriod == 'Ay' ? Colors.brown.shade900.withOpacity(0.5) : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('Ay', style: TextStyle(color: _selectedPeriod == 'Ay' ? Colors.white : AppTheme.textSecondary, fontSize: 13)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Filter Chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFilterChip(context, 'Gelir', 'income', AppTheme.incomeGreen, _selectedTypes.contains('income')),
              _buildFilterChip(context, 'Gider', 'expense', AppTheme.expenseRed, _selectedTypes.contains('expense')),
            ],
          ),
          const SizedBox(height: 32),
          // Grafik alanı (fl_chart)
          SizedBox(
            height: 120,
            width: double.infinity,
            child: provider.transactions.isEmpty
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundDark.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    alignment: Alignment.center,
                    child: const Text('Henüz veri yok', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  )
                : LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: FlTitlesData(
                        show: true,
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 22,
                            interval: _selectedPeriod == 'Gün' ? 4 : (_selectedPeriod == 'Hafta' ? 1 : 5),
                            getTitlesWidget: (value, meta) {
                              String text = '';
                              int val = value.toInt();
                              if (_selectedPeriod == 'Gün') {
                                text = '${val.toString().padLeft(2, '0')}:00';
                              } else if (_selectedPeriod == 'Hafta') {
                                DateTime date = DateTime.now().subtract(Duration(days: 6 - val));
                                text = '${date.day}/${date.month}';
                              } else if (_selectedPeriod == 'Ay') {
                                DateTime date = DateTime.now().subtract(Duration(days: 29 - val));
                                text = '${date.day}/${date.month}';
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(text, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: _generateLineBars(provider.transactions),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, String label, String typeKey, Color color, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (_selectedTypes.contains(typeKey)) {
            if (_selectedTypes.length > 1) { // En az bir tane seçili kalsın
              _selectedTypes.remove(typeKey);
            }
          } else {
            _selectedTypes.add(typeKey);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.backgroundDark : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? color.withOpacity(0.5) : Colors.transparent),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactionsCard(BuildContext context, List<dynamic> transactions) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(CupertinoIcons.clock, color: AppTheme.primaryPurple, size: 20),
                  SizedBox(width: 8),
                  Text('Son İşlemler', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                ],
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const TransactionsScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.brown.shade900.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Text('Tümünü Gör', style: TextStyle(color: Colors.white, fontSize: 12)),
                      SizedBox(width: 4),
                      Icon(CupertinoIcons.arrow_right, color: Colors.white, size: 12),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (transactions.isEmpty)
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: AppTheme.backgroundDark,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(CupertinoIcons.doc_text, color: AppTheme.primaryPurple, size: 32),
                  ),
                  const SizedBox(height: 16),
                  const Text('Henüz işlem yok', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                  const SizedBox(height: 8),
                  const Text('İlk işleminizi ekleyin ve finansal takibinizi başlatın', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  const SizedBox(height: 24),
                ],
              ),
            )
          else
            ...transactions.take(5).map((tx) {
              bool isIncome = tx['type'] == 'income';
              double amt = double.parse(tx['amount'].toString());
              String category = (tx['category'] ?? '').toString();
              
              if (category.startsWith('{')) {
                try {
                  RegExp regex = RegExp(r"name:\s*'([^']+)'|name:\s*([a-zA-ZğüşıöçĞÜŞİÖÇ/]+)");
                  var match = regex.firstMatch(category);
                  if (match != null) {
                     category = match.group(1) ?? match.group(2) ?? category;
                  }
                } catch (_) {}
              }
              if (category.isEmpty || category.startsWith('{')) {
                 category = isIncome ? 'Gelir' : 'Gider';
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isIncome ? AppTheme.incomeGreen.withOpacity(0.1) : AppTheme.expenseRed.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isIncome ? CupertinoIcons.arrow_down_left : CupertinoIcons.cart_fill, 
                            color: isIncome ? AppTheme.incomeGreen : AppTheme.expenseRed, 
                            size: 20
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(category, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                            const SizedBox(height: 4),
                            Text(tx['transaction_date'] ?? '', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                    Text(
                      '${isIncome ? '+' : '-'}${amt.toStringAsFixed(2)} ${context.read<SettingsProvider>().currencySymbol}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isIncome ? AppTheme.incomeGreen : AppTheme.expenseRed,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
  List<LineChartBarData> _generateLineBars(List<dynamic> txs) {
    DateTime now = DateTime.now();
    int numBuckets = 0;
    
    if (_selectedPeriod == 'Gün') numBuckets = 24;      // Son 24 saat
    else if (_selectedPeriod == 'Hafta') numBuckets = 7;     // Son 7 gün
    else if (_selectedPeriod == 'Ay') numBuckets = 30;       // Son 30 gün

    Map<String, List<double>> bucketSums = {
      'income': List.filled(numBuckets, 0.0),
      'expense': List.filled(numBuckets, 0.0),
    };

    for (var tx in txs) {
      if (tx['transaction_date'] == null) continue;
      DateTime txDate = DateTime.parse(tx['transaction_date']);
      
      int bucketIndex = -1;
      
      if (_selectedPeriod == 'Gün') {
        if (txDate.year == now.year && txDate.month == now.month && txDate.day == now.day) {
          bucketIndex = txDate.hour;
        }
      } else if (_selectedPeriod == 'Hafta') {
        int daysAgo = DateTime(now.year, now.month, now.day)
            .difference(DateTime(txDate.year, txDate.month, txDate.day))
            .inDays;
        if (daysAgo >= 0 && daysAgo < 7) {
          bucketIndex = 6 - daysAgo; // 6: bugs, 0: 6 gün önce
        }
      } else if (_selectedPeriod == 'Ay') {
        int daysAgo = DateTime(now.year, now.month, now.day)
            .difference(DateTime(txDate.year, txDate.month, txDate.day))
            .inDays;
        if (daysAgo >= 0 && daysAgo < 30) {
          bucketIndex = 29 - daysAgo;
        }
      }

      if (bucketIndex != -1) {
        String baseType = tx['type'].toString().toLowerCase();
        // Sadece income veya expense var
        if (baseType == 'income' || baseType == 'expense') {
          bucketSums[baseType]![bucketIndex] += double.tryParse(tx['amount'].toString()) ?? 0.0;
        }
      }
    }

    List<LineChartBarData> bars = [];
    
    Color getColorForType(String type) {
      switch (type) {
        case 'income': return AppTheme.incomeGreen;
        case 'expense': return AppTheme.expenseRed;
        default: return Colors.white;
      }
    }

    for (String type in _selectedTypes) {
      List<FlSpot> spots = [];
      List<double> sums = bucketSums[type]!;
      for (int i = 0; i < numBuckets; i++) {
        spots.add(FlSpot(i.toDouble(), sums[i]));
      }
      
      bars.add(
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: getColorForType(type),
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: getColorForType(type).withOpacity(0.15),
          ),
        )
      );
    }
    
    if (bars.isEmpty) {
      bars.add(
        LineChartBarData(
          spots: const [FlSpot(0, 0), FlSpot(1, 0)],
          color: Colors.transparent,
        )
      );
    }

    return bars;
  }
}
