import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/settings_provider.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    final transactions = provider.transactions;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tüm İşlemler', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: transactions.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
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
                  const Text('İşlem geçmişiniz burada görünecektir.', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final tx = transactions[index];
                bool isIncome = tx['type'] == 'income';
                double amt = double.tryParse(tx['amount'].toString()) ?? 0.0;
                String category = (tx['category'] ?? '').toString();
                // Attempt to parse stringified JSON (looks like {id: 1, name: Gıda/...})
                // Actually the backend response from python is: "{'id': 1, 'name': 'Gıda/Market', 'icon_name': 'cart', 'type': 'expense'}"
                // So we need to handle single quotes -> double quotes for jsonDecode, or just extract name with RegExp.
                if (category.startsWith('{')) {
                  try {
                    String jsonStr = category.replaceAll("'", '"');
                    // Gerekirse dartın decode edemediği anahtarsız unquoted value formatını regex ile çöz.
                    // En kolayı RegExp ile name parametresini almak:
                    RegExp regex = RegExp(r"name:\s*'([^']+)'|name:\s*([a-zA-ZğüşıöçĞÜŞİÖÇ/]+)");
                    var match = regex.firstMatch(category);
                    if (match != null) {
                       category = match.group(1) ?? match.group(2) ?? category;
                    }
                  } catch (e) {
                     // fallback
                  }
                }
                
                if (category.isEmpty || category.startsWith('{')) {
                   category = isIncome ? 'Gelir' : 'Gider';
                }
                
                return Dismissible(
                  key: Key(tx['id'].toString()),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.centerRight,
                    child: const Icon(CupertinoIcons.trash, color: Colors.white),
                  ),
                  onDismissed: (direction) async {
                    await context.read<TransactionProvider>().deleteTransaction(tx['id']);
                  },
                  child: Padding(
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
                  ),
                );
              },
            ),
    );
  }
}
