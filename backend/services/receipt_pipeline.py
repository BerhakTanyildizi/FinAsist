"""
Fiş Tarama Pipeline Orkestratörü — v4
=======================================
Katmanlı (layered) mimari: her katman başarısız olursa bir sonraki devreye girer.

Pipeline Akışı:
  [Görüntü]
    │
    ├─ 1. Gemini Vision API (varsa)
    │      → Görüntüyü doğrudan LLM'e gönderir, OCR adımı yoktur
    │      → Başarısız/devre dışıysa ↓
    │
    ├─ 2. Groq Vision API (varsa)
    │      → Görüntüyü doğrudan LLM'e gönderir, OCR adımı yoktur
    │      → EasyOCR'ın karakter okuma hatalarını (ör. "BİM"→"BIX") tamamen
    │        ortadan kaldırır çünkü OCR'a hiç ihtiyaç duymaz
    │      → Başarısız/devre dışıysa ↓
    │
    ├─ 3. EasyOCR → LLM Metin (Gemini veya Groq metin modeli)
    │      → Görüntü kalitesi çok düşükse vision modelleri de başarısız
    │        olabilir; bu durumda OCR + metin LLM denemesi yapılır
    │      → Başarısız olursa ↓
    │
    └─ 4. EasyOCR → Geliştirilmiş Regex Parser (SON ÇARE)
           → Hiçbir API çalışmıyorsa bile çalışır

Mimari Desen:
- Facade: router sadece bu modülü çağırır, iç servisler gizlidir.
- Chain of Responsibility: her katman başarısız olursa bir sonrakine geçer.
"""

import logging

from .image_processing import decode_image_from_bytes, decode_image_from_base64
from .ocr_service import extract_text
from .llm_parser import (
    GEMINI_API_KEY,
    GROQ_API_KEY,
    parse_receipt_with_vision,
    parse_receipt_with_groq_vision,
    parse_receipt_with_llm,
    _fallback_regex_parser,
)

logger = logging.getLogger("receipt_pipeline")

_EMPTY = {
    "kurum_adi": "Okunamadı",
    "tarih": "",
    "toplam_tutar": 0.0,
    "kdv_tutari": 0.0,
    "kategori": "Diğer",
    "islem_tipi": "Gider",
    "ocr_text": "",
}


async def _try_vision_layers(image_bytes: bytes) -> dict | None:
    """Gemini Vision ve Groq Vision'ı sırayla dener. İkisi de yoksa/başarısızsa None döner."""
    if GEMINI_API_KEY:
        try:
            result = await parse_receipt_with_vision(image_bytes)
            result["ocr_text"] = ""
            logger.info("=== KATMAN 1 (Gemini Vision) BAŞARILI === %s", result)
            return result
        except Exception as e:
            logger.warning("Katman 1 (Gemini Vision) başarısız: %s", e)

    if GROQ_API_KEY:
        try:
            result = await parse_receipt_with_groq_vision(image_bytes)
            result["ocr_text"] = ""
            logger.info("=== KATMAN 2 (Groq Vision) BAŞARILI === %s", result)
            return result
        except Exception as e:
            logger.warning("Katman 2 (Groq Vision) başarısız: %s", e)

    return None


async def process_receipt_image(image_bytes: bytes) -> dict:
    """Fiş görüntüsünü (bytes) uçtan uca işler ve yapılandırılmış veri döndürür."""

    # ── KATMAN 1 & 2: Vision modelleri (OCR'sız, en doğru) ──
    vision_result = await _try_vision_layers(image_bytes)
    if vision_result is not None:
        return vision_result

    logger.info("Vision katmanları kullanılamadı — EasyOCR'a geçiliyor...")

    # ── KATMAN 3 & 4: EasyOCR ile metin çıkar ──
    img = decode_image_from_bytes(image_bytes)
    ocr_text = extract_text(img)
    logger.info("=== OCR ÇIKTISI ===\n%s\n=== OCR SONU ===", ocr_text)

    if not ocr_text.strip():
        logger.warning("OCR hiç metin çıkaramadı.")
        return _EMPTY.copy()

    # ── KATMAN 3: EasyOCR metni → LLM (Gemini veya Groq) ──
    if GEMINI_API_KEY or GROQ_API_KEY:
        try:
            result = await parse_receipt_with_llm(ocr_text)
            result["ocr_text"] = ocr_text
            logger.info("=== KATMAN 3 (LLM Metin) BAŞARILI === %s", result)
            return result
        except Exception as e:
            logger.warning("Katman 3 başarısız (%s) — regex fallback devreye giriyor...", e)

    # ── KATMAN 4: Geliştirilmiş Regex Parser ──
    parsed = _fallback_regex_parser(ocr_text)
    parsed["ocr_text"] = ocr_text
    logger.info("=== KATMAN 4 (Regex) SONUCU === %s", parsed)
    return parsed


async def process_receipt_base64(base64_string: str) -> dict:
    """Base64 kodlanmış fiş görüntüsünü uçtan uca işler."""
    import base64 as b64

    raw = base64_string.split(",", 1)[1] if "," in base64_string else base64_string
    image_bytes = b64.b64decode(raw)

    # ── KATMAN 1 & 2: Vision modelleri ──
    vision_result = await _try_vision_layers(image_bytes)
    if vision_result is not None:
        return vision_result

    logger.info("Vision katmanları kullanılamadı — EasyOCR'a geçiliyor...")

    # ── KATMAN 3 & 4: EasyOCR ──
    img = decode_image_from_base64(base64_string)
    ocr_text = extract_text(img)
    logger.info("=== OCR ÇIKTISI ===\n%s\n=== OCR SONU ===", ocr_text)

    if not ocr_text.strip():
        return _EMPTY.copy()

    if GEMINI_API_KEY or GROQ_API_KEY:
        try:
            result = await parse_receipt_with_llm(ocr_text)
            result["ocr_text"] = ocr_text
            return result
        except Exception as e:
            logger.warning("Katman 3 (base64) başarısız (%s) — regex fallback...", e)

    parsed = _fallback_regex_parser(ocr_text)
    parsed["ocr_text"] = ocr_text
    return parsed
