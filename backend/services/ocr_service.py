"""
OCR Servisi — EasyOCR tabanlı (v2 — satır-bilincli sıralama)
================================================================
Tesseract yerine EasyOCR kullanılıyor.

İki sütunlu fiş düzeni için kritik düzeltme (v2):
  Fiş formatı:
    TOPKDV   *6,63
    TOPLAM   *195,58
  EasyOCR her bounding box'ı ayrı döndürür. Y-sıralaması bu kutucukları
  karıştırabilir. _sort_reading_order + _group_into_lines ile aynı satırdaki
  kutucuklar boşlukla birleştirilir:
    "TOPKDV *6,63"    ← tek satır, regex bunu doğru yakalar
    "TOPLAM *195,58"  ← tek satır, regex bunu doğru yakalar
"""

import logging
import numpy as np

logger = logging.getLogger("ocr_service")

_reader = None


def _get_reader():
    """EasyOCR reader singleton — ilk çağrıda modeli yükler."""
    global _reader
    if _reader is None:
        logger.info("EasyOCR modeli yükleniyor (ilk çalıştırma ~30sn sürebilir)...")
        import easyocr
        _reader = easyocr.Reader(['tr', 'en'], gpu=False, verbose=False)
        logger.info("EasyOCR hazır.")
    return _reader


def _mid_y(r) -> float:
    """Bounding box'ın dikey orta noktası."""
    return (r[0][0][1] + r[0][2][1]) / 2


def _mid_x(r) -> float:
    """Bounding box'ın yatay orta noktası."""
    return (r[0][0][0] + r[0][2][0]) / 2


def _box_height(r) -> float:
    return abs(r[0][2][1] - r[0][0][1])


def _sort_reading_order(results: list) -> list[list]:
    """
    EasyOCR bounding box'larını okuma sırasına göre satırlara gruplar.

    Fişlerdeki iki sütunlu düzen (isim | fiyat) için kritik:
    - Aynı dikey konumdaki kutucuklar aynı satır kabul edilir.
    - Her satır içinde kutucuklar X koordinatına göre (soldan sağa) sıralanır.

    Returns:
        Liste içinde liste — her iç liste bir satırdaki kutucukları içerir.
    """
    if not results:
        return []

    avg_h = sum(_box_height(r) for r in results) / len(results)
    line_threshold = max(avg_h * 0.65, 5)  # aynı satır eşiği (piksel)

    # Y'ye göre sırala
    sorted_r = sorted(results, key=_mid_y)

    rows: list[list] = []
    current_row = [sorted_r[0]]

    for item in sorted_r[1:]:
        # Mevcut satırın ortalama Y'si
        row_mid_y = sum(_mid_y(r) for r in current_row) / len(current_row)
        if abs(_mid_y(item) - row_mid_y) <= line_threshold:
            current_row.append(item)
        else:
            rows.append(sorted(current_row, key=_mid_x))
            current_row = [item]

    rows.append(sorted(current_row, key=_mid_x))
    return rows


def extract_text(processed_image: np.ndarray, original_image: np.ndarray = None) -> str:
    """
    Görüntüden metin çıkarır.
    Orijinal görüntü varsa tercih edilir (EasyOCR kendi ön işlemeyi yapar).
    Aynı satırdaki bounding box'lar boşlukla birleştirilir.
    """
    reader = _get_reader()
    target = original_image if original_image is not None else processed_image

    try:
        results = reader.readtext(target, detail=1, paragraph=False)
    except Exception as e:
        logger.error("EasyOCR hatası: %s", e)
        return ""

    if not results:
        return ""

    # Güven skoru filtresi
    results = [r for r in results if r[2] > 0.1]

    # Satır-bilincli sıralama
    rows = _sort_reading_order(results)

    # Her satırdaki kutucukları boşlukla birleştir
    lines = [" ".join(item[1] for item in row) for row in rows]

    text = "\n".join(lines)

    # Bölünmüş ondalık düzeltme: "6, 63" → "6,63"  "195, 58" → "195,58"
    # EasyOCR bazen ondalık kısımı ayrı bounding box'a koyar.
    import re as _re
    text = _re.sub(r'(\d+[,.])\s+(\d{2})\b', r'\1\2', text)
    logger.info("EasyOCR: %d satır, %d karakter çıkarıldı", len(lines), len(text))
    return text


def extract_header_text(header_images: list, original_header: np.ndarray = None) -> list[str]:
    """
    Fiş başlık bölgesinden OCR çıkarır.
    """
    reader = _get_reader()
    all_texts = []

    targets = []
    if original_header is not None:
        targets.append(("orijinal", original_header))
    for i, img in enumerate(header_images[:2]):
        targets.append((f"strateji_{i}", img))

    for label, img in targets:
        try:
            results = reader.readtext(img, detail=1, paragraph=False)
            results = [r for r in results if r[2] > 0.2]
            if not results:
                continue
            rows = _sort_reading_order(results)
            lines = [" ".join(item[1] for item in row) for row in rows]
            combined = "\n".join(lines)
            if combined.strip():
                all_texts.append(combined)
                logger.info("Başlık OCR [%s]: %s", label, " | ".join(lines[:3]))
        except Exception as e:
            logger.debug("Başlık OCR hatası [%s]: %s", label, e)

    return all_texts
