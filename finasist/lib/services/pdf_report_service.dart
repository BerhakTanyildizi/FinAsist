import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart' show PdfGoogleFonts, Printing;

/// Aylık finansal raporu PDF olarak oluşturup kullanıcıya indirtir.
///
/// Neden `pdf` + `printing` paketleri?
/// - `pdf`: Platform bağımsız, vektör tabanlı PDF belgesi oluşturur (widget benzeri API).
/// - `printing`: Oluşan PDF'i web'de indirme, masaüstünde kaydetme/yazdırma diyaloğu
///   olarak kullanıcıya sunar — tek API ile tüm platformları kapsar.
/// Türkçe karakterler (ç, ş, ğ, ı, ö, ü) standart PDF temel fontlarında yoktur,
/// bu yüzden Unicode kapsamı geniş olan Noto Sans Google Font'u çalışma zamanında yüklenir.
class PdfReportService {
  static const PdfColor _purple = PdfColor.fromInt(0xFF8B5CF6);
  static const PdfColor _green = PdfColor.fromInt(0xFF34D399);
  static const PdfColor _red = PdfColor.fromInt(0xFFFF4D4D);
  static const PdfColor _grey = PdfColor.fromInt(0xFF6B7280);
  static const PdfColor _lightGrey = PdfColor.fromInt(0xFFF2F4FA);

  static const List<PdfColor> _categoryPalette = [
    _purple,
    _green,
    _red,
    PdfColor.fromInt(0xFFFBBF24),
    PdfColor.fromInt(0xFF38BDF8),
    PdfColor.fromInt(0xFFF472B6),
    PdfColor.fromInt(0xFFA78BFA),
    PdfColor.fromInt(0xFF94A3B8),
  ];

  /// Verilen işlem listesinden bir özet PDF'i üretir ve kullanıcıya
  /// indirme/yazdırma diyaloğu açar.
  /// [days] null verilirse TÜM zamanlardaki işlemler dahil edilir (tam dışa aktarım).
  static Future<void> generateAndShare({
    required List<dynamic> transactions,
    required String currencySymbol,
    String userName = 'Finasist Kullanıcısı',
    int? days = 30,
  }) async {
    final bytes = await _buildPdf(
      transactions: transactions,
      currencySymbol: currencySymbol,
      userName: userName,
      days: days,
    );
    final suffix = days == null ? 'tum_veriler' : 'rapor';
    final fileName =
        'finasist_${suffix}_${DateTime.now().toIso8601String().split('T').first}.pdf';
    await Printing.sharePdf(bytes: bytes, filename: fileName);
  }

