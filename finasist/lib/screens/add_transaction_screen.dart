import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/transaction_provider.dart';
import '../utils/thousand_separator_formatter.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  bool isExpense = true;
  int selectedCategoryId = 1;
  String selectedCategoryName = 'Market & Gıda';
  DateTime selectedDate = DateTime.now();
  bool _isSaving = false;

  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _merchantController = TextEditingController();

  // Backend'teki category id'leri ile eşleşen sabit liste
  final List<Map<String, dynamic>> expenseCategories = [
    {'id': 1, 'name': 'Market & Gıda', 'icon': Icons.shopping_cart, 'color': Colors.orange},
    {'id': 2, 'name': 'Faturalar', 'icon': Icons.receipt_long, 'color': Colors.blue},
    {'id': 3, 'name': 'Ulaşım', 'icon': Icons.directions_car, 'color': Colors.teal},
    {'id': 4, 'name': 'Eğlence', 'icon': Icons.movie, 'color': Colors.purple},
    {'id': 5, 'name': 'Sağlık', 'icon': Icons.local_hospital, 'color': Colors.red},
    {'id': 6, 'name': 'Eğitim', 'icon': Icons.school, 'color': Colors.indigo},
    {'id': 7, 'name': 'Giyim', 'icon': Icons.checkroom, 'color': Colors.pink},
    {'id': 8, 'name': 'Diğer', 'icon': Icons.more_horiz, 'color': Colors.grey},
  ];

  final List<Map<String, dynamic>> incomeCategories = [
    {'id': 9, 'name': 'Maaş', 'icon': Icons.account_balance, 'color': Colors.green},
    {'id': 10, 'name': 'Freelance', 'icon': Icons.laptop, 'color': Colors.teal},
    {'id': 11, 'name': 'Yatırım', 'icon': Icons.trending_up, 'color': Colors.blue},
    {'id': 12, 'name': 'Hediye', 'icon': Icons.card_giftcard, 'color': Colors.amber},
    {'id': 13, 'name': 'Diğer', 'icon': Icons.more_horiz, 'color': Colors.grey},
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _merchantController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E2C) : Colors.white;
    final categories = isExpense ? expenseCategories : incomeCategories;

    if (!categories.any((c) => c['id'] == selectedCategoryId)) {
      selectedCategoryId = categories.first['id'] as int;
      selectedCategoryName = categories.first['name'] as String;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('İşlem Ekle', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Gelir / Gider Toggle ──
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => isExpense = true),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: isExpense ? Colors.red : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            '\u{1F4B8}  Gider',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isExpense
                                  ? Colors.white
                                  : (isDark ? Colors.white54 : Colors.grey),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => isExpense = false),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: !isExpense ? Colors.green : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            '\u{1F4B0}  Gelir',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: !isExpense
                                  ? Colors.white
                                  : (isDark ? Colors.white54 : Colors.grey),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── Tutar ──
            Text('Tutar', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.grey[700])),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                ThousandSeparatorFormatter(),
              ],
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                prefixText: '\u20BA  ',
                prefixStyle: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: isExpense ? Colors.red : Colors.green),
                hintText: '0,00',
                filled: true,
                fillColor: cardColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade300)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isExpense ? Colors.red : Colors.green, width: 2)),
              ),
            ),
            const SizedBox(height: 24),

            // ── Kategori ──
            Text('Kategori', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.grey[700])),
            const SizedBox(height: 12),
            SizedBox(
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final isSelected = selectedCategoryId == cat['id'];
                  return GestureDetector(
                    onTap: () => setState(() {
                      selectedCategoryId = cat['id'] as int;
                      selectedCategoryName = cat['name'] as String;
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 80,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (cat['color'] as Color).withValues(alpha: 0.2)
                            : (isDark ? Colors.white10 : Colors.grey.shade100),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: isSelected ? cat['color'] as Color : Colors.transparent, width: 2),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(cat['icon'] as IconData, color: cat['color'] as Color, size: 28),
                          const SizedBox(height: 6),
                          Text(
                            cat['name'] as String,
                            style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // ── İşyeri / Kaynak ──
            Text(isExpense ? 'İşyeri' : 'Kaynak', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.grey[700])),
            const SizedBox(height: 8),
            TextField(
              controller: _merchantController,
              decoration: InputDecoration(
                hintText: isExpense ? 'ör: Migros, BİM...' : 'ör: Şirket Adı',
                prefixIcon: Icon(isExpense ? Icons.store : Icons.business, color: const Color(0xFF00B4D8)),
                filled: true,
                fillColor: cardColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade300)),
              ),
            ),
            const SizedBox(height: 20),

            // ── Açıklama ──
            Text('Açıklama (opsiyonel)', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.grey[700])),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Ek not ekleyebilirsiniz...',
                prefixIcon: const Icon(Icons.notes, color: Color(0xFF00B4D8)),
                filled: true,
                fillColor: cardColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade300)),
              ),
            ),
            const SizedBox(height: 20),

            // ── Tarih ──
            Text('Tarih', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.grey[700])),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => selectedDate = picked);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Color(0xFF00B4D8)),
                    const SizedBox(width: 12),
                    Text(
                      '${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const Spacer(),
                    Icon(Icons.arrow_drop_down, color: isDark ? Colors.white38 : Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 36),

            // ── Kaydet ──
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveTransaction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isExpense ? Colors.red : Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 4,
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        isExpense ? '\u{1F4B8}  Gideri Kaydet' : '\u{1F4B0}  Geliri Kaydet',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _saveTransaction() async {
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir tutar girin.'), backgroundColor: Colors.red),
      );
      return;
    }

    final amountText = _amountController.text.replaceAll('.', '');
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Geçerli bir tutar girin.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSaving = true);

    final dateStr =
        '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';

    final success = await context.read<TransactionProvider>().addTransaction(
          categoryId: selectedCategoryId,
          amount: amount,
          type: isExpense ? 'expense' : 'income',
          transactionDate: dateStr,
          merchant: _merchantController.text.trim(),
          description: _descriptionController.text.trim(),
        );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      final type = isExpense ? 'Gider' : 'Gelir';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$type başarıyla kaydedildi!'),
          backgroundColor: isExpense ? Colors.red.shade700 : Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.read<TransactionProvider>().error ?? 'Kayıt başarısız'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
