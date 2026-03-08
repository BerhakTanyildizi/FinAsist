import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';

import '../providers/transaction_provider.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int touchedIndex = -1;

  static const _chartColors = [
    Color(0xFF00B4D8),
    Color(0xFF90E0EF),
    Color(0xFF0077B6),
    Color(0xFF03045E),
    Colors.orange,
    Colors.purple,
    Colors.pink,
    Colors.teal,
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E2C) : Colors.white;
    final textSecondary = isDark ? Colors.white54 : Colors.grey[600]!;
    final subtitleColor = isDark ? Colors.white70 : Colors.grey[800]!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aylık Analiz', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, txProvider, _) {
          final expenseMap = txProvider.expenseByCategory;
          final totalExpense = txProvider.totalExpense;
          final totalIncome = txProvider.totalIncome;

          return SingleChildScrollView(
            child: Column(
              children: [
                // ── Top Summary ──
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark ? Colors.black38 : Colors.black12,
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text('Toplam Harcama', style: TextStyle(color: textSecondary, fontSize: 14)),
                      const SizedBox(height: 8),
                      Text(
                        _formatMoney(totalExpense),
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF03045E),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (totalIncome > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: (totalExpense > totalIncome * 0.7 ? Colors.red : Colors.green)
                                .withValues(alpha: isDark ? 0.25 : 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                totalExpense > totalIncome * 0.7 ? Icons.arrow_upward : Icons.arrow_downward,
                                color: totalExpense > totalIncome * 0.7 ? Colors.red : Colors.green,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Gelirin %${(totalExpense / totalIncome * 100).toStringAsFixed(0)}\'i harcandı',
                                style: TextStyle(
                                  color: totalExpense > totalIncome * 0.7 ? Colors.red : Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Pie Chart Card ──
                if (expenseMap.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: isDark ? Colors.black38 : Colors.black12,
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kategori Dağılımı',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF03045E),
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 240,
                            child: PieChart(
                              PieChartData(
                                pieTouchData: PieTouchData(
                                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                    setState(() {
                                      if (!event.isInterestedForInteractions ||
                                          pieTouchResponse == null ||
                                          pieTouchResponse.touchedSection == null) {
                                        touchedIndex = -1;
                                        return;
                                      }
                                      touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                                    });
                                  },
                                ),
                                borderData: FlBorderData(show: false),
                                sectionsSpace: 4,
                                centerSpaceRadius: 52,
                                sections: _buildSections(expenseMap, totalExpense),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          _buildLegend(expenseMap, subtitleColor),
                        ],
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'Henüz gider verisi yok.\nİşlem ekleyerek raporlarınızı görün!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: textSecondary, fontSize: 15),
                    ),
                  ),

                const SizedBox(height: 24),

                // ── AI Insight Card ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0077B6), Color(0xFF00B4D8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00B4D8).withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.psychology, color: Colors.white, size: 32),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Yapay Zeka Analizi',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _getAIInsight(expenseMap, totalExpense, totalIncome),
                                style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatMoney(double value) {
    final parts = value.toStringAsFixed(2).split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return '\u20BA $intPart,${parts[1]}';
  }

  String _getAIInsight(Map<String, double> expenseMap, double totalExpense, double totalIncome) {
    if (expenseMap.isEmpty) {
      return 'Henüz yeterli veri yok. İşlem ekledikçe size özel analizler sunacağım.';
    }
    final topCategory = expenseMap.entries.reduce((a, b) => a.value > b.value ? a : b);
    final pct = (topCategory.value / totalExpense * 100).toStringAsFixed(0);
    return 'En yüksek harcama kategoriniz "${topCategory.key}" (%$pct). Bu alanda tasarruf fırsatlarını değerlendirebilirsiniz.';
  }

  List<PieChartSectionData> _buildSections(Map<String, double> expenseMap, double total) {
    const shadows = [Shadow(color: Colors.black26, blurRadius: 4)];
    final entries = expenseMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return List.generate(entries.length, (i) {
      final touched = i == touchedIndex;
      final radius = touched ? 72.0 : 58.0;
      final fontSize = touched ? 20.0 : 13.0;
      final pct = total > 0 ? (entries[i].value / total * 100) : 0.0;

      return PieChartSectionData(
        color: _chartColors[i % _chartColors.length],
        value: entries[i].value,
        title: '%${pct.toStringAsFixed(0)}',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: shadows,
        ),
      );
    });
  }

  Widget _buildLegend(Map<String, double> expenseMap, Color subtitleColor) {
    final entries = expenseMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: List.generate(entries.length, (i) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Container(
                width: 13,
                height: 13,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _chartColors[i % _chartColors.length],
                ),
              ),
              const SizedBox(width: 10),
              Text(entries[i].key, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              const Spacer(),
              Text(_formatMoney(entries[i].value), style: TextStyle(fontWeight: FontWeight.bold, color: subtitleColor)),
            ],
          ),
        );
      }),
    );
  }
}
