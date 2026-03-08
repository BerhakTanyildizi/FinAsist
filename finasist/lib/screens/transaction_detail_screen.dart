import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../utils/thousand_separator_formatter.dart';

class TransactionDetailScreen extends StatefulWidget {
  final Transaction transaction;
  const TransactionDetailScreen({super.key, required this.transaction});

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  late bool isExpense;
  late int selectedCategoryId;
  late DateTime selectedDate;
  late TextEditingController _amountController;
  late TextEditingController _merchantController;
  late TextEditingController _descriptionController;
  bool _isEditing = false;
  bool _isSaving = false;

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
  void initState() {
    super.initState();
    final tx = widget.transaction;
    isExpense = tx.isExpense;
    selectedCategoryId = tx.categoryId;
    selectedDate = tx.transactionDate;
    _amountController = TextEditingController(
      text: _formatInitialAmount(tx.amount),
    );
    _merchantController = TextEditingController(text: tx.merchant ?? '');
    _descriptionController = TextEditingController(text: tx.description ?? '');
  }

  String _formatInitialAmount(double amount) {
    final intAmount = amount.toInt();
    if (amount == intAmount.toDouble()) {
      return intAmount.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]}.',
      );
    }
    return amount.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tx = widget.transaction;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E2C) : Colors.white;
    final labelColor = isDark ? Colors.white70 : Colors.grey[700]!;
    final categories = isExpense ? expenseCategories : incomeCategories;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'İşlemi Düzenle' : 'İşlem Detayı',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _confirmDelete(context, tx),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: _isEditing
            ? _buildEditForm(isDark, cardColor, labelColor, categories)
            : _buildDetailView(tx, isDark, cardColor, labelColor),
      ),
    );
  }

  // ── Detay Görünümü ──

  Widget _buildDetailView(
      Transaction tx, bool isDark, Color cardColor, Color labelColor) {
    final iconColor = tx.category.color;

    return Column(
      children: [
        const SizedBox(height: 8),
        CircleAvatar(
          radius: 36,
          backgroundColor: iconColor.withValues(alpha: isDark ? 0.3 : 0.15),
          child: Icon(tx.category.icon, color: iconColor, size: 36),
        ),
        const SizedBox(height: 16),
        Text(
          tx.formattedAmount,
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.bold,
            color: tx.isIncome ? Colors.green : Colors.red,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: (tx.isIncome ? Colors.green : Colors.red)
                .withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            tx.isIncome ? 'Gelir' : 'Gider',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: tx.isIncome ? Colors.green : Colors.red,
            ),
          ),
        ),
        const SizedBox(height: 28),
        _detailCard(cardColor, labelColor, [
          _detailRow(Icons.category, 'Kategori', tx.category.name, labelColor),
          if (tx.merchant != null && tx.merchant!.isNotEmpty)
            _detailRow(Icons.store, 'İşyeri / Kaynak', tx.merchant!, labelColor),
          if (tx.description != null && tx.description!.isNotEmpty)
            _detailRow(Icons.notes, 'Açıklama', tx.description!, labelColor),
          _detailRow(
            Icons.calendar_today,
            'Tarih',
            '${tx.transactionDate.day.toString().padLeft(2, '0')}/'
                '${tx.transactionDate.month.toString().padLeft(2, '0')}/'
                '${tx.transactionDate.year}',
            labelColor,
          ),
          _detailRow(
            Icons.access_time,
            'Oluşturulma',
            '${tx.createdAt.day.toString().padLeft(2, '0')}/'
                '${tx.createdAt.month.toString().padLeft(2, '0')}/'
                '${tx.createdAt.year} '
                '${tx.createdAt.hour.toString().padLeft(2, '0')}:'
                '${tx.createdAt.minute.toString().padLeft(2, '0')}',
            labelColor,
          ),
        ]),
      ],
    );
  }

  Widget _detailCard(
      Color cardColor, Color labelColor, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: children
            .expand((w) => [w, const Divider(height: 24)])
            .toList()
          ..removeLast(),
      ),
    );
  }

  Widget _detailRow(
      IconData icon, String label, String value, Color labelColor) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF00B4D8)),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(fontSize: 12, color: labelColor)),
            const SizedBox(height: 2),
            Text(value,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }

  // ── Düzenleme Formu ──

  Widget _buildEditForm(
      bool isDark, Color cardColor, Color labelColor, List<Map<String, dynamic>> categories) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Gelir/Gider toggle
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark ? Colors.white10 : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              _toggleButton('Gider', true, Colors.red, isDark),
              _toggleButton('Gelir', false, Colors.green, isDark),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Tutar
        Text('Tutar', style: TextStyle(fontWeight: FontWeight.bold, color: labelColor)),
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
            prefixStyle: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isExpense ? Colors.red : Colors.green,
            ),
            filled: true,
            fillColor: cardColor,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isExpense ? Colors.red : Colors.green, width: 2)),
          ),
        ),
        const SizedBox(height: 24),

        // Kategori
        Text('Kategori', style: TextStyle(fontWeight: FontWeight.bold, color: labelColor)),
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
                onTap: () => setState(() => selectedCategoryId = cat['id'] as int),
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

        // İşyeri
        Text(isExpense ? 'İşyeri' : 'Kaynak', style: TextStyle(fontWeight: FontWeight.bold, color: labelColor)),
        const SizedBox(height: 8),
        TextField(
          controller: _merchantController,
          decoration: InputDecoration(
            prefixIcon: Icon(isExpense ? Icons.store : Icons.business, color: const Color(0xFF00B4D8)),
            filled: true,
            fillColor: cardColor,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade300)),
          ),
        ),
        const SizedBox(height: 20),

        // Açıklama
        Text('Açıklama', style: TextStyle(fontWeight: FontWeight.bold, color: labelColor)),
        const SizedBox(height: 8),
        TextField(
          controller: _descriptionController,
          maxLines: 2,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.notes, color: Color(0xFF00B4D8)),
            filled: true,
            fillColor: cardColor,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade300)),
          ),
        ),
        const SizedBox(height: 20),

        // Tarih
        Text('Tarih', style: TextStyle(fontWeight: FontWeight.bold, color: labelColor)),
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
        const SizedBox(height: 32),

        // Butonlar
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _isEditing = false),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade400),
                ),
                child: const Text('İptal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00B4D8),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isSaving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Kaydet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _toggleButton(String label, bool expense, Color activeColor, bool isDark) {
    final active = isExpense == expense;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => isExpense = expense),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: active ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: active ? Colors.white : (isDark ? Colors.white54 : Colors.grey),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveChanges() async {
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

    final success =
        await context.read<TransactionProvider>().updateTransaction(
              id: widget.transaction.id,
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('İşlem güncellendi!'),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.read<TransactionProvider>().error ?? 'Güncelleme başarısız'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _confirmDelete(BuildContext context, Transaction tx) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('İşlemi Sil', style: TextStyle(color: Colors.red)),
        content: const Text('Bu işlemi silmek istediğinize emin misiniz?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final provider = context.read<TransactionProvider>();
              Navigator.pop(ctx);
              await provider.deleteTransaction(tx.id);
              if (context.mounted) Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
