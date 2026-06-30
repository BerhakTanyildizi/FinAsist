import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../providers/transaction_provider.dart';

class ScanReceiptScreen extends StatefulWidget {
  const ScanReceiptScreen({super.key});

  @override
  State<ScanReceiptScreen> createState() => _ScanReceiptScreenState();
}

class _ScanReceiptScreenState extends State<ScanReceiptScreen> {
  bool _isLoading = false;
  bool _hasResult = false;
  String? _errorMessage;

  // Seçilen dosya bilgisi
  String? _selectedFileName;
  Uint8List? _selectedFileBytes;

  // Tarama sonucu
  Map<String, dynamic>? _scanResult;

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.bytes != null) {
        setState(() {
          _selectedFileName = file.name;
          _selectedFileBytes = file.bytes;
          _hasResult = false;
          _scanResult = null;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Dosya seçilirken hata: $e';
      });
    }
  }

  Future<void> _scanReceipt() async {
    if (_selectedFileBytes == null || _selectedFileName == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await ApiService.scanReceiptFile(
        _selectedFileBytes!,
        _selectedFileName!,
      );

      if (result != null) {
        setState(() {
          _scanResult = result;
          _hasResult = true;
        });
      } else {
        setState(() {
          _errorMessage = 'Fiş analiz edilemedi. Lütfen daha net bir görüntü deneyin.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Bir hata oluştu: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _resetScreen() {
    setState(() {
      _selectedFileName = null;
      _selectedFileBytes = null;
      _hasResult = false;
      _scanResult = null;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundOf(context),
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundOf(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(CupertinoIcons.back, color: AppTheme.textPrimaryOf(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Fiş / Fatura Tara',
          style: TextStyle(color: AppTheme.textPrimaryOf(context), fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading ? _buildLoadingState(context) : _hasResult ? _buildResultState(context) : _buildUploadState(context),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AppTheme.primaryPurple,
              backgroundColor: AppTheme.primaryPurple.withValues(alpha: 0.15),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Fiş analiz ediliyor...',
            style: TextStyle(color: AppTheme.textPrimaryOf(context), fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Text(
            'OCR + Yapay Zeka ile metin çıkarılıyor',
            style: TextStyle(color: AppTheme.textSecondaryOf(context), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // Dosya seçme alanı
          GestureDetector(
            onTap: _pickFile,
            child: Container(
              width: double.infinity,
              height: 260,
              decoration: BoxDecoration(
                color: AppTheme.cardColorOf(context),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _selectedFileBytes != null
                      ? AppTheme.incomeGreen.withValues(alpha: 0.5)
                      : AppTheme.textSecondaryOf(context).withValues(alpha: 0.3),
                  width: 2,
                  strokeAlign: BorderSide.strokeAlignInside,
                ),
              ),
              child: _selectedFileBytes != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Görsel önizleme — kamera/dosya önizlemesi, sabit kalmalı
                          Image.memory(_selectedFileBytes!, fit: BoxFit.cover),
                          // Dosya adı overlay — önizleme üzerinde sabit koyu gradyan, metin sabit beyaz kalmalı
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [Colors.black87, Colors.transparent],
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(CupertinoIcons.checkmark_circle_fill, color: AppTheme.incomeGreen, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _selectedFileName ?? '',
                                      style: const TextStyle(color: Colors.white, fontSize: 13),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: _resetScreen,
                                    child: const Icon(CupertinoIcons.xmark_circle_fill, color: Colors.white, size: 20),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryPurple.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(CupertinoIcons.doc_text_viewfinder, color: AppTheme.primaryPurple, size: 44),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Fiş veya Fatura Seçin',
                          style: TextStyle(color: AppTheme.textPrimaryOf(context), fontSize: 17, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'JPG, PNG veya WEBP formatında',
                          style: TextStyle(color: AppTheme.textSecondaryOf(context), fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Maksimum 10 MB',
                          style: TextStyle(color: AppTheme.textSecondaryOf(context), fontSize: 12),
                        ),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 20),

          // Hata mesajı
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppTheme.expenseRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.expenseRed.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(CupertinoIcons.exclamationmark_triangle, color: AppTheme.expenseRed, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: AppTheme.expenseRed, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

          const Spacer(),

          // Bilgi kartı
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardColorOf(context),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.starYellow.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(CupertinoIcons.lightbulb, color: AppTheme.starYellow, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Nasıl Çalışır?', style: TextStyle(color: AppTheme.textPrimaryOf(context), fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(
                        'Fiş fotoğrafı OCR ile okunur, ardından yapay zeka ile kurum adı, tutar, tarih ve kategori otomatik çıkarılır.',
                        style: TextStyle(color: AppTheme.textSecondaryOf(context), fontSize: 12, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Tara butonu — bu buton her zaman primaryPurple arkaplanlıdır, metin/ikon sabit beyaz kalmalı
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _selectedFileBytes != null ? _scanReceipt : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryPurple,
                disabledBackgroundColor: AppTheme.primaryPurple.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.doc_text_viewfinder,
                    color: _selectedFileBytes != null ? Colors.white : Colors.white38,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Fişi Tara ve Analiz Et',
                    style: TextStyle(
                      color: _selectedFileBytes != null ? Colors.white : Colors.white38,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildResultState(BuildContext context) {
    final data = _scanResult!;
    final ocrText = data['ocr_text'] ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başarı başlığı
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.incomeGreen.withValues(alpha: 0.15), AppTheme.incomeGreen.withValues(alpha: 0.05)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.incomeGreen.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(CupertinoIcons.checkmark_seal_fill, color: AppTheme.incomeGreen, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Analiz Tamamlandı', style: TextStyle(color: AppTheme.incomeGreen, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text('Fiş başarıyla okundu ve analiz edildi.', style: TextStyle(color: AppTheme.textSecondaryOf(context), fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Sonuç kartları — her birine dokunarak düzenlenebilir
          _buildEditableResultCard(
            context: context,
            icon: CupertinoIcons.building_2_fill,
            label: 'Kurum Adı',
            value: data['kurum_adi'] ?? 'Bilinmiyor',
            color: AppTheme.primaryPurple,
            onEdit: () => _editField('kurum_adi', 'Kurum Adı', data['kurum_adi'] ?? ''),
          ),
          _buildEditableResultCard(
            context: context,
            icon: CupertinoIcons.calendar,
            label: 'Tarih',
            value: data['tarih'] ?? '-',
            color: Colors.blue,
            onEdit: () => _editField('tarih', 'Tarih (GG-AA-YYYY)', data['tarih'] ?? ''),
          ),
          _buildEditableResultCard(
            context: context,
            icon: CupertinoIcons.money_dollar_circle_fill,
            label: 'Toplam Tutar',
            value: '${_formatAmount(data['toplam_tutar'])} TL',
            color: AppTheme.expenseRed,
            isHighlighted: true,
            onEdit: () => _editField('toplam_tutar', 'Toplam Tutar', data['toplam_tutar']?.toString() ?? '0', isNumeric: true),
          ),
          _buildEditableResultCard(
            context: context,
            icon: CupertinoIcons.percent,
            label: 'KDV Tutarı',
            value: '${_formatAmount(data['kdv_tutari'])} TL',
            color: AppTheme.starYellow,
            onEdit: () => _editField('kdv_tutari', 'KDV Tutarı', data['kdv_tutari']?.toString() ?? '0', isNumeric: true),
          ),
          _buildEditableResultCard(
            context: context,
            icon: CupertinoIcons.tag_fill,
            label: 'Kategori',
            value: data['kategori'] ?? 'Diğer',
            color: AppTheme.incomeGreen,
            onEdit: () => _editCategory(),
          ),
          _buildEditableResultCard(
            context: context,
            icon: CupertinoIcons.arrow_up_arrow_down,
            label: 'İşlem Tipi',
            value: data['islem_tipi'] ?? 'Gider',
            color: Colors.orange,
          ),

          const SizedBox(height: 16),

          // OCR ham metin (genişletilebilir)
          if (ocrText.isNotEmpty)
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                collapsedBackgroundColor: AppTheme.cardColorOf(context),
                backgroundColor: AppTheme.cardColorOf(context),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                leading: Icon(CupertinoIcons.doc_plaintext, color: AppTheme.textSecondaryOf(context), size: 18),
                title: Text('OCR Ham Metin', style: TextStyle(color: AppTheme.textSecondaryOf(context), fontSize: 14)),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundOf(context),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: SelectableText(
                      ocrText,
                      style: TextStyle(color: AppTheme.textSecondaryOf(context), fontSize: 12, fontFamily: 'monospace', height: 1.5),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 24),

          // Alt butonlar
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _resetScreen,
                    icon: const Icon(CupertinoIcons.arrow_counterclockwise, size: 18),
                    label: const Text('Yeni Tarama'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textSecondaryOf(context),
                      side: BorderSide(color: AppTheme.textSecondaryOf(context).withValues(alpha: 0.3)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 50,
                  // Bu buton her zaman primaryPurple arkaplanlıdır, metin sabit beyaz kalmalı
                  child: ElevatedButton.icon(
                    onPressed: () => _addAsTransaction(data),
                    icon: const Icon(CupertinoIcons.add_circled, size: 18),
                    label: const Text('İşlem Olarak Ekle'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildEditableResultCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool isHighlighted = false,
    VoidCallback? onEdit,
  }) {
    return GestureDetector(
      onTap: onEdit,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isHighlighted ? color.withValues(alpha: 0.08) : AppTheme.cardColorOf(context),
          borderRadius: BorderRadius.circular(14),
          border: isHighlighted ? Border.all(color: color.withValues(alpha: 0.3)) : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(color: AppTheme.textSecondaryOf(context), fontSize: 12)),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      color: isHighlighted ? color : AppTheme.textPrimaryOf(context),
                      fontSize: isHighlighted ? 18 : 15,
                      fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (onEdit != null)
              Icon(CupertinoIcons.pencil, color: AppTheme.textSecondaryOf(context).withValues(alpha: 0.5), size: 16),
          ],
        ),
      ),
    );
  }

  void _editField(String key, String label, String currentValue, {bool isNumeric = false}) {
    final controller = TextEditingController(text: currentValue);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardColorOf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: AppTheme.textSecondaryOf(ctx).withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text(label, style: TextStyle(color: AppTheme.textPrimaryOf(ctx), fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: isNumeric ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
              style: TextStyle(color: AppTheme.textPrimaryOf(ctx), fontSize: 16),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppTheme.backgroundOf(ctx),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              // Bu buton her zaman primaryPurple arkaplanlıdır, metin sabit beyaz kalmalı
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    if (isNumeric) {
                      _scanResult![key] = double.tryParse(controller.text.replaceAll(',', '.')) ?? 0.0;
                    } else {
                      _scanResult![key] = controller.text;
                    }
                  });
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryPurple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Kaydet', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _editCategory() {
    final categories = ['Market & Gıda', 'Faturalar', 'Ulaşım', 'Eğlence', 'Sağlık', 'Eğitim', 'Giyim', 'Diğer'];
    final current = _scanResult!['kategori'] ?? 'Diğer';

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardColorOf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: AppTheme.textSecondaryOf(ctx).withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text('Kategori Seç', style: TextStyle(color: AppTheme.textPrimaryOf(ctx), fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categories.map((cat) {
                final isSelected = cat == current;
                return GestureDetector(
                  onTap: () {
                    setState(() { _scanResult!['kategori'] = cat; });
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      // Seçili rozet her zaman primaryPurple arkaplanlıdır, metin sabit beyaz kalmalı
                      color: isSelected ? AppTheme.primaryPurple : AppTheme.backgroundOf(ctx),
                      borderRadius: BorderRadius.circular(10),
                      border: isSelected ? null : Border.all(color: AppTheme.textSecondaryOf(ctx).withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.textSecondaryOf(ctx),
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  String _formatAmount(dynamic amount) {
    if (amount == null) return '0,00';
    double val = 0;
    if (amount is num) {
      val = amount.toDouble();
    } else {
      val = double.tryParse(amount.toString()) ?? 0;
    }
    // 1234.56 → "1.234,56" Türk formatı
    String intPart = val.truncate().toString();
    String decPart = ((val - val.truncate()) * 100).round().toString().padLeft(2, '0');

    final buffer = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buffer.write('.');
      buffer.write(intPart[i]);
    }
    return '${buffer.toString()},$decPart';
  }

  void _addAsTransaction(Map<String, dynamic> data) async {
    final provider = context.read<TransactionProvider>();

    // Kategori adından ID bul
    final categoryName = data['kategori'] ?? 'Diğer';
    int? categoryId;
    for (var cat in provider.categories) {
      if (cat['name'] == categoryName ||
          cat['name'].toString().toLowerCase() == categoryName.toString().toLowerCase()) {
        categoryId = cat['id'];
        break;
      }
    }

    // Bulunamazsa "expense" tipindeki ilk kategoriyi al
    if (categoryId == null) {
      for (var cat in provider.categories) {
        if (cat['type'] == 'expense') {
          categoryId = cat['id'];
          break;
        }
      }
    }

    if (categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kategori bulunamadı. Lütfen önce kategori ekleyin.')),
      );
      return;
    }

    // Tutarı parse et
    double amount = 0;
    final rawAmount = data['toplam_tutar'];
    if (rawAmount is num) {
      amount = rawAmount.toDouble();
    } else {
      amount = double.tryParse(rawAmount.toString().replaceAll(',', '.')) ?? 0;
    }

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tutar 0 olamaz. Lütfen tutarı düzenleyin.')),
      );
      return;
    }

    // Tarihi YYYY-MM-DD formatına çevir (API beklentisi)
    String apiDate;
    final tarih = data['tarih'] ?? '';
    final parts = tarih.split('-');
    if (parts.length == 3 && parts[0].length == 2) {
      apiDate = '${parts[2]}-${parts[1]}-${parts[0]}';
    } else {
      apiDate = DateTime.now().toIso8601String().substring(0, 10);
    }

    setState(() { _isLoading = true; });

    final success = await provider.addTransaction(
      categoryId: categoryId,
      amount: amount,
      type: 'expense',
      merchant: data['kurum_adi'],
      description: 'Fiş tarama ile eklendi',
      transactionDate: apiDate,
    );

    if (!mounted) return;
    setState(() { _isLoading = false; });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('İşlem başarıyla eklendi!'),
          backgroundColor: AppTheme.incomeGreen,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('İşlem eklenirken bir hata oluştu.'),
          backgroundColor: AppTheme.expenseRed,
        ),
      );
    }
  }
}
