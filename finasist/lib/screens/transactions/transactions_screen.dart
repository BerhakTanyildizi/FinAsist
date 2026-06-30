import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/settings_provider.dart';
import '../../utils/category_icons.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
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
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundOf(context),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(CupertinoIcons.doc_text, color: AppTheme.primaryPurple, size: 32),
                  ),
                  const SizedBox(height: 16),
                  Text('Henüz işlem yok', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimaryOf(context))),
                  const SizedBox(height: 8),
                  Text('İşlem geçmişiniz burada görünecektir.', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textSecondaryOf(context), fontSize: 13)),
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

                Color typeColor = isIncome ? AppTheme.incomeGreen : AppTheme.expenseRed;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Material(
                    color: AppTheme.cardColorOf(context),
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _showTransactionDetail(context, tx),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: typeColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(getCategoryIcon(iconName), color: typeColor, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(category, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimaryOf(context))),
                                  const SizedBox(height: 4),
                                  if (description.isNotEmpty)
                                    Text(description, style: TextStyle(color: AppTheme.textSecondaryOf(context), fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  Text(tx['transaction_date'] ?? '', style: TextStyle(color: AppTheme.textSecondaryOf(context), fontSize: 11)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${isIncome ? '+' : '-'}${amt.toStringAsFixed(2)} ${context.read<SettingsProvider>().currencySymbol}',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: typeColor),
                            ),
                            const SizedBox(width: 4),
                            Icon(CupertinoIcons.chevron_right, color: AppTheme.textSecondaryOf(context), size: 14),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showTransactionDetail(BuildContext context, dynamic tx) {
    bool isIncome = tx['type'] == 'income';
    double amt = double.tryParse(tx['amount'].toString()) ?? 0.0;
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

    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.backgroundOf(context),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.24), borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: typeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                  child: Icon(getCategoryIcon(iconName), color: typeColor, size: 32),
                ),
                const SizedBox(height: 16),
                Text(category, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryOf(context))),
                const SizedBox(height: 8),
                Text(
                  '${isIncome ? '+' : '-'}${amt.toStringAsFixed(2)} $currencySymbol',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: typeColor),
                ),
                const SizedBox(height: 20),
                _detailRow(context, CupertinoIcons.calendar, 'Tarih', date),
                _detailRow(context, CupertinoIcons.tag_fill, 'Tür', isIncome ? 'Gelir' : 'Gider'),
                if (merchant.isNotEmpty) _detailRow(context, CupertinoIcons.building_2_fill, 'Mağaza', merchant),
                if (description.isNotEmpty) _detailRow(context, CupertinoIcons.doc_text_fill, 'Not', description),
                const SizedBox(height: 20),
                Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showEditDialog(context, tx);
                      },
                      icon: const Icon(CupertinoIcons.pencil, size: 18),
                      label: const Text('Düzenle', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryPurple,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (c) => AlertDialog(
                            backgroundColor: AppTheme.cardColorOf(c),
                            title: Text('İşlemi Sil', style: TextStyle(color: AppTheme.textPrimaryOf(c))),
                            content: Text('Bu işlemi silmek istediğinize emin misiniz?', style: TextStyle(color: AppTheme.textSecondaryOf(c))),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('İptal')),
                              TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Sil', style: TextStyle(color: AppTheme.expenseRed))),
                            ],
                          ),
                        );
                        if (confirmed == true && mounted) {
                          await context.read<TransactionProvider>().deleteTransaction(tx['id']);
                        }
                      },
                      icon: const Icon(CupertinoIcons.trash, size: 18),
                      label: const Text('Sil', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.expenseRed,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditDialog(BuildContext context, dynamic tx) {
    final amountController = TextEditingController(text: double.tryParse(tx['amount'].toString())?.toStringAsFixed(0) ?? '');
    final noteController = TextEditingController(text: (tx['description'] ?? '').toString());
    final provider = context.read<TransactionProvider>();
    final categories = provider.categories;

    bool isIncome = tx['type'] == 'income';
    int selectedCategoryId = tx['category_id'] ?? (tx['category'] is Map ? tx['category']['id'] : 0);
    DateTime selectedDate = DateTime.tryParse(tx['transaction_date'] ?? '') ?? DateTime.now();

    var filteredCategories = categories.where((c) => c['type'] == (isIncome ? 'income' : 'expense')).toList();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.backgroundOf(context),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24, right: 24, top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.24), borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 20),
                  Center(child: Text('İşlemi Düzenle', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryOf(ctx)))),
                  const SizedBox(height: 24),

                  Text('Tutar', style: TextStyle(color: AppTheme.textSecondaryOf(ctx), fontSize: 13)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(color: AppTheme.textPrimaryOf(ctx), fontSize: 18, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppTheme.cardColorOf(ctx),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      suffixText: context.read<SettingsProvider>().currencySymbol,
                      suffixStyle: TextStyle(color: AppTheme.textSecondaryOf(ctx), fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text('Kategori', style: TextStyle(color: AppTheme.textSecondaryOf(ctx), fontSize: 13)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(color: AppTheme.cardColorOf(ctx), borderRadius: BorderRadius.circular(16)),
                    child: DropdownButton<int>(
                      value: filteredCategories.any((c) => c['id'] == selectedCategoryId) ? selectedCategoryId : null,
                      isExpanded: true,
                      dropdownColor: AppTheme.cardColorOf(ctx),
                      underline: const SizedBox(),
                      style: TextStyle(color: AppTheme.textPrimaryOf(ctx), fontSize: 16),
                      hint: Text('Kategori seçin', style: TextStyle(color: AppTheme.textSecondaryOf(ctx))),
                      items: filteredCategories.map<DropdownMenuItem<int>>((c) {
                        return DropdownMenuItem<int>(
                          value: c['id'],
                          child: Row(
                            children: [
                              Icon(getCategoryIcon(c['icon_name']), color: AppTheme.textSecondaryOf(ctx), size: 18),
                              const SizedBox(width: 8),
                              Text(c['name']),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setSheetState(() => selectedCategoryId = val);
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text('Tarih', style: TextStyle(color: AppTheme.textSecondaryOf(ctx), fontSize: 13)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2040),
                        builder: (c, child) => Theme(
                          data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: AppTheme.primaryPurple, surface: AppTheme.cardColor, onSurface: Colors.white)),
                          child: child!,
                        ),
                      );
                      if (picked != null) setSheetState(() => selectedDate = picked);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(color: AppTheme.cardColorOf(ctx), borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        children: [
                          Icon(CupertinoIcons.calendar, color: AppTheme.textSecondaryOf(ctx), size: 18),
                          const SizedBox(width: 8),
                          Text(
                            '${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}',
                            style: TextStyle(color: AppTheme.textPrimaryOf(ctx), fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text('Not', style: TextStyle(color: AppTheme.textSecondaryOf(ctx), fontSize: 13)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: noteController,
                    maxLines: 2,
                    style: TextStyle(color: AppTheme.textPrimaryOf(ctx)),
                    decoration: InputDecoration(
                      hintText: 'Not ekleyin...',
                      hintStyle: TextStyle(color: AppTheme.textSecondaryOf(ctx)),
                      filled: true,
                      fillColor: AppTheme.cardColorOf(ctx),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final rawAmount = amountController.text.replaceAll('.', '').replaceAll(',', '.');
                        final amount = double.tryParse(rawAmount);
                        if (amount == null || amount <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Geçerli bir tutar giriniz.'), backgroundColor: AppTheme.expenseRed),
                          );
                          return;
                        }

                        Navigator.pop(ctx);
                        final dateStr = '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
                        final success = await provider.updateTransaction(
                          transactionId: tx['id'],
                          amount: amount,
                          categoryId: selectedCategoryId,
                          description: noteController.text.trim(),
                          transactionDate: dateStr,
                        );
                        if (!success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Güncelleme başarısız oldu.'), backgroundColor: AppTheme.expenseRed),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryPurple,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      // Bu buton her zaman primaryPurple arkaplanlıdır, metin sabit beyaz kalmalı
                      child: const Text('Güncelle', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _detailRow(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textSecondaryOf(context), size: 18),
          const SizedBox(width: 12),
          Text('$label:', style: TextStyle(color: AppTheme.textSecondaryOf(context), fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: TextStyle(color: AppTheme.textPrimaryOf(context), fontSize: 14), textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}
