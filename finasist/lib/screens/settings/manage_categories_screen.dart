import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/transaction_provider.dart';

class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  String _filterType = 'all'; // 'all', 'income', 'expense'

  // İkonlar: kullanıcı seçebilir (sadece Flutter CupertinoIcons tabanlı ikon adları)
  final List<IconData> _availableIcons = [
    CupertinoIcons.cart_fill,
    CupertinoIcons.house_fill,
    CupertinoIcons.car_fill,
    CupertinoIcons.bolt_fill,
    CupertinoIcons.heart_fill,
    CupertinoIcons.music_note,
    CupertinoIcons.gift_fill,
    CupertinoIcons.briefcase_fill,
    CupertinoIcons.doc_fill,
    CupertinoIcons.airplane,
    CupertinoIcons.sportscourt_fill,
    CupertinoIcons.money_dollar_circle_fill,
    CupertinoIcons.creditcard_fill,
    CupertinoIcons.book_fill,
    CupertinoIcons.person_fill,
    CupertinoIcons.flame_fill,
  ];

  IconData _selectedIcon = CupertinoIcons.cart_fill;
  String _categoryType = 'expense'; // 'income' or 'expense'
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _showAddCategoryDialog() async {
    _nameController.clear();
    setState(() {
      _selectedIcon = CupertinoIcons.cart_fill;
      _categoryType = 'expense';
    });

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Başlık
                const Text('Yeni Kategori', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),

                // İsim Girişi
                TextField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Kategori Adı',
                    labelStyle: const TextStyle(color: AppTheme.textSecondary),
                    filled: true,
                    fillColor: AppTheme.backgroundDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Tür Seçimi (Gelir / Gider)
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setSheetState(() => _categoryType = 'income'),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: _categoryType == 'income' ? AppTheme.incomeGreen : AppTheme.backgroundDark,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              '✅ Gelir',
                              style: TextStyle(
                                color: _categoryType == 'income' ? Colors.white : AppTheme.textSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setSheetState(() => _categoryType = 'expense'),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: _categoryType == 'expense' ? AppTheme.expenseRed : AppTheme.backgroundDark,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              '❌ Gider',
                              style: TextStyle(
                                color: _categoryType == 'expense' ? Colors.white : AppTheme.textSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // İkon Seçici
                const Text('İkon Seç', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _availableIcons.map((icon) {
                    bool isSelected = _selectedIcon == icon;
                    return GestureDetector(
                      onTap: () => setSheetState(() => _selectedIcon = icon),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.primaryPurple : AppTheme.backgroundDark,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? AppTheme.primaryPurple : Colors.white12,
                            width: 2,
                          ),
                        ),
                        child: Icon(icon, color: isSelected ? Colors.white : AppTheme.textSecondary, size: 22),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Kaydet Butonu
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final name = _nameController.text.trim();
                      if (name.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Kategori adı boş olamaz!'), backgroundColor: AppTheme.expenseRed),
                        );
                        return;
                      }
                      Navigator.pop(ctx);
                      final success = await Provider.of<TransactionProvider>(context, listen: false).createCategory(
                        name: name,
                        type: _categoryType,
                      );
                      if (!success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Kategori oluşturulamadı!'), backgroundColor: AppTheme.expenseRed),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryPurple,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text('Kaydet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    
    var filteredCategories = provider.categories.where((c) {
      if (_filterType == 'all') return true;
      return c['type'] == _filterType;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kategorileri Yönet'),
        actions: [
          TextButton.icon(
            onPressed: _showAddCategoryDialog,
            icon: const Icon(CupertinoIcons.plus_circle_fill, color: AppTheme.primaryPurple),
            label: const Text('Yeni', style: TextStyle(color: AppTheme.primaryPurple, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtre Seçici
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _filterChip('Tümü', 'all'),
                const SizedBox(width: 8),
                _filterChip('Gelir', 'income'),
                const SizedBox(width: 8),
                _filterChip('Gider', 'expense'),
              ],
            ),
          ),

          // Kategori Listesi
          Expanded(
            child: filteredCategories.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: const BoxDecoration(
                            color: AppTheme.backgroundDark,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(CupertinoIcons.tag_fill, color: AppTheme.primaryPurple, size: 48),
                        ),
                        const SizedBox(height: 24),
                        const Text('Henüz kategori yok', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 8),
                        const Text('Sağ üstteki "Yeni" butonuna tıklayarak\nkendi kategorinizi oluşturun', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredCategories.length,
                    separatorBuilder: (_, __) => Divider(color: Colors.white.withOpacity(0.05), height: 1),
                    itemBuilder: (context, index) {
                      final cat = filteredCategories[index];
                      final bool isIncome = cat['type'] == 'income';
                      final bool isCustom = cat['user_id'] != null; // Özel mi? (Silinebilir mi?)
                      
                      return Container(
                        color: AppTheme.cardColor,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isIncome ? AppTheme.incomeGreen.withOpacity(0.15) : AppTheme.expenseRed.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isIncome ? CupertinoIcons.arrow_down_left : CupertinoIcons.cart_fill,
                              color: isIncome ? AppTheme.incomeGreen : AppTheme.expenseRed,
                              size: 20,
                            ),
                          ),
                          title: Text(cat['name'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          subtitle: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (isIncome ? AppTheme.incomeGreen : AppTheme.expenseRed).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isIncome ? 'Gelir' : 'Gider',
                                  style: TextStyle(
                                    color: isIncome ? AppTheme.incomeGreen : AppTheme.expenseRed,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (!isCustom) ...[
                                const SizedBox(width: 6),
                                const Text('Sistem', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                              ],
                            ],
                          ),
                          trailing: isCustom
                              ? IconButton(
                                  icon: const Icon(CupertinoIcons.trash_fill, color: AppTheme.expenseRed, size: 20),
                                  onPressed: () async {
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        backgroundColor: AppTheme.cardColor,
                                        title: const Text('Kategoriyi Sil', style: TextStyle(color: Colors.white)),
                                        content: Text('"${cat['name']}" kategorisini silmek istediğinize emin misiniz?', style: const TextStyle(color: AppTheme.textSecondary)),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx, false),
                                            child: const Text('İptal'),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx, true),
                                            child: const Text('Sil', style: TextStyle(color: AppTheme.expenseRed)),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirmed == true) {
                                      await Provider.of<TransactionProvider>(context, listen: false)
                                          .deleteCategory(cat['id']);
                                    }
                                  },
                                )
                              : const Icon(CupertinoIcons.lock_fill, color: AppTheme.textSecondary, size: 16),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    bool isSelected = _filterType == value;
    return GestureDetector(
      onTap: () => setState(() => _filterType = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryPurple : AppTheme.cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