  static Future<Uint8List> _buildPdf({
    required List<dynamic> transactions,
    required String currencySymbol,
    required String userName,
    int? days = 30,
  }) async {
    final regularFont = await PdfGoogleFonts.notoSansRegular();
    final boldFont = await PdfGoogleFonts.notoSansBold();

    final doc = pw.Document(
      theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
    );

    final now = DateTime.now();
    final start = days == null ? null : now.subtract(Duration(days: days));

    // Seçilen dönemdeki (veya tüm zamanlardaki) işlemleri filtrele
    final periodTxs = transactions.where((tx) {
      final d = tx['transaction_date'];
      if (d == null) return false;
      final date = DateTime.tryParse(d.toString());
      if (date == null) return false;
      if (start == null) return true;
      return date.isAfter(start.subtract(const Duration(days: 1)));
    }).toList()
      ..sort((a, b) => DateTime.parse(b['transaction_date'])
          .compareTo(DateTime.parse(a['transaction_date'])));

    double totalIncome = 0;
    double totalExpense = 0;
    final Map<String, double> categoryTotals = {};

    for (final tx in periodTxs) {
      final amount = double.tryParse(tx['amount'].toString()) ?? 0;
      if (tx['type'] == 'income') {
        totalIncome += amount;
      } else {
        totalExpense += amount;
        final catName = (tx['category']?['name'] ?? 'Diğer').toString();
        categoryTotals[catName] = (categoryTotals[catName] ?? 0) + amount;
      }
    }

    final net = totalIncome - totalExpense;
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(userName, start, now),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          pw.SizedBox(height: 16),
          _buildSummaryRow(totalIncome, totalExpense, net, currencySymbol),
          pw.SizedBox(height: 24),
          if (sortedCategories.isNotEmpty) ...[
            _sectionTitle('Kategori Bazında Giderler'),
            pw.SizedBox(height: 12),
            _buildCategoryChart(sortedCategories, totalExpense, currencySymbol),
            pw.SizedBox(height: 24),
          ],
          _sectionTitle(start == null ? 'İşlem Geçmişi (Tüm Zamanlar)' : 'İşlem Geçmişi'),
          pw.SizedBox(height: 12),
          _buildTransactionTable(periodTxs, currencySymbol),
        ],
      ),
    );

    return doc.save();
  }

  static pw.Widget _buildHeader(String userName, DateTime? start, DateTime end) {
    String fmt(DateTime d) => '${d.day}.${d.month}.${d.year}';
    final periodText = start == null ? 'Tüm Zamanlar' : '${fmt(start)} - ${fmt(end)}';
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Finasist — Finansal Rapor',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: _purple),
            ),
            pw.Text(fmt(end), style: const pw.TextStyle(fontSize: 10, color: _grey)),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          '$userName  •  Dönem: $periodText',
          style: const pw.TextStyle(fontSize: 10, color: _grey),
        ),
        pw.Divider(color: _lightGrey, thickness: 1.5),
      ],
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Column(
      children: [
        pw.Divider(color: _lightGrey, thickness: 0.5),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Finasist — TÜBİTAK 2209-A',
              style: const pw.TextStyle(fontSize: 8, color: _grey),
            ),
            pw.Text(
              'Sayfa ${context.pageNumber} / ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 8, color: _grey),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _sectionTitle(String text) {
    return pw.Text(text, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold));
  }

  static pw.Widget _buildSummaryRow(
    double income,
    double expense,
    double net,
    String symbol,
  ) {
    return pw.Row(
      children: [
        pw.Expanded(child: _statBox('Toplam Gelir', income, symbol, _green)),
        pw.SizedBox(width: 12),
        pw.Expanded(child: _statBox('Toplam Gider', expense, symbol, _red)),
        pw.SizedBox(width: 12),
        pw.Expanded(
          child: _statBox('Net Durum', net, symbol, net >= 0 ? _green : _red),
        ),
      ],
    );
  }

  static pw.Widget _statBox(String label, double value, String symbol, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _lightGrey,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: color, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: _grey)),
          pw.SizedBox(height: 6),
          pw.Text(
            '${value.toStringAsFixed(2)} $symbol',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  /// Kategori bazlı giderleri yatay çubuk grafik olarak çizer.
  static pw.Widget _buildCategoryChart(
    List<MapEntry<String, double>> categories,
    double totalExpense,
    String symbol,
  ) {
    const maxBarWidth = 320.0;
    final top = categories.take(8).toList();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: List.generate(top.length, (i) {
        final entry = top[i];
        final pct = totalExpense > 0 ? (entry.value / totalExpense) : 0.0;
        final color = _categoryPalette[i % _categoryPalette.length];
        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 8),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.SizedBox(
                width: 110,
                child: pw.Text(entry.key, style: const pw.TextStyle(fontSize: 9)),
              ),
              pw.Stack(
                children: [
                  pw.Container(
                    width: maxBarWidth,
                    height: 14,
                    decoration: pw.BoxDecoration(
                      color: _lightGrey,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                  ),
                  pw.Container(
                    width: maxBarWidth * pct.clamp(0.02, 1.0),
                    height: 14,
                    decoration: pw.BoxDecoration(
                      color: color,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(width: 8),
              pw.Text(
                '${entry.value.toStringAsFixed(0)} $symbol (%${(pct * 100).toStringAsFixed(0)})',
                style: const pw.TextStyle(fontSize: 8, color: _grey),
              ),
            ],
          ),
        );
      }),
    );
  }

  static const int _maxTableRows = 300;

  static pw.Widget _buildTransactionTable(List<dynamic> txs, String symbol) {
    if (txs.isEmpty) {
      return pw.Text(
        'Bu dönemde kayıtlı işlem bulunamadı.',
        style: const pw.TextStyle(fontSize: 10, color: _grey),
      );
    }

    final shown = txs.take(_maxTableRows).toList();
    final rows = shown.map((tx) {
      final date = DateTime.tryParse(tx['transaction_date'].toString());
      final dateStr = date != null ? '${date.day}.${date.month}.${date.year}' : '-';
      final desc = (tx['merchant'] ?? tx['description'] ?? '-').toString();
      final cat = (tx['category']?['name'] ?? '-').toString();
      final isIncome = tx['type'] == 'income';
      final amount = double.tryParse(tx['amount'].toString()) ?? 0;
      final amountStr =
          '${isIncome ? '+' : '-'}${amount.toStringAsFixed(2)} $symbol';
      return [dateStr, desc, cat, amountStr];
    }).toList();

    final table = pw.TableHelper.fromTextArray(
      headers: const ['Tarih', 'Açıklama', 'Kategori', 'Tutar'],
      data: rows,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: _purple),
      cellStyle: const pw.TextStyle(fontSize: 8.5),
      cellHeight: 22,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerLeft,
        3: pw.Alignment.centerRight,
      },
      oddRowDecoration: const pw.BoxDecoration(color: _lightGrey),
    );

    if (txs.length <= _maxTableRows) return table;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        table,
        pw.SizedBox(height: 6),
        pw.Text(
          '+ ${txs.length - _maxTableRows} işlem daha (en yeni $_maxTableRows işlem gösterildi).',
          style: const pw.TextStyle(fontSize: 8, color: _grey),
        ),
      ],
    );
  }
}
