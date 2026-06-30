import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/settings_provider.dart';
import '../../utils/category_icons.dart';
import '../main_layout.dart';
import '../transactions/transactions_screen.dart';
import '../scan/scan_receipt_screen.dart';

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
          icon: Icon(CupertinoIcons.settings, color: AppTheme.textSecondaryOf(context)),
          onPressed: () => MainLayoutScreen.changeTab(context, 5),
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
                  _buildBalanceCard(context, provider.totalBalance, context.watch<SettingsProvider>().currencySymbol),
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

  Widget _buildBalanceCard(BuildContext context, double balance, String currencySymbol) {
    // Bakiyemizi formatlıyoruz
    String balanceString = balance.toStringAsFixed(2);
    List<String> parts = balanceString.split('.');
    String integerPart = parts[0];
    String decimalPart = parts.length > 1 ? parts[1] : '00';
    final textPrimary = AppTheme.textPrimaryOf(context);
    final textSecondary = AppTheme.textSecondaryOf(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardColorOf(context),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Hesaplarım', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textPrimary)),
              Icon(CupertinoIcons.chevron_right, color: textSecondary, size: 18),
            ],
          ),
          const SizedBox(height: 24),
          Text('Genel', style: TextStyle(color: textSecondary, fontSize: 14)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(currencySymbol, style: TextStyle(color: textPrimary, fontSize: 24, fontWeight: FontWeight.bold)),
              Text(integerPart, style: TextStyle(color: textPrimary, fontSize: 48, fontWeight: FontWeight.bold, height: 1.0)),
              Text(',$decimalPart', style: TextStyle(color: textPrimary, fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Text('Son Güncelleme: ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}', style: TextStyle(color: textSecondary, fontSize: 12)),
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
    final textPrimary = AppTheme.textPrimaryOf(context);
    final textSecondary = AppTheme.textSecondaryOf(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColorOf(context),
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
                child: Icon(Icons.flash_on, color: textSecondary, size: 16),
              ),
              const SizedBox(width: 12),
              Text('Hızlı İşlemler', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textPrimary)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildQuickActionItem(
                context: context,
                icon: CupertinoIcons.doc_text_viewfinder,
                color: AppTheme.incomeGreen,
                bgColor: AppTheme.incomeGreen.withValues(alpha: 0.1),
                label: 'Evrak Tara',
                isAi: true,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ScanReceiptScreen()),
                  );
                },
              ),
              _buildQuickActionItem(
                context: context,
                icon: CupertinoIcons.chat_bubble_2,
                color: Colors.brown.shade300,
                bgColor: Colors.brown.shade900.withValues(alpha: 0.5),
                label: 'AI Finansal\nDanışman',
                isAi: true,
                onTap: () => MainLayoutScreen.changeTab(context, 1),
              ),
              _buildQuickActionItem(
                context: context,
                icon: CupertinoIcons.add,
                color: AppTheme.starYellow,
                bgColor: AppTheme.starYellow.withValues(alpha: 0.1),
                label: 'Gelir/Gider Ekle',
                isAi: false,
                onTap: () => MainLayoutScreen.changeTab(context, 3),
              ),
              _buildQuickActionItem(
                context: context,
                icon: CupertinoIcons.chart_pie,
                color: Colors.blueAccent,
                bgColor: Colors.blueAccent.withValues(alpha: 0.1),
                label: 'Finansal\nRaporlar',
                isAi: false,
                onTap: () => MainLayoutScreen.changeTab(context, 4),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionItem({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required String label,
    required bool isAi,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                    border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
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
                        color: AppTheme.cardColorOf(context),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(CupertinoIcons.sparkles, color: AppTheme.textPrimaryOf(context), size: 8),
                          const SizedBox(width: 2),
                          Text('AI', style: TextStyle(color: AppTheme.textPrimaryOf(context), fontSize: 8, fontWeight: FontWeight.bold)),
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
              style: TextStyle(color: AppTheme.textSecondaryOf(context), fontSize: 11, height: 1.2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendAnalysisCard(BuildContext context, TransactionProvider provider) {
    final textPrimary = AppTheme.textPrimaryOf(context);
    final textSecondary = AppTheme.textSecondaryOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColorOf(context),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(CupertinoIcons.chart_bar_alt_fill, color: Colors.brown, size: 20),
              const SizedBox(width: 8),
              Text('Trend Analizi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textPrimary)),
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
                    color: _selectedPeriod == 'Gün' ? Colors.brown.shade900.withValues(alpha: 0.5) : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('Gün', style: TextStyle(color: _selectedPeriod == 'Gün' ? textPrimary : textSecondary, fontSize: 13)),
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () => setState(() => _selectedPeriod = 'Hafta'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: _selectedPeriod == 'Hafta' ? Colors.brown.shade900.withValues(alpha: 0.5) : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('Hafta', style: TextStyle(color: _selectedPeriod == 'Hafta' ? textPrimary : textSecondary, fontSize: 13)),
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () => setState(() => _selectedPeriod = 'Ay'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: _selectedPeriod == 'Ay' ? Colors.brown.shade900.withValues(alpha: 0.5) : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('Ay', style: TextStyle(color: _selectedPeriod == 'Ay' ? textPrimary : textSecondary, fontSize: 13)),
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
                      color: AppTheme.backgroundOf(context).withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1)),
                    ),
                    alignment: Alignment.center,
                    child: Text('Henüz veri yok', style: TextStyle(color: textSecondary, fontSize: 12)),
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
                                child: Text(text, style: TextStyle(color: textSecondary, fontSize: 10)),
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
          color: isSelected ? AppTheme.backgroundOf(context) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? color.withValues(alpha: 0.5) : Colors.transparent),
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
            Text(label, style: TextStyle(color: AppTheme.textPrimaryOf(context), fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactionsCard(BuildContext context, List<dynamic> transactions) {
    final textPrimary = AppTheme.textPrimaryOf(context);
    final textSecondary = AppTheme.textSecondaryOf(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColorOf(context),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(CupertinoIcons.clock, color: AppTheme.primaryPurple, size: 20),
                  const SizedBox(width: 8),
                  Text('Son İşlemler', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textPrimary)),
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
                    color: Colors.brown.shade900.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Text('Tümünü Gör', style: TextStyle(color: textPrimary, fontSize: 12)),
                      const SizedBox(width: 4),
                      Icon(CupertinoIcons.arrow_right, color: textPrimary, size: 12),
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
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundOf(context),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(CupertinoIcons.doc_text, color: AppTheme.primaryPurple, size: 32),
                  ),
                  const SizedBox(height: 16),
                  Text('Henüz işlem yok', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textPrimary)),
                  const SizedBox(height: 8),
                  Text('İlk işleminizi ekleyin ve finansal takibinizi başlatın', textAlign: TextAlign.center, style: TextStyle(color: textSecondary, fontSize: 13)),
                  const SizedBox(height: 24),
                ],
              ),
            )
          else
            ...transactions.take(5).map((tx) {
              bool isIncome = tx['type'] == 'income';
              double amt = double.parse(tx['amount'].toString());
              String description = (tx['description'] ?? '').toString().trim();

              final catObj = tx['category'];
              String category = '';
              String? iconName;
              if (catObj is Map) {
                category = catObj['name'] ?? '';
                iconName = catObj['icon_name'];
              }
              if (category.isEmpty) {
                category = isIncome ? 'Gelir' : 'Gider';
              }

              return GestureDetector(
                onTap: () => _showTransactionDetail(context, tx),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isIncome ? AppTheme.incomeGreen.withValues(alpha: 0.1) : AppTheme.expenseRed.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                getCategoryIcon(iconName),
                                color: isIncome ? AppTheme.incomeGreen : AppTheme.expenseRed,
                                size: 20
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(category, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary)),
                                  const SizedBox(height: 4),
                                  if (description.isNotEmpty)
                                    Text(description, style: TextStyle(color: textSecondary, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  Text(tx['transaction_date'] ?? '', style: TextStyle(color: textSecondary, fontSize: 11)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
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
                ),
              );
            }),
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
        default: return AppTheme.textSecondary;
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
            color: getColorForType(type).withValues(alpha: 0.15),
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

  void _showTransactionDetail(BuildContext context, dynamic tx) {
    bool isIncome = tx['type'] == 'income';
    double amt = double.parse(tx['amount'].toString());
    String description = (tx['description'] ?? '').toString().trim();
    String date = tx['transaction_date'] ?? '';
    String merchant = (tx['merchant'] ?? '').toString().trim();
    Color typeColor = isIncome ? AppTheme.incomeGreen : AppTheme.expenseRed;
    String currencySymbol = context.read<SettingsProvider>().currencySymbol;

    final catObj = tx['category'];
    String category = '';
    String? iconName;
    if (catObj is Map) {
      category = catObj['name'] ?? '';
      iconName = catObj['icon_name'];
    }
    if (category.isEmpty) category = isIncome ? 'Gelir' : 'Gider';

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.backgroundOf(context),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: typeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                child: Icon(getCategoryIcon(iconName), color: typeColor, size: 32),
              ),
              const SizedBox(height: 16),
              Text(category, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryOf(ctx))),
              const SizedBox(height: 8),
              Text(
                '${isIncome ? '+' : '-'}${amt.toStringAsFixed(2)} $currencySymbol',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: typeColor),
              ),
              const SizedBox(height: 20),
              _detailRow(ctx, CupertinoIcons.calendar, 'Tarih', date),
              _detailRow(ctx, CupertinoIcons.tag_fill, 'Tür', isIncome ? 'Gelir' : 'Gider'),
              if (merchant.isNotEmpty) _detailRow(ctx, CupertinoIcons.building_2_fill, 'Mağaza', merchant),
              if (description.isNotEmpty) _detailRow(ctx, CupertinoIcons.doc_text_fill, 'Not', description),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(BuildContext context, IconData icon, String label, String value) {
    final textSecondary = AppTheme.textSecondaryOf(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: textSecondary, size: 18),
          const SizedBox(width: 12),
          Text('$label:', style: TextStyle(color: textSecondary, fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: TextStyle(color: AppTheme.textPrimaryOf(context), fontSize: 14), textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}
