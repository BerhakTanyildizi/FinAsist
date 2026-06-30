import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';
import '../../providers/settings_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/pdf_report_service.dart';
import '../transactions/transactions_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int _selectedTrendTab = 0; // 0 = Günlük, 1 = Haftalık
  bool _isGeneratingPdf = false;

  Future<void> _downloadPdfReport() async {
    if (_isGeneratingPdf) return;
    setState(() => _isGeneratingPdf = true);

    try {
      final provider = context.read<TransactionProvider>();
      final settings = context.read<SettingsProvider>();
      final auth = context.read<AuthProvider>();

      await PdfReportService.generateAndShare(
        transactions: provider.transactions,
        currencySymbol: settings.currencySymbol,
        userName: auth.user?.fullName ?? 'Finasist Kullanıcısı',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rapor PDF olarak oluşturuldu. ✅')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rapor oluşturulamadı: $e')),
      );
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    final transactions = provider.transactions;
    
    // Basit istatistik hesaplama (Gerçek veritabanından)
    DateTime now = DateTime.now();
    double thisMonthIncome = 0;
    double thisMonthExpense = 0;
    double lastMonthIncome = 0;
    double lastMonthExpense = 0;

    for (var tx in transactions) {
      if (tx['transaction_date'] == null) continue;
      DateTime date = DateTime.parse(tx['transaction_date']);
      double amount = double.parse(tx['amount'].toString());
      bool isIncome = tx['type'] == 'income';

      if (date.year == now.year && date.month == now.month) {
        if (isIncome) thisMonthIncome += amount;
        else thisMonthExpense += amount;
      } else if ((now.month == 1 && date.year == now.year - 1 && date.month == 12) || 
                 (date.year == now.year && date.month == now.month - 1)) {
        if (isIncome) lastMonthIncome += amount;
        else lastMonthExpense += amount;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Finansal Rapor', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.square_list, color: AppTheme.primaryPurple),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TransactionsScreen()),
              );
            },
          ),
          IconButton(
            icon: _isGeneratingPdf
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.starYellow),
                  )
                : const Icon(CupertinoIcons.arrow_down_doc, color: AppTheme.starYellow),
            onPressed: _isGeneratingPdf ? null : _downloadPdfReport,
            tooltip: 'PDF olarak indir',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            // 1. Trend Analizi Kartı
            _buildLargeTrendCard(context, transactions),
            const SizedBox(height: 16),

            // 2. Dönemsel Karşılaştırma Kartı
            _buildComparisonCard(context, thisMonthIncome, thisMonthExpense, lastMonthIncome, lastMonthExpense),
            const SizedBox(height: 80), // Fab padding
          ],
        ),
      ),
    );
  }

  Widget _buildLargeTrendCard(BuildContext context, List<dynamic> transactions) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColorOf(context),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundOf(context),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(CupertinoIcons.graph_circle, color: Colors.blueAccent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text('Trend Analizi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimaryOf(context))),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.backgroundOf(context),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() => _selectedTrendTab = 0);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _selectedTrendTab == 0 ? Colors.brown.shade800 : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        // Seçili sekme her zaman koyu (brown.shade800) arkaplanlıdır, metin sabit beyaz kalmalı
                        child: Text('Günlük', style: TextStyle(color: _selectedTrendTab == 0 ? Colors.white : AppTheme.textSecondaryOf(context), fontSize: 12)),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() => _selectedTrendTab = 1);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _selectedTrendTab == 1 ? Colors.brown.shade800 : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        // Seçili sekme her zaman koyu (brown.shade800) arkaplanlıdır, metin sabit beyaz kalmalı
                        child: Text('Haftalık', style: TextStyle(color: _selectedTrendTab == 1 ? Colors.white : AppTheme.textSecondaryOf(context), fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildLegendDot('Gelir', AppTheme.incomeGreen, context),
              const SizedBox(width: 16),
              _buildLegendDot('Gider', AppTheme.expenseRed, context),
            ],
          ),
          const SizedBox(height: 32),

          // Büyük grafik alanı (fl_chart)
          SizedBox(
            height: 200,
            child: transactions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundOf(context),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(CupertinoIcons.chart_bar_alt_fill, color: AppTheme.textSecondaryOf(context), size: 28),
                      ),
                      const SizedBox(height: 16),
                      Text('Bu dönem için veri yok', style: TextStyle(color: AppTheme.textSecondaryOf(context), fontSize: 13)),
                    ],
                  ),
                )
              : BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: _getMaxY(transactions) * 1.2, // Tavanı %20 yüksek tutalım
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            rod.toY.toStringAsFixed(0) + ' ${context.read<SettingsProvider>().currencySymbol}\n',
                            TextStyle(color: AppTheme.textPrimaryOf(context), fontWeight: FontWeight.bold),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 32, // Artırıldı ki "Hafta X" vb. kesilmesin
                          interval: 1,
                          getTitlesWidget: (value, meta) => _getBottomTitles(value, meta, transactions, context),
                        ),
                      ),
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    barGroups: _generateBarGroups(transactions),
                  ),
                ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  double _getMaxY(List<dynamic> txs) {
    if (txs.isEmpty) return 1000;
    
    // Compute max for the grouped bars instead of individual transactions
    var groups = _getGroupedData(txs);
    double max = 0;
    for (var group in groups) {
      if (group['income'] > max) max = group['income'];
      if (group['expense'] > max) max = group['expense'];
    }
    
    return max == 0 ? 1000 : max;
  }

  // Gruplama mantığını ortaklaştıran yardımcı fonksiyon
  // Geri dönüş List of Map, her Map: { 'label': String, 'income': double, 'expense': double }
  List<Map<String, dynamic>> _getGroupedData(List<dynamic> txs) {
    DateTime now = DateTime.now();
    List<Map<String, dynamic>> result = [];
    
    if (_selectedTrendTab == 0) { // Günlük (Son 7 Gün)
      for (int i = 6; i >= 0; i--) { // Eskiden yeniye
        DateTime targetDate = now.subtract(Duration(days: i));
        double dIncome = 0;
        double dExpense = 0;
        
        for (var tx in txs) {
           if (tx['transaction_date'] == null) continue;
           DateTime txD = DateTime.parse(tx['transaction_date']);
           if (txD.year == targetDate.year && txD.month == targetDate.month && txD.day == targetDate.day) {
              double amt = double.tryParse(tx['amount'].toString()) ?? 0;
              if (tx['type'] == 'income') dIncome += amt;
              else dExpense += amt;
           }
        }
        result.add({
          'label': "${targetDate.day}/${targetDate.month}",
          'income': dIncome,
          'expense': dExpense
        });
      }
    } else { // Haftalık (Son 4 Hafta)
      for (int i = 3; i >= 0; i--) { // Eskiden yeniye
        DateTime weekEnd = now.subtract(Duration(days: i * 7));
        DateTime weekStart = weekEnd.subtract(const Duration(days: 6));
        
        double wIncome = 0;
        double wExpense = 0;
        
        for (var tx in txs) {
           if (tx['transaction_date'] == null) continue;
           DateTime txD = DateTime.parse(tx['transaction_date']);
           
           // weekStart <= txD <= weekEnd (Yaklaşık)
           // Saat farklarını yoksaymak için sadece gün bazında basit sınır kontrolü yapalım
           DateTime txDayOnly = DateTime(txD.year, txD.month, txD.day);
           DateTime startOnly = DateTime(weekStart.year, weekStart.month, weekStart.day);
           DateTime endOnly = DateTime(weekEnd.year, weekEnd.month, weekEnd.day);

           if (txDayOnly.compareTo(startOnly) >= 0 && txDayOnly.compareTo(endOnly) <= 0) {
              double amt = double.tryParse(tx['amount'].toString()) ?? 0;
              if (tx['type'] == 'income') wIncome += amt;
              else wExpense += amt;
           }
        }
        result.add({
          'label': "Hafta ${4 - i}",
          'income': wIncome,
          'expense': wExpense
        });
      }
    }
    
    return result;
  }

  Widget _getBottomTitles(double value, TitleMeta meta, List<dynamic> txs, BuildContext context) {
    final style = TextStyle(color: AppTheme.textSecondaryOf(context), fontWeight: FontWeight.bold, fontSize: 10);
    int intVal = value.toInt();
    
    var groups = _getGroupedData(txs);
    String text = "";
    if (intVal >= 0 && intVal < groups.length) {
       text = groups[intVal]['label'];
    }
    
    return SideTitleWidget(
      meta: meta,
      space: 10,
      child: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Text(text, style: style),
      ),
    );
  }

  List<BarChartGroupData> _generateBarGroups(List<dynamic> txs) {
    var groups = _getGroupedData(txs);
    List<BarChartGroupData> items = [];
    
    for (int i = 0; i < groups.length; i++) {
        var g = groups[i];
        
        items.add(
          BarChartGroupData(
            x: i,
            barsSpace: 4, // İki yan yana çubuk arası boşluk
            barRods: [
              // Gelir çubuğu
              BarChartRodData(
                toY: g['income'],
                color: AppTheme.incomeGreen,
                width: 12,
                borderRadius: BorderRadius.circular(4),
              ),
              // Gider çubuğu
              BarChartRodData(
                toY: g['expense'],
                color: AppTheme.expenseRed,
                width: 12,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          )
        );
    }
    return items;
  }

  Widget _buildLegendDot(String label, Color color, BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: AppTheme.textSecondaryOf(context), fontSize: 12)),
      ],
    );
  }

  Widget _buildComparisonCard(BuildContext context, double tIncome, double tExpense, double lIncome, double lExpense) {
    return Container(
      width: double.infinity,
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
                  color: AppTheme.backgroundOf(context),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(CupertinoIcons.arrow_right_arrow_left, color: Colors.orangeAccent, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text('Dönemsel Karşılaştırma', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimaryOf(context))),
                   Text('Geçen aya göre', style: TextStyle(color: AppTheme.textSecondaryOf(context), fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildComparisonStatBox(context, true, tIncome, lIncome)),
              const SizedBox(width: 16),
              Expanded(child: _buildComparisonStatBox(context, false, tExpense, lExpense)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonStatBox(BuildContext context, bool isIncome, double current, double lastMonth) {
    Color color = isIncome ? AppTheme.incomeGreen : AppTheme.expenseRed;
    String label = isIncome ? 'Gelir' : 'Gider';
    IconData icon = isIncome ? CupertinoIcons.arrow_up_right : CupertinoIcons.arrow_down_right;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Yüzdesel farkı hesapla
    double percentage = 0;
    if (lastMonth > 0) {
      percentage = ((current - lastMonth) / lastMonth) * 100;
    } else if (current > 0) {
      percentage = 100; // Geçen ay 0, bu ay veri varsa %100 arttı
    }

    String sign = percentage > 0 ? "+" : "";

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.1), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(current.toStringAsFixed(0), style: TextStyle(color: AppTheme.textPrimaryOf(context), fontSize: 24, fontWeight: FontWeight.bold, height: 1.0))
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('$sign${percentage.toStringAsFixed(1)}%', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 24),
          Divider(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1), height: 1),
          const SizedBox(height: 12),
          Text('Geçen Ay', style: TextStyle(color: AppTheme.textSecondaryOf(context), fontSize: 11)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(lastMonth.toStringAsFixed(0), style: TextStyle(color: AppTheme.textSecondaryOf(context), fontSize: 14, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );
  }
}
