import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/transaction_provider.dart';
import '../models/transaction.dart';
import 'transaction_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    final provider = context.read<TransactionProvider>();
    Future.microtask(() => provider.loadTransactions());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Özet Durum',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          IconButton(icon: const Icon(Icons.account_circle), onPressed: () {}),
        ],
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, txProvider, _) {
          if (txProvider.isLoading && txProvider.transactions.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () => txProvider.loadTransactions(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBalanceCard(context, txProvider),
                  const SizedBox(height: 24),
                  _buildSectionHeader('AI Gözlemleri', context),
                  const SizedBox(height: 12),
                  _buildAIAdviceCard(context, isDark, txProvider),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionHeader('Son İşlemler', context),
                      TextButton(
                        onPressed: () {},
                        child: const Text('Tümünü Gör'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildTransactionList(context, isDark, txProvider),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final provider = context.read<TransactionProvider>();
          await context.push('/add-transaction');
          if (mounted) provider.loadTransactions();
        },
        backgroundColor: const Color(0xFF00B4D8),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
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

  Widget _buildBalanceCard(
      BuildContext context, TransactionProvider txProvider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00B4D8), Color(0xFF0077B6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0077B6).withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Toplam Bakiye',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            _formatMoney(txProvider.balance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildIncomeExpenseRow(
                Icons.arrow_upward,
                'Gelir',
                _formatMoney(txProvider.totalIncome),
                Colors.greenAccent,
              ),
              _buildIncomeExpenseRow(
                Icons.arrow_downward,
                'Gider',
                _formatMoney(txProvider.totalExpense),
                Colors.redAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeExpenseRow(
    IconData icon,
    String label,
    String amount,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70)),
            Text(
              amount,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, BuildContext context) {
    return Text(
      title,
      style: Theme.of(context)
          .textTheme
          .titleLarge
          ?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildAIAdviceCard(
      BuildContext context, bool isDark, TransactionProvider txProvider) {
    final cardBg = isDark
        ? const Color(0xFF0077B6).withValues(alpha: 0.25)
        : const Color(0xFF90E0EF).withValues(alpha: 0.2);
    final borderColor = isDark
        ? const Color(0xFF00B4D8).withValues(alpha: 0.6)
        : const Color(0xFF90E0EF);
    final textColor = isDark ? Colors.white70 : Colors.grey[800]!;

    String advice;
    if (txProvider.transactions.isEmpty) {
      advice =
          'Henüz işlem eklemediniz. İlk gelir veya giderinizi ekleyerek finansal takibinize başlayın!';
    } else if (txProvider.totalExpense > txProvider.totalIncome * 0.8) {
      advice =
          'Giderleriniz gelirinizin %80\'inden fazla! Harcamalarınızı gözden geçirmenizi öneririm.';
    } else {
      advice =
          'Finansal durumunuz iyi görünüyor. Gelir-gider dengenizi korumaya devam edin.';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb, color: Color(0xFF00B4D8), size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI Tavsiyesi',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00B4D8),
                  ),
                ),
                const SizedBox(height: 8),
                Text(advice, style: TextStyle(color: textColor, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList(
      BuildContext context, bool isDark, TransactionProvider txProvider) {
    final all = txProvider.transactions;

    if (all.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        alignment: Alignment.center,
        child: Text(
          'Henüz işlem yok.\n"+" butonuyla başlayın!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isDark ? Colors.white38 : Colors.grey,
            fontSize: 15,
          ),
        ),
      );
    }

    final sorted = List<Transaction>.from(all)
      ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 400),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: sorted.length,
        itemBuilder: (context, index) {
          final tx = sorted[index];
          return Dismissible(
            key: ValueKey(tx.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              color: Colors.red,
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (_) {
              txProvider.deleteTransaction(tx.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('İşlem silindi')),
              );
            },
            child: _buildTransactionItem(context, isDark, tx),
          );
        },
      ),
    );
  }

  Widget _buildTransactionItem(
      BuildContext context, bool isDark, Transaction tx) {
    final iconColor = tx.category.color;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: iconColor.withValues(alpha: isDark ? 0.25 : 0.1),
          child: Icon(tx.category.icon, color: iconColor),
        ),
        title: Text(tx.category.name,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(tx.merchant ?? tx.description ?? ''),
        trailing: Text(
          tx.formattedAmount,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: tx.isIncome ? Colors.green : Colors.red,
            fontSize: 16,
          ),
        ),
        onTap: () async {
          final provider = context.read<TransactionProvider>();
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => TransactionDetailScreen(transaction: tx),
            ),
          );
          if (result == true && mounted) provider.loadTransactions();
        },
      ),
    );
  }
}
