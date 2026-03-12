import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/settings_provider.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  // İşlem Türü: 0 = Gider, 1 = Gelir, 2 = Tahsilat Al, 3 = Borç Ver
  int _transactionType = 0;
  final TextEditingController _amountController = TextEditingController();
  bool _isLoading = false;
  
  DateTime _selectedDate = DateTime.now();
  int? _selectedCategoryId;

  // Düzenli işlem state'leri
  bool isRecurring = false;
  String selectedFrequency = 'Aylık'; // 'Aylık', 'Haftalık', 'Yıllık'
  DateTime? endDate;

  void _saveTransaction() async {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen geçerli bir tutar giriniz.'), backgroundColor: AppTheme.expenseRed),
      );
      return;
    }

    // Convert string to double (Handle comma vs dot)
    final double? amount = double.tryParse(amountText.replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Lütfen geçerli bir tutar giriniz.'), backgroundColor: AppTheme.expenseRed),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    String apiType = _transactionType == 0 ? "expense" : "income";
    
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir kategori seçiniz.'), backgroundColor: AppTheme.expenseRed),
      );
      setState(() { _isLoading = false; });
      return;
    }

    // Global Provider üzerinden işlemi kaydetme
    bool success = false;
    
    // İşlem Türü: 0=Gider, 1=Gelir, 2=Tahsilat (Gelir gibi), 3=Borç (Gider gibi davranabilir veya ayrı tip)
    // Şimdilik "expense" ve "income" olarak sınıflandırıyoruz
    
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
        description: "",
      );
    } else {
      success = await Provider.of<TransactionProvider>(context, listen: false).addTransaction(
        categoryId: _selectedCategoryId!,
        amount: amount,
        type: apiType,
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
      // Temizleme işlemi
      _amountController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hata: Sunucu ile bağlantı kurulamadı veya kayıt başarısız.'), backgroundColor: AppTheme.expenseRed),
      );
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // İşlem tipine göre ana renk değişsin ki uygulamamız dinamik ve interaktif olsun!
    Color mainColor = _transactionType == 0 
        ? AppTheme.expenseRed 
        : _transactionType == 1 
            ? AppTheme.incomeGreen 
            : AppTheme.primaryPurple;

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
                  _buildTypeButton(0, 'Gider', CupertinoIcons.arrow_down_right, mainColor),
                  const SizedBox(width: 8),
                  _buildTypeButton(1, 'Gelir', CupertinoIcons.arrow_up_right, mainColor),
                  const SizedBox(width: 8),
                  _buildTypeButton(2, 'Tahsilat Al', CupertinoIcons.arrow_down_doc_fill, mainColor),
                  const SizedBox(width: 8),
                  _buildTypeButton(3, 'Borç', CupertinoIcons.doc_text, mainColor),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. Devasa Tutar Giriş Alanı Kartı
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: mainColor.withOpacity(0.3), 
                  width: _amountController.text.isNotEmpty ? 2 : 1, 
                ),
              ),
              child: Column(
                children: [
                  const Text('Tutar', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        _transactionType == 0 ? '-' : '+',
                        style: TextStyle(color: mainColor, fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 4),
                      IntrinsicWidth(
                        child: TextField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold, letterSpacing: -1),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: "0,00",
                            hintStyle: TextStyle(color: Colors.white24, fontSize: 48, fontWeight: FontWeight.bold),
                          ),
                          onChanged: (text) {
                            // Sınır parlaması efekti için state tetikleme
                            setState(() {});
                          },
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(context.read<SettingsProvider>().currencySymbol, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 32)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 3. Seçim Kartı (Hesap, Kategori, Tarih)
            Container(
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Consumer<TransactionProvider>(
                builder: (context, provider, child) {
                  // Mevcut tipe (income/expense) uygun kategorileri filtrele
                  String currentApiType = _transactionType == 0 ? "expense" : "income";
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
                        icon: CupertinoIcons.creditcard_fill,
                        iconColor: Colors.blueAccent,
                        iconBgColor: Colors.blue.shade900,
                        label: 'Hesap',
                        value: 'Genel',
                        onTap: () {},
                      ),
                      Divider(color: Colors.white.withOpacity(0.05), height: 1, indent: 64),
                      _buildSelectionRow(
                        icon: CupertinoIcons.cart_fill, 
                        iconColor: Colors.orangeAccent,
                        iconBgColor: Colors.orange.shade900,
                        label: 'Kategori',
                        value: categoryName, 
                        onTap: () => _showCategoryPicker(filteredCategories),
                      ),
                      Divider(color: Colors.white.withOpacity(0.05), height: 1, indent: 64),
                      _buildSelectionRow(
                        icon: CupertinoIcons.calendar,
                        iconColor: Colors.brown.shade300,
                        iconBgColor: Colors.brown.shade900,
                        label: 'Tarih',
                        value: dateLabel,
                        onTap: () => _selectDate(),
                        trailingOverride: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.brown.shade900.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
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
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: isRecurring ? mainColor : Colors.transparent, width: 2),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Düzenli İşlem / Taksit mi?', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                      Switch(
                        value: isRecurring,
                        activeColor: mainColor,
                        onChanged: (val) => setState(() => isRecurring = val),
                      ),
                    ],
                  ),
                  if (isRecurring) ...[
                    Divider(color: Colors.white.withOpacity(0.1), height: 24),
                    Row(
                      children: [
                        const Text('Sıklık:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                        const Spacer(),
                        DropdownButton<String>(
                          value: selectedFrequency,
                          dropdownColor: AppTheme.cardColor,
                          underline: const SizedBox(),
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
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
                        const Text('Bitiş:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
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
                          label: Text(endDate == null ? 'Süresiz (Seç)' : '${endDate!.day.toString().padLeft(2, '0')}/${endDate!.month.toString().padLeft(2, '0')}/${endDate!.year}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
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
            
            // 4. Not ve Etiket Ekleme Kartları
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(CupertinoIcons.doc_text, color: AppTheme.textSecondary, size: 18),
                        SizedBox(width: 8),
                        Text('Not Ekle', style: TextStyle(color: Colors.white, fontSize: 14)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(CupertinoIcons.tag, color: AppTheme.textSecondary, size: 18),
                        SizedBox(width: 8),
                        Text('Fotoğraf Ekle', style: TextStyle(color: Colors.white, fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ],
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
                  shadowColor: mainColor.withOpacity(0.5),
                ),
                child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                    : const Text('İşlemi Kaydet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 80), // Fab butonu üstünü örtmesin diye boşluk
          ],
        ),
      ),
    );
  }

  Widget _buildTypeButton(int index, String label, IconData icon, Color activeColor) {
    bool isSelected = _transactionType == index;
    
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
          color: isSelected ? activeColor : AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? activeColor : Colors.white.withOpacity(0.05),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon, 
              color: isSelected ? Colors.white : AppTheme.textSecondary,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionRow({
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
      title: Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
      subtitle: Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
      trailing: trailingOverride ?? const Icon(CupertinoIcons.chevron_right, color: AppTheme.textSecondary, size: 18),
      onTap: onTap,
    );
  }

  void _showCategoryPicker(List<dynamic> categories) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.backgroundDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Kategori Seçin', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    var cat = categories[index];
                    return ListTile(
                      leading: const Icon(CupertinoIcons.cart_fill, color: Colors.white54),
                      title: Text(cat['name'], style: const TextStyle(color: Colors.white)),
                      onTap: () {
                        setState(() { _selectedCategoryId = cat['id']; });
                        Navigator.pop(context);
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
