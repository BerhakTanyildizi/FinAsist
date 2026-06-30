import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/settings_provider.dart';
import '../../utils/category_icons.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  // İşlem Türü: 0 = Gider, 1 = Gelir, 2 = Tahsilat Al, 3 = Borç Ver
  int _transactionType = 0;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  bool _isLoading = false;

  DateTime _selectedDate = DateTime.now();
  int? _selectedCategoryId;

  // Düzenli işlem state'leri
  bool isRecurring = false;
  String selectedFrequency = 'Aylık';
  DateTime? endDate;

  String _formatNumber(String value) {
    value = value.replaceAll('.', '').replaceAll(',', '');
    if (value.isEmpty) return '';
    final buffer = StringBuffer();
    for (int i = 0; i < value.length; i++) {
      if (i > 0 && (value.length - i) % 3 == 0) buffer.write('.');
      buffer.write(value[i]);
    }
    return buffer.toString();
  }

  String _getRawAmount() {
    return _amountController.text.replaceAll('.', '').replaceAll(',', '.');
  }

  void _saveTransaction() async {
    final rawAmount = _getRawAmount();
    if (rawAmount.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen geçerli bir tutar giriniz.'), backgroundColor: AppTheme.expenseRed),
      );
      return;
    }

    final double? amount = double.tryParse(rawAmount);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Lütfen geçerli bir tutar giriniz.'), backgroundColor: AppTheme.expenseRed),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // 0=Gider, 1=Gelir, 2=Tahsilat (income), 3=Borç (expense)
    String apiType = (_transactionType == 0 || _transactionType == 3) ? "expense" : "income";

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir kategori seçiniz.'), backgroundColor: AppTheme.expenseRed),
      );
      setState(() { _isLoading = false; });
      return;
    }

    bool success = false;
    final description = _noteController.text.trim();

    if (isRecurring) {
      String? endDateStr;
      if (endDate != null) {
        endDateStr = '${endDate!.year}-${endDate!.month.toString().padLeft(2, '0')}-${endDate!.day.toString().padLeft(2, '0')}';
      }

      success = await Provider.of<TransactionProvider>(context, listen: false).addRecurringTransaction(
        categoryId: _selectedCategoryId!,
        amount: amount,
        type: apiType,
        frequency: selectedFrequency,
        startDate: _selectedDate.toIso8601String().split('T')[0],
        endDate: endDateStr,
        description: description,
      );
    } else {
      success = await Provider.of<TransactionProvider>(context, listen: false).addTransaction(
        categoryId: _selectedCategoryId!,
        amount: amount,
        type: apiType,
        description: description,
        transactionDate: _selectedDate.toIso8601String().split('T')[0],
      );
    }

    setState(() {
      _isLoading = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İşleminiz başarıyla kaydedildi! ✓'), backgroundColor: AppTheme.incomeGreen),
      );
      _amountController.clear();
      _noteController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hata: Sunucu ile bağlantı kurulamadı veya kayıt başarısız.'), backgroundColor: AppTheme.expenseRed),
      );
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // İşlem tipine göre ana renk değişsin ki uygulamamız dinamik ve interaktif olsun!
    Color mainColor = (_transactionType == 0 || _transactionType == 3)
        ? AppTheme.expenseRed
        : _transactionType == 1
            ? AppTheme.incomeGreen
            : AppTheme.primaryPurple;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('İşlem Ekle'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            // 1. Üstteki İşlem Türü Sekmeleri
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTypeButton(context, 0, 'Gider', CupertinoIcons.arrow_down_right, mainColor),
                  const SizedBox(width: 8),
                  _buildTypeButton(context, 1, 'Gelir', CupertinoIcons.arrow_up_right, mainColor),
                  const SizedBox(width: 8),
                  _buildTypeButton(context, 2, 'Tahsilat Al', CupertinoIcons.arrow_down_doc_fill, mainColor),
                  const SizedBox(width: 8),
                  _buildTypeButton(context, 3, 'Borç', CupertinoIcons.doc_text, mainColor),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. Devasa Tutar Giriş Alanı Kartı
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.cardColorOf(context),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: mainColor.withValues(alpha: 0.3),
                  width: _amountController.text.isNotEmpty ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Text('Tutar', style: TextStyle(color: AppTheme.textSecondaryOf(context), fontSize: 14)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        (_transactionType == 0 || _transactionType == 3) ? '-' : '+',
                        style: TextStyle(color: mainColor, fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 4),
                      IntrinsicWidth(
                        child: TextField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: false),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                          ],
                          style: TextStyle(color: AppTheme.textPrimaryOf(context), fontSize: 48, fontWeight: FontWeight.bold, letterSpacing: -1),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: "0",
                            hintStyle: TextStyle(color: AppTheme.textSecondaryOf(context), fontSize: 48, fontWeight: FontWeight.bold),
                          ),
                          onChanged: (text) {
                            final raw = text.replaceAll('.', '');
                            final formatted = _formatNumber(raw);
                            if (formatted != text) {
                              _amountController.value = TextEditingValue(
                                text: formatted,
                                selection: TextSelection.collapsed(offset: formatted.length),
                              );
                            }
                            setState(() {});
                          },
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(context.read<SettingsProvider>().currencySymbol, style: TextStyle(color: AppTheme.textSecondaryOf(context), fontSize: 32)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 3. Seçim Kartı (Hesap, Kategori, Tarih)
            Container(
              decoration: BoxDecoration(
                color: AppTheme.cardColorOf(context),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Consumer<TransactionProvider>(
                builder: (context, provider, child) {
                  String currentApiType = (_transactionType == 0 || _transactionType == 3) ? "expense" : "income";
                  var filteredCategories = provider.categories.where((c) => c['type'] == currentApiType).toList();

                  // Seçili kategori adını bul
                  String categoryName = "Kategori Seçin";
                  if (_selectedCategoryId != null) {
                    var found = provider.categories.firstWhere((c) => c['id'] == _selectedCategoryId, orElse: () => null);
                    if (found != null) categoryName = found['name'];
                  } else if (filteredCategories.isNotEmpty) {
                     // Default olarak ilkini seçelim
                     _selectedCategoryId = filteredCategories.first['id'];
                     categoryName = filteredCategories.first['name'];
                  }

                  String dateLabel = "${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}";

                  return Column(
                    children: [
                      _buildSelectionRow(
                        context: context,
                        icon: CupertinoIcons.creditcard_fill,
                        iconColor: Colors.blueAccent,
                        iconBgColor: Colors.blue.shade900,
                        label: 'Hesap',
                        value: 'Genel',
                        onTap: () {},
                      ),
                      Divider(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05), height: 1, indent: 64),
                      _buildSelectionRow(
                        context: context,
                        icon: CupertinoIcons.cart_fill,
                        iconColor: Colors.orangeAccent,
                        iconBgColor: Colors.orange.shade900,
                        label: 'Kategori',
                        value: categoryName,
                        onTap: () => _showCategoryPicker(filteredCategories),
                      ),
                      Divider(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05), height: 1, indent: 64),
                      _buildSelectionRow(
                        context: context,
                        icon: CupertinoIcons.calendar,
                        iconColor: Colors.brown.shade300,
                        iconBgColor: Colors.brown.shade900,
                        label: 'Tarih',
                        value: dateLabel,
                        onTap: () => _selectDate(),
                        trailingOverride: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.brown.shade900.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Rozet arkaplanı her zaman koyu kahverengi, metin sabit beyaz kalmalı
                              const Icon(CupertinoIcons.clock, color: Colors.white70, size: 14),
                              const SizedBox(width: 4),
                              Text('${_selectedDate.hour.toString().padLeft(2, '0')}:${_selectedDate.minute.toString().padLeft(2, '0')}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                              const SizedBox(width: 8),
                              const Icon(CupertinoIcons.chevron_right, color: Colors.white54, size: 12),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }
              ),
            ),
            const SizedBox(height: 16),

            // 3.5 Düzenli İşlem / Taksit Toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.cardColorOf(context),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: isRecurring ? mainColor : Colors.transparent, width: 2),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Düzenli İşlem / Taksit mi?', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimaryOf(context), fontSize: 16)),
                      Switch(
                        value: isRecurring,
                        activeColor: mainColor,
                        onChanged: (val) => setState(() => isRecurring = val),
                      ),
                    ],
                  ),
                  if (isRecurring) ...[
                    Divider(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1), height: 24),
                    Row(
                      children: [
                        Text('Sıklık:', style: TextStyle(color: AppTheme.textSecondaryOf(context), fontSize: 14)),
                        const Spacer(),
                        DropdownButton<String>(
                          value: selectedFrequency,
                          dropdownColor: AppTheme.cardColorOf(context),
                          underline: const SizedBox(),
                          style: TextStyle(color: AppTheme.textPrimaryOf(context), fontSize: 16, fontWeight: FontWeight.bold),
                          items: const [
                            DropdownMenuItem(value: 'Aylık', child: Text('Aylık')),
                            DropdownMenuItem(value: 'Haftalık', child: Text('Haftalık')),
                            DropdownMenuItem(value: 'Yıllık', child: Text('Yıllık')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => selectedFrequency = val);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text('Bitiş:', style: TextStyle(color: AppTheme.textSecondaryOf(context), fontSize: 14)),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: endDate ?? _selectedDate.add(const Duration(days: 30)),
                              firstDate: _selectedDate,
                              lastDate: DateTime(2040),
                              builder: (context, child) {
                                return Theme(
                                  data: ThemeData.dark().copyWith(
                                    colorScheme: ColorScheme.dark(
                                      primary: mainColor,
                                      onPrimary: Colors.white,
                                      surface: AppTheme.cardColor,
                                      onSurface: Colors.white,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) setState(() => endDate = picked);
                          },
                          icon: Icon(CupertinoIcons.calendar, size: 18, color: mainColor),
                          label: Text(endDate == null ? 'Süresiz (Seç)' : '${endDate!.day.toString().padLeft(2, '0')}/${endDate!.month.toString().padLeft(2, '0')}/${endDate!.year}', style: TextStyle(color: AppTheme.textPrimaryOf(context), fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                        if (endDate != null)
                          IconButton(
                            icon: const Icon(CupertinoIcons.clear_circled, size: 18, color: AppTheme.expenseRed),
                            onPressed: () => setState(() => endDate = null),
                          )
                      ],
                    ),
                  ]
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 4. Not Ekleme Kartı
            GestureDetector(
              onTap: () => _showNoteDialog(),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppTheme.cardColorOf(context),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _noteController.text.isNotEmpty ? mainColor.withValues(alpha: 0.3) : Colors.transparent,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.doc_text,
                      color: _noteController.text.isNotEmpty ? mainColor : AppTheme.textSecondaryOf(context),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _noteController.text.isNotEmpty ? _noteController.text : 'Not Ekle',
                        style: TextStyle(
                          color: _noteController.text.isNotEmpty ? AppTheme.textPrimaryOf(context) : AppTheme.textSecondaryOf(context),
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_noteController.text.isNotEmpty)
                      GestureDetector(
                        onTap: () => setState(() => _noteController.clear()),
                        child: Icon(CupertinoIcons.clear_circled, color: AppTheme.textSecondaryOf(context), size: 16),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // 5. Kaydet Butonu (Backend Entegrasyonu)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveTransaction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: mainColor,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 8,
                  shadowColor: mainColor.withValues(alpha: 0.5),
                ),
                // Bu buton her zaman mainColor (expenseRed/incomeGreen/primaryPurple) arkaplanlıdır, metin sabit beyaz kalmalı
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                    : const Text('İşlemi Kaydet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 80), // Fab butonu üstünü örtmesin diye boşluk
          ],
        ),
      ),
    );
  }

  Widget _buildTypeButton(BuildContext context, int index, String label, IconData icon, Color activeColor) {
    bool isSelected = _transactionType == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        setState(() {
          _transactionType = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : AppTheme.cardColorOf(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? activeColor : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              // Seçili durumda renkli (activeColor) arkaplan üzerinde olduğu için sabit beyaz kalmalı
              color: isSelected ? Colors.white : AppTheme.textSecondaryOf(context),
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                // Seçili durumda renkli (activeColor) arkaplan üzerinde olduğu için sabit beyaz kalmalı
                color: isSelected ? Colors.white : AppTheme.textSecondaryOf(context),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionRow({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String label,
    required String value,
    Widget? trailingOverride,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconBgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(label, style: TextStyle(color: AppTheme.textSecondaryOf(context), fontSize: 12)),
      subtitle: Text(value, style: TextStyle(color: AppTheme.textPrimaryOf(context), fontSize: 16, fontWeight: FontWeight.w600)),
      trailing: trailingOverride ?? Icon(CupertinoIcons.chevron_right, color: AppTheme.textSecondaryOf(context), size: 18),
      onTap: onTap,
    );
  }

  void _showCategoryPicker(List<dynamic> categories) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.backgroundOf(context),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Kategori Seçin', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryOf(ctx))),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: categories.length,
                  itemBuilder: (ctx, index) {
                    var cat = categories[index];
                    bool isSelected = _selectedCategoryId == cat['id'];
                    bool isExpense = cat['type'] == 'expense';
                    Color catColor = isExpense ? AppTheme.expenseRed : AppTheme.incomeGreen;
                    return ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: catColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          getCategoryIcon(cat['icon_name']),
                          color: isSelected ? catColor : AppTheme.textSecondaryOf(ctx),
                          size: 20,
                        ),
                      ),
                      title: Text(cat['name'], style: TextStyle(
                        color: AppTheme.textPrimaryOf(ctx),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      )),
                      trailing: isSelected
                          ? Icon(CupertinoIcons.checkmark_circle_fill, color: catColor, size: 20)
                          : null,
                      onTap: () {
                        setState(() { _selectedCategoryId = cat['id']; });
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  void _showNoteDialog() {
    final tempController = TextEditingController(text: _noteController.text);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.backgroundOf(context),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Not Ekle', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryOf(ctx))),
              const SizedBox(height: 16),
              TextField(
                controller: tempController,
                autofocus: true,
                maxLines: 3,
                style: TextStyle(color: AppTheme.textPrimaryOf(ctx)),
                decoration: InputDecoration(
                  hintText: 'İşlem hakkında not yazın...',
                  hintStyle: TextStyle(color: AppTheme.textSecondaryOf(ctx)),
                  filled: true,
                  fillColor: AppTheme.cardColorOf(ctx),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() { _noteController.text = tempController.text.trim(); });
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryPurple,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  // Bu buton her zaman primaryPurple arkaplanlıdır, metin sabit beyaz kalmalı
                  child: const Text('Kaydet', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primaryPurple,
              onPrimary: Colors.white,
              surface: AppTheme.cardColor,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      // Picked time is 00:00:00, we can keep the current hour/minute to not lose time context totally
      var newDate = DateTime(picked.year, picked.month, picked.day, _selectedDate.hour, _selectedDate.minute);
      setState(() { _selectedDate = newDate; });
    }
  }
}
