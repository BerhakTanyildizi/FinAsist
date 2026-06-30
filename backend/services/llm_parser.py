"""
LLM Tabanlı Yapılandırılmış Veri Çıkarımı Servisi
====================================================
OCR'dan çıkan ham metni bir Büyük Dil Modeline (LLM) göndererek
yapılandırılmış JSON verisine dönüştürür.

Neden LLM Kullanıyoruz?
- Fiş formatları standart değildir: her mağaza/restoran farklı düzende
  yazdırır. Regex veya kural tabanlı ayrıştırma (parsing) çok kırılgan olur.
- LLM, doğal dil anlama yeteneği ile farklı formatlardaki fişlerden
  aynı yapıda veri çıkarabilir.
- Eksik veya bozuk OCR çıktısını bile anlamlandırabilir (bağlam tahmini).

Mimari Tercih:
- Google Gemini API kullanıyoruz (ücretsiz katman mevcut, Türkçe desteği iyi).
- response_mime_type="application/json" ile modelden garanti JSON alıyoruz.
- Fallback mekanizması: LLM başarısız olursa regex tabanlı basit parser devreye girer.
- 429 (Rate Limit) hatalarında exponential backoff ile 3 kez retry yapılır.
"""

import os
import json
import re
import asyncio
import logging
from datetime import datetime
from dotenv import load_dotenv

load_dotenv()

logger = logging.getLogger("llm_parser")

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY") or None
GEMINI_MODEL = os.getenv("GEMINI_MODEL", "gemini-2.0-flash")
GROQ_API_KEY = os.getenv("GROQ_API_KEY") or None
GROQ_MODEL = "llama-3.3-70b-versatile"
# Groq'un görüntü okuyabilen (vision) modeli — OCR adımını tamamen atlar
GROQ_VISION_MODEL = "meta-llama/llama-4-scout-17b-16e-instruct"

# AQ. formatındaki key'ler OAuth2 token'dır, API key değil.
# Bu format Gemini REST API ile çalışmaz — boşa 401 denemesi yapmamak için devre dışı.
if GEMINI_API_KEY and GEMINI_API_KEY.startswith("AQ."):
    logger.warning(
        "GEMINI_API_KEY 'AQ.' formatında (OAuth token). "
        "Gemini REST API bu formatı desteklemiyor. "
        "Lütfen Google AI Studio'dan 'AIza...' formatında key alın. "
        "Şimdilik Gemini devre dışı, EasyOCR+regex kullanılacak."
    )
    GEMINI_API_KEY = None


# ═══════════════════════════════════════════════════════════════
# Bilinen Türk Kurum/Mağaza Sözlüğü (Fuzzy Matching için)
# ═══════════════════════════════════════════════════════════════
# OCR çıktısı bu listedeki isimlerle karşılaştırılır.
# Levenshtein mesafesi ile en yakın eşleşme bulunur.
# Bu sayede "Migrss" → "Migros", "BM" → "BİM" gibi düzeltmeler yapılır.

KNOWN_MERCHANTS = [
    # ─── Market / Süpermarket ───
    "Migros", "BİM", "A101", "ŞOK", "CarrefourSA", "Carrefour",
    "Metro", "Macro Center", "Hakmar", "Onur Market", "File Market",
    "Bizim Toptan", "Kim Market", "Pehlivanoğlu", "Tarsu",
    "Mopaş", "Adese", "Özdilek", "Happy Center", "Beğendik",
    "D&R", "Çağdaş", "Kipa", "Real", "Tansaş", "Uyum",
    "Yunus Market", "İstanbul Market", "Ekomini", "Seyhanlar",
    "Groseri", "Snowy", "Şok Market", "Altunbilekler",
    "Çetinkaya", "Show", "Lidl", "Walmart", "Tesco", "Aldi",
    "Rammar", "Doğuş", "Makro Market",
    # ─── Eczane ───
    "Eczane", "Eczacıbaşı", "Ataşehir Eczane", "Farmasi",
    "Gratis", "Watsons", "Rossmann",
    # ─── Akaryakıt ───
    "Shell", "Opet", "BP", "Total", "Petrol Ofisi", "Aytemiz",
    "Lukoil", "GO", "M Oil", "TP", "SOCAR", "Alpet",
    # ─── Restoran / Cafe ───
    "Starbucks", "Burger King", "McDonald's", "KFC", "Popeyes",
    "Domino's", "Pizza Hut", "Little Caesars", "Sbarro",
    "Subway", "Arby's", "Tavuk Dünyası", "Köfteci Yusuf",
    "Baydöner", "Sultanahmet Köftecisi", "Simit Sarayı",
    "Kahve Dünyası", "Gloria Jean's", "Mado", "Midpoint",
    "Big Chefs", "Eataly", "Nusret", "Günaydın",
    "Çiğköftem", "Usta Dönerci", "Dönerci", "Pideci",
    # ─── Giyim ───
    "Zara", "H&M", "LC Waikiki", "DeFacto", "Koton", "Mavi",
    "Colin's", "İpekyol", "Vakko", "Beymen", "Network",
    "Boyner", "YKM", "Fabrika", "Twist", "Oxxo",
    "Pull & Bear", "Bershka", "Massimo Dutti", "Mango",
    "Nike", "Adidas", "Puma", "New Balance", "Skechers",
    "Flo", "Ayakkabı Dünyası", "Hotiç", "Derimod",
    # ─── Teknoloji / Elektronik ───
    "Teknosa", "Media Markt", "Vatan Bilgisayar", "Apple Store",
    "Samsung", "Hepsiburada", "Trendyol", "N11",
    # ─── Mobilya / Ev ───
    "IKEA", "Koçtaş", "Bauhaus", "Tekzen", "Praktiker",
    "Evidea", "Bellona", "İstikbal", "Çilek", "Yataş",
    # ─── Kırtasiye / Kitap ───
    "D&R", "Kitapyurdu", "İdefix", "Pandora",
    # ─── Fatura / Telekomünikasyon ───
    "Turkcell", "Vodafone", "Türk Telekom", "Superonline",
    "TurkNet", "TTNET", "Digiturk", "D-Smart", "beIN",
    # ─── Diğer ───
    "PTT", "İETT", "İstanbulkart", "Marmaray",
    "THY", "Pegasus", "AnadoluJet", "SunExpress",
]

# Normalize edilmiş sözlük (küçük harf, Türkçe karakter normalize)
_MERCHANT_LOOKUP: dict[str, str] = {}
for _m in KNOWN_MERCHANTS:
    _key = _m.lower().replace("İ", "i").replace("ı", "i").replace("ö", "o") \
        .replace("ü", "u").replace("ş", "s").replace("ç", "c").replace("ğ", "g")
    _MERCHANT_LOOKUP[_key] = _m


def _normalize_text(text: str) -> str:
    """Türkçe karakterleri normalize eder, küçük harfe çevirir."""
    return text.lower().replace("İ", "i").replace("ı", "i").replace("ö", "o") \
        .replace("ü", "u").replace("ş", "s").replace("ç", "c").replace("ğ", "g")


def _levenshtein_distance(s1: str, s2: str) -> int:
    """İki string arasındaki Levenshtein düzenleme mesafesini hesaplar."""
    if len(s1) < len(s2):
        return _levenshtein_distance(s2, s1)
    if len(s2) == 0:
        return len(s1)

    prev_row = range(len(s2) + 1)
    for i, c1 in enumerate(s1):
        curr_row = [i + 1]
        for j, c2 in enumerate(s2):
            insertions = prev_row[j + 1] + 1
            deletions = curr_row[j] + 1
            substitutions = prev_row[j] + (c1 != c2)
            curr_row.append(min(insertions, deletions, substitutions))
        prev_row = curr_row

    return prev_row[-1]


def _similarity_ratio(s1: str, s2: str) -> float:
    """İki string arasındaki benzerlik oranı (0.0–1.0)."""
    if not s1 or not s2:
        return 0.0
    max_len = max(len(s1), len(s2))
    distance = _levenshtein_distance(s1, s2)
    return 1.0 - (distance / max_len)


def fuzzy_match_merchant(ocr_text: str, threshold: float = 0.55) -> tuple[str | None, float]:
    """
    OCR çıktısını bilinen kurum sözlüğüyle fuzzy match eder.

    Hem kelimeleri teker teker hem de 2-3 kelimelik n-gram'ları dener.
    En yüksek benzerlik skoru threshold'u aşıyorsa eşleşmeyi döndürür.

    Returns:
        (kurum_adı, skor) veya (None, 0.0)
    """
    normalized = _normalize_text(ocr_text)
    # Özel karakterleri temizle
    cleaned = re.sub(r"[^a-z0-9\s]", " ", normalized)
    words = cleaned.split()

    best_match = None
    best_score = 0.0

    # Tüm 1, 2 ve 3 kelimelik kombinasyonları dene
    for n in range(1, 4):
        for i in range(len(words) - n + 1):
            ngram = " ".join(words[i:i+n])
            if len(ngram) < 2:
                continue

            for merchant_key, merchant_original in _MERCHANT_LOOKUP.items():
                # Tam eşleşme kontrolü (en hızlı)
                if ngram == merchant_key:
                    return merchant_original, 1.0

                # İçerme kontrolü — kısa ngram'ların uzun isimlere yanlış eşleşmesini önle
                # Örnek: "market" tek başına "Onur Market"e eşleşmemeli
                if merchant_key in ngram or ngram in merchant_key:
                    min_len = min(len(ngram), len(merchant_key))
                    max_len = max(len(ngram), len(merchant_key))
                    coverage = min_len / max_len if max_len > 0 else 0
                    if coverage >= 0.60:  # En az %60 örtüşme şart
                        score = 0.85 * coverage
                        if score > best_score:
                            best_score = score
                            best_match = merchant_original
                    continue

                # Fuzzy benzerlik
                score = _similarity_ratio(ngram, merchant_key)
                if score > best_score and score >= threshold:
                    best_score = score
                    best_match = merchant_original

    return best_match, best_score


def _is_quality_text(text: str) -> bool:
    """
    OCR çıktısının okunabilir (kaliteli) olup olmadığını kontrol eder.
    Tesseract'ın ürettiği sembol karmaşası gibi çöp metinleri filtreler.
    Alfabetik karakter oranı %35'in altındaysa çöp sayılır.
    """
    if not text or len(text.strip()) < 3:
        return False
    alpha_count = sum(1 for c in text if c.isalpha())
    return alpha_count / max(len(text.strip()), 1) > 0.35


def extract_merchant_from_headers(header_texts: list[str], full_ocr_text: str = "") -> str:
    """
    Birden fazla başlık OCR sonucundan en iyi kurum adını çıkarır.

    Strateji:
    1. Kalite filtresi — çöp OCR sonuçlarını ele (sembol karmaşası vs.)
    2. Her kaliteli başlık metnini bilinen kurum sözlüğüyle fuzzy match et
    3. Eşleşme bulunamazsa tüm OCR metninde de dene
    4. Sözlükte yoksa, ana OCR metninin ilk anlamlı satırını direkt kullan
       (bilinmeyen lokal mağazalar için — ör. "TURUNCU MARKET")
    5. Son çare: başlık metinlerinden en iyi satırı seç

    Args:
        header_texts: Farklı OCR stratejilerinden gelen başlık metinleri
        full_ocr_text: Tüm fişin OCR metni (fallback olarak kullanılır)

    Returns:
        En iyi kurum adı tahmini
    """
    best_merchant = None
    best_score = 0.0

    # 1. Kalite filtresi uygulayarak her başlık metnini sözlükle karşılaştır
    for header in header_texts:
        if not _is_quality_text(header):
            logger.debug("Çöp OCR atlandı: '%s'", header[:40])
            continue
        merchant, score = fuzzy_match_merchant(header)
        if score > best_score:
            best_score = score
            best_merchant = merchant
            logger.info("Başlık match: '%s' → '%s' (skor: %.2f)", header[:50], merchant, score)

    # 2. Tüm OCR metninde de dene
    if best_score < 0.7 and full_ocr_text:
        merchant, score = fuzzy_match_merchant(full_ocr_text)
        if score > best_score:
            best_score = score
            best_merchant = merchant
            logger.info("Tam metin match: '%s' (skor: %.2f)", merchant, score)

    # 3. Yeterli skor varsa döndür
    if best_merchant and best_score >= 0.55:
        logger.info("Kurum adı belirlendi (sözlük): '%s' (skor: %.2f)", best_merchant, best_score)
        return best_merchant

    # 4. Sözlükte bulunamadı — ana OCR metninin ilk anlamlı satırını kullan
    #    Bu, "TURUNCU MARKET" gibi lokal/bilinmeyen mağazaları doğru yakalar.
    if full_ocr_text:
        for line in full_ocr_text.strip().split("\n"):
            cleaned = line.strip()
            if len(cleaned) < 3:
                continue
            # Sadece rakam/sembolden oluşan satırları atla (tarih, fiyat vb.)
            if re.match(r'^[\d\s./:,\-+()]+$', cleaned):
                continue
            letter_ratio = sum(1 for c in cleaned if c.isalpha()) / max(len(cleaned), 1)
            if letter_ratio > 0.4 and len(cleaned) <= 60:
                name = _clean_merchant_name(cleaned)
                logger.info("Kurum adı (ham OCR ilk satır): '%s'", name)
                return name

    # 5. Son çare: başlık metinlerinden en iyi satırı seç
    best_raw_name = "Bilinmiyor"
    best_raw_score = 0

    for header in header_texts:
        if not _is_quality_text(header):
            continue
        lines = header.strip().split("\n")
        for line in lines:
            cleaned = line.strip()
            if len(cleaned) < 3:
                continue
            letter_count = sum(1 for c in cleaned if c.isalpha())
            letter_ratio = letter_count / max(len(cleaned), 1)
            if re.match(r'^[\d\s./:,\-+()]+$', cleaned):
                continue
            if letter_ratio > 0.4 and 3 <= len(cleaned) <= 60:
                score = letter_ratio * min(letter_count, 20)
                if score > best_raw_score:
                    best_raw_score = score
                    best_raw_name = _clean_merchant_name(cleaned)

    return best_raw_name


EXTRACTION_PROMPT = """Sen bir Türk fişi/faturası analiz uzmanısın. Aşağıda OCR ile taranmış ham metin var.
Bu metinden bilgileri çıkar ve SADECE geçerli bir JSON nesnesi döndür. Açıklama ekleme.

Kurallar:
1. "kurum_adi": Fişin ait olduğu işletme/mağaza adı (genellikle ilk satır). Bulamazsan "Bilinmiyor".
2. "tarih": Fişin tarihi, DD-MM-YYYY formatında. Bulamazsan bugünü kullan.
3. "toplam_tutar": Müşterinin ödediği TOPLAM tutar.
   - TOPLAM, TOP veya TOTAL satırındaki değeri al.
   - KREDI/NAKİT satırı da aynı değeri gösterir, kullanabilirsin.
   - KDV (TOPKDV) zaten TOPLAM'ın İÇİNDEDİR — ayrıca ekleme, sadece TOPLAM satırını al.
   - OCR hatalı olabilir: "*304,31" veya "+304,31" → 304.31 anlamına gelir.
   - Bulamazsan 0.0.
4. "kdv_tutari": TOPKDV veya KDV satırındaki tutar. Bulamazsan 0.0.
5. "kategori": Şu listeden seç:
   "Market & Gıda", "Faturalar", "Ulaşım", "Eğlence", "Sağlık", "Eğitim", "Giyim", "Diğer"
6. "islem_tipi": Her zaman "Gider".

JSON:
{"kurum_adi": "...", "tarih": "DD-MM-YYYY", "toplam_tutar": 0.0, "kdv_tutari": 0.0, "kategori": "...", "islem_tipi": "Gider"}

OCR Metni:
"""

VISION_PROMPT = (
    "Sen bir Türk fişi/faturası analiz uzmanısın. Görseldeki fişten bilgileri çıkar, "
    "SADECE geçerli JSON döndür. Açıklama ekleme.\n\n"
    "Kurallar:\n"
    '1. "kurum_adi": Mağaza/işletme adı (genellikle en üstte). Bulamazsan "Bilinmiyor".\n'
    '2. "tarih": DD-MM-YYYY formatında. Bulamazsan bugün.\n'
    '3. "toplam_tutar": TOPLAM/TOTAL/KREDI satırındaki değer. '
    'KDV zaten içindedir, ekleme. Virgül yerine nokta kullan.\n'
    '4. "kdv_tutari": TOPKDV/KDV satırındaki değer. Bulamazsan 0.0.\n'
    '5. "kategori": "Market & Gıda", "Faturalar", "Ulaşım", "Eğlence", "Sağlık", "Eğitim", "Giyim", "Diğer"\n'
    '6. "islem_tipi": Her zaman "Gider".\n\n'
    'JSON: {"kurum_adi":"...","tarih":"DD-MM-YYYY","toplam_tutar":0.0,"kdv_tutari":0.0,"kategori":"...","islem_tipi":"Gider"}'
)

MAX_RETRIES = 4
INITIAL_BACKOFF = 2  # saniye


async def parse_receipt_with_groq_vision(image_bytes: bytes) -> dict:
    """
    Fiş görüntüsünü doğrudan Groq'un vision modeline gönderir.
    OCR adımını tamamen atlar — EasyOCR'ın karakter okuma hatalarını
    (ör. "BİM" → "BIX") tamamen ortadan kaldırır çünkü model görseli
    kendisi "görür", OCR çıktısına bağımlı değildir.
    """
    if not GROQ_API_KEY:
        raise ValueError("GROQ_API_KEY tanımlı değil — Groq Vision kullanılamaz.")

    import base64 as b64
    import httpx

    image_base64 = b64.b64encode(image_bytes).decode("utf-8")
    url = "https://api.groq.com/openai/v1/chat/completions"
    headers = {"Authorization": f"Bearer {GROQ_API_KEY}", "Content-Type": "application/json"}
    payload = {
        "model": GROQ_VISION_MODEL,
        "messages": [
            {
                "role": "user",
                "content": [
                    {"type": "text", "text": VISION_PROMPT},
                    {"type": "image_url", "image_url": {"url": f"data:image/jpeg;base64,{image_base64}"}},
                ],
            }
        ],
        "temperature": 0.1,
        "response_format": {"type": "json_object"},
    }
    async with httpx.AsyncClient(timeout=30.0) as client:
        response = await client.post(url, json=payload, headers=headers)
        response.raise_for_status()
    data = response.json()
    raw_text = data["choices"][0]["message"]["content"]
    return _validate_and_clean(json.loads(raw_text))


async def parse_receipt_with_groq(ocr_text: str) -> dict:
    """
    Groq API (Llama 3.3 70B) ile OCR metnini ayrıştırır.
    groq.com'dan ücretsiz key alınabilir — günde 14.400 istek limiti.
    """
    import httpx
    url = "https://api.groq.com/openai/v1/chat/completions"
    headers = {"Authorization": f"Bearer {GROQ_API_KEY}", "Content-Type": "application/json"}
    payload = {
        "model": GROQ_MODEL,
        "messages": [
            {"role": "system", "content": "Sen bir fiş/fatura analiz uzmanısın. Sadece geçerli JSON döndür."},
            {"role": "user", "content": EXTRACTION_PROMPT + ocr_text},
        ],
        "temperature": 0.1,
        "response_format": {"type": "json_object"},
    }
    async with httpx.AsyncClient(timeout=30.0) as client:
        response = await client.post(url, json=payload, headers=headers)
        response.raise_for_status()
    data = response.json()
    raw_text = data["choices"][0]["message"]["content"]
    return _validate_and_clean(json.loads(raw_text))


async def parse_receipt_with_llm(ocr_text: str) -> dict:
    """
    OCR metnini LLM ile ayrıştırır.
    Öncelik sırası: Gemini → Groq → Regex Fallback
    """
    # Gemini
    if GEMINI_API_KEY:
        try:
            return await _call_gemini_with_retry(ocr_text)
        except Exception as e:
            logger.warning("Gemini başarısız: %s", e)

    # Groq (ücretsiz, hızlı)
    if GROQ_API_KEY:
        try:
            result = await parse_receipt_with_groq(ocr_text)
            logger.info("Groq parse başarılı.")
            return result
        except Exception as e:
            logger.warning("Groq başarısız: %s — Regex fallback devreye giriyor.", e)

    # Regex fallback
    logger.info("Tüm LLM'ler devre dışı/başarısız — regex parser kullanılıyor.")
    return _fallback_regex_parser(ocr_text)


async def parse_receipt_with_vision(image_bytes: bytes) -> dict:
    """
    Fiş görüntüsünü doğrudan Gemini Vision API'ye gönderir.
    OCR adımını tamamen atlayarak çok daha yüksek doğruluk sağlar.
    """
    if not GEMINI_API_KEY:
        raise ValueError("GEMINI_API_KEY tanımlı değil — Vision kullanılamaz.")
    import base64 as b64
    image_base64 = b64.b64encode(image_bytes).decode("utf-8")
    return await _call_gemini_vision_with_retry(image_base64)


async def parse_receipt_base64_with_vision(base64_string: str) -> dict:
    """
    Base64 kodlanmış fiş görüntüsünü doğrudan Gemini Vision API'ye gönderir.
    """
    if not GEMINI_API_KEY:
        raise ValueError("GEMINI_API_KEY tanımlı değil — Vision kullanılamaz.")
    if "," in base64_string:
        base64_string = base64_string.split(",", 1)[1]
    return await _call_gemini_vision_with_retry(base64_string)


async def _call_gemini_vision_with_retry(image_base64: str) -> dict:
    """Exponential backoff ile Gemini Vision API'yi çağırır."""
    import httpx
    last_error = None
    for attempt in range(MAX_RETRIES):
        try:
            return await _call_gemini_vision(image_base64)
        except httpx.HTTPStatusError as e:
            last_error = e
            if e.response.status_code == 429:
                wait_time = INITIAL_BACKOFF * (2 ** attempt)
                logger.info("Gemini Vision 429 — %d. deneme, %ds bekleniyor...", attempt + 1, wait_time)
                await asyncio.sleep(wait_time)
            else:
                raise
        except Exception:
            raise
    raise last_error


async def _call_gemini_vision(image_base64: str) -> dict:
    """
    Gemini Vision API — görüntüyü doğrudan modele gönderir.
    Güvenlik: API key URL query param'ında DEĞİL, sadece header'da gönderilir.
    Sebep: httpx, isteklerin tam URL'sini INFO seviyesinde loglar — key URL'de
    olsaydı her çağrıda sunucu loglarına açık metin olarak yazılırdı.
    """
    import httpx
    url = f"https://generativelanguage.googleapis.com/v1beta/models/{GEMINI_MODEL}:generateContent"
    headers = {"x-goog-api-key": GEMINI_API_KEY, "Content-Type": "application/json"}
    payload = {
        "contents": [{
            "parts": [
                {"text": VISION_PROMPT},
                {"inlineData": {"mimeType": "image/jpeg", "data": image_base64}}
            ]
        }],
        "generationConfig": {
            "response_mime_type": "application/json",
            "temperature": 0.1,
        }
    }
    async with httpx.AsyncClient(timeout=30.0) as client:
        response = await client.post(url, json=payload, headers=headers)
        response.raise_for_status()
    data = response.json()
    raw_text = data["candidates"][0]["content"]["parts"][0]["text"]
    return _validate_and_clean(json.loads(raw_text))


async def _call_gemini_with_retry(ocr_text: str) -> dict:
    """
    Exponential backoff ile Gemini API'yi çağırır.
    429 (Rate Limit) alındığında MAX_RETRIES kez tekrar dener.
    İlk bekleme INITIAL_BACKOFF saniye, her denemede 2 katına çıkar.
    """
    import httpx

    last_error = None

    for attempt in range(MAX_RETRIES):
        try:
            return await _call_gemini(ocr_text)
        except httpx.HTTPStatusError as e:
            last_error = e
            if e.response.status_code == 429:
                wait_time = INITIAL_BACKOFF * (2 ** attempt)
                logger.info(
                    "Gemini 429 Rate Limit — %d. deneme, %ds bekleniyor...",
                    attempt + 1, wait_time
                )
                await asyncio.sleep(wait_time)
            else:
                raise
        except Exception as e:
            raise

    raise last_error


async def _call_gemini(ocr_text: str) -> dict:
    """
    Google Gemini API'yi çağırır.
    Güvenlik: API key sadece x-goog-api-key header'ında gönderilir, URL'de DEĞİL
    (bkz. _call_gemini_vision docstring'i — httpx URL'leri loglar).
    """
    import httpx

    url = f"https://generativelanguage.googleapis.com/v1beta/models/{GEMINI_MODEL}:generateContent"
    headers = {"x-goog-api-key": GEMINI_API_KEY, "Content-Type": "application/json"}

    payload = {
        "contents": [{
            "parts": [{"text": EXTRACTION_PROMPT + ocr_text}]
        }],
        "generationConfig": {
            "response_mime_type": "application/json",
            "temperature": 0.1,
        }
    }

    async with httpx.AsyncClient(timeout=30.0) as client:
        response = await client.post(url, json=payload, headers=headers)
        response.raise_for_status()

    data = response.json()
    raw_text = data["candidates"][0]["content"]["parts"][0]["text"]
    return _validate_and_clean(json.loads(raw_text))


def _fallback_regex_parser(ocr_text: str, header_texts: list[str] | None = None) -> dict:
    """
    LLM erişilemezken devreye giren regex tabanlı ayrıştırıcı.

    Fiş formatı genellikle:
      - İlk birkaç satır: mağaza adı, adres, telefon
      - Orta kısım: ürün listesi
      - Alt kısım: SUBTOTAL, TAX, TOTAL, ödeme bilgileri, tarih

    Strateji:
      1. Kurum adını başlık OCR + fuzzy matching ile belirle
      2. TOTAL/TOPLAM satırındaki tutarı yakala
      3. TAX/KDV satırındaki tutarı yakala
      4. Tarihi çeşitli formatlarla yakala (MM/DD/YYYY, DD.MM.YYYY vb.)
      5. Anahtar kelime tabanlı kategori tahmini
    """
    result = {
        "kurum_adi": "Bilinmiyor",
        "tarih": datetime.now().strftime("%d-%m-%Y"),
        "toplam_tutar": 0.0,
        "kdv_tutari": 0.0,
        "kategori": "Diğer",
        "islem_tipi": "Gider",
    }

    # OCR hata düzeltmesi: Tesseract/EasyOCR'ın sık yaptığı karakter hataları
    # Bu düzeltme sadece tarih/sayı bağlamında uygulanır (tam metni bozmamak için)
    ocr_corrected = (
        ocr_text
        .replace("'", "7")   # ' → 7 (yıl sonundaki tırnak hatası)
    )

    lines = ocr_text.strip().split("\n")

    # --- Kurum Adı ---
    # Strateji: EasyOCR ilk satırı çok iyi okunur, onu birincil kaynak olarak kullan.
    # Sözlükte varsa fuzzy eşleştirme ile düzelt (ör. "SOK" → "ŞOK").
    # Başlık OCR ayrıca gönderilmişse onu kullan.
    if header_texts:
        merchant = extract_merchant_from_headers(header_texts, ocr_text)
        result["kurum_adi"] = merchant
    else:
        # 1. Önce OCR'ın ilk anlamlı satırını al (lokal mağazalar için doğru)
        first_line_name = None
        for line in lines:
            cleaned = line.strip()
            if len(cleaned) < 3:
                continue
            if re.match(r'^[\d\s./:,\-+()]+$', cleaned):
                continue
            letter_ratio = sum(1 for c in cleaned if c.isalpha()) / max(len(cleaned), 1)
            if letter_ratio > 0.4:
                first_line_name = _clean_merchant_name(cleaned)
                break

        # 2. Sözlükte bir eşleşme var mı? (Yüksek eşik: 0.75 — "market" tek başına eşleşmesin)
        merchant, score = fuzzy_match_merchant(ocr_text)
        if merchant and score >= 0.75:
            result["kurum_adi"] = merchant
            logger.info("Kurum adı (fuzzy): '%s' (skor: %.2f)", merchant, score)
        elif first_line_name:
            result["kurum_adi"] = first_line_name
            logger.info("Kurum adı (ilk satır): '%s'", first_line_name)
        elif merchant and score >= 0.55:
            result["kurum_adi"] = merchant
            logger.info("Kurum adı (düşük skorlu fuzzy): '%s' (skor: %.2f)", merchant, score)

    # --- Toplam Tutar ---
    # Fişlerde tutar genellikle şu kalıplarla gelir:
    #   TOTAL     90.32    veya   TOPLAM: 156,90 TL   veya   *TOPLAM   45.00
    # Birden fazla TOTAL satırı olabilir (SUBTOTAL, TOTAL, GRAND TOTAL)
    # En son bulunan TOTAL değerini al (genellikle nihai toplam sonda olur)
    total_amount = 0.0
    amount_patterns = [
        # BİM özel: "TOPLAM TOPKDV *304,31 +22,01" — iki etiket aynı satırda
        r"TOPLAM\s+TOPKDV\s*[*]?\s*(\d+[.,]\d{2})",
        # "TOTAL     90.32" veya "TOPLAM: 156,90 TL" — tutar sağda
        r"(?:GRAND\s*TOTAL|GENEL\s*TOPLAM)[\s:]*[*]?\s*[$€₺£]?\s*(\d+[.,]\d{2})",
        r"(?:TOTAL|TOPLAM|TUTAR|TOP\.?\s*TUT)[\s:]*[*]?\s*[$€₺£]?\s*(\d+[.,]\d{2})",
        # "90,32 TOTAL PURCHASE" veya "90.32 TOPLAM" — tutar solda
        r"(\d+[.,]\d{2})\s+(?:TOTAL|TOPLAM)",
    ]
    for pattern in amount_patterns:
        matches = re.findall(pattern, ocr_text, re.IGNORECASE)
        if matches:
            amount_str = matches[-1].replace(",", ".")
            total_amount = float(amount_str)
            break

    # SUBTOTAL varsa ve TOTAL bulunamadıysa, SUBTOTAL'ı kullan
    if total_amount == 0.0:
        sub_patterns = [
            r"(?:SUBTOTAL|ARA\s*TOPLAM)[\s:]*[*]?\s*(\d+[.,]\d{2})",
            r"(\d+[.,]\d{2})\s+(?:SUBTOTAL|ARA\s*TOPLAM)",
        ]
        for pattern in sub_patterns:
            match = re.search(pattern, ocr_text, re.IGNORECASE)
            if match:
                total_amount = float(match.group(1).replace(",", "."))
                break

    # Hâlâ 0 ise, satır sonundaki en büyük sayıyı bul (son çare)
    if total_amount == 0.0:
        all_amounts = re.findall(r"(\d+[.,]\d{2})\s*$", ocr_text, re.MULTILINE)
        if all_amounts:
            amounts_float = [float(a.replace(",", ".")) for a in all_amounts]
            total_amount = max(amounts_float)

    result["toplam_tutar"] = total_amount

    # --- KDV / Tax ---
    # Türk fişlerinde KDV satırı çeşitli biçimlerde gelir:
    #   "KDV *1,28"  |  "KDV: 1.28"  |  "TOP KDV  1,28 TL"
    # Ayrıca EasyOCR "*1,28" → "*1,28" doğru okuyabilir.
    kdv_amount = 0.0
    kdv_patterns = [
        # BİM özel: "TOPLAM TOPKDV *304,31 +22,01" — KDV tutar en sonda (+22,01)
        r"TOPLAM\s+TOPKDV\s*[*]?\s*\d+[.,]\d{2}\s*[+*]?\s*(\d+[.,]\d{2})",
        # "KDV *1,28" veya "KDV: 1,28" — yıldız/iki nokta öncesi, sonrası tutar
        r"(?:KDV|TOPKDV|TOP\.?\s*KDV|TAX|TAK|VAT)[\s:*]+(\d+[.,]\d{1,2})",
        # "KDV %8 *1,28" gibi oran içeren satırlar
        r"(?:KDV|TAX|VAT)[\s:]*\d*[.,]?\d*\s*%?\s*[Xx]?\s*[*]?\s*(\d+[.,]\d{2})",
        # Tutar sonda: "1,28 KDV"
        r"(\d+[.,]\d{2})\s+(?:TAX|KDV|VAT)",
    ]
    for pattern in kdv_patterns:
        match = re.search(pattern, ocr_text, re.IGNORECASE)
        if match:
            kdv_amount = float(match.group(1).replace(",", "."))
            break

    # KDV bulunamadıysa ve hem TOTAL hem SUBTOTAL varsa, farkı al
    if kdv_amount == 0.0 and total_amount > 0:
        sub_val = 0.0
        for p in [r"(?:SUBTOTAL|ARA\s*TOPLAM)[\s:]*[*]?\s*(\d+[.,]\d{2})",
                  r"(\d+[.,]\d{2})\s+(?:SUBTOTAL|ARA\s*TOPLAM)"]:
            m = re.search(p, ocr_text, re.IGNORECASE)
            if m:
                sub_val = float(m.group(1).replace(",", "."))
                break
        if sub_val > 0 and total_amount > sub_val:
            kdv_amount = round(total_amount - sub_val, 2)

    # Hâlâ KDV bulunamadıysa ve "TAX" veya "KDV" kelimesi metinde varsa,
    # TOTAL'dan küçük olan ve ürün fiyatlarından büyük olan tüm sayıları incele.
    # Genellikle TAX satırının etrafındaki (±1 satır) sayı KDV'dir.
    if kdv_amount == 0.0 and total_amount > 0:
        tax_keywords = ["TAX", "TAK", "KDV", "VAT"]
        for i, line in enumerate(lines):
            if any(kw in line.upper() for kw in tax_keywords):
                # Bu satır ve komşu satırlardaki sayıları tara
                search_range = lines[max(0, i-1):min(len(lines), i+2)]
                for nearby_line in search_range:
                    nearby_amounts = re.findall(r"(\d+[.,]\d{2})", nearby_line)
                    for amt_str in nearby_amounts:
                        amt = float(amt_str.replace(",", "."))
                        if 0 < amt < total_amount * 0.3:
                            kdv_amount = amt
                            break
                    if kdv_amount > 0:
                        break
                break

    result["kdv_tutari"] = kdv_amount

    # --- TOPLAM / KDV Çapraz Doğrulama ---
    # OCR'da '*' karakteri bazen '1' olarak okunur: "*195,58" → "1195,58"
    # KDV/TOPLAM oranı %30'u aşıyorsa TOPLAM muhtemelen yanlış okunmuş.
    if total_amount > 0 and kdv_amount > 0:
        ratio = kdv_amount / total_amount
        if ratio > 0.30:
            total_str = f"{total_amount:.2f}"
            if total_str.startswith("1") and len(total_str) > 5:
                try:
                    corrected = float(total_str[1:])
                    if corrected > 0 and kdv_amount / corrected <= 0.30:
                        logger.info(
                            "TOPLAM '*'→'1' OCR düzeltmesi: %.2f → %.2f", total_amount, corrected
                        )
                        result["toplam_tutar"] = corrected
                        total_amount = corrected
                except ValueError:
                    pass

    # --- Tarih ---
    # OCR hata düzeltmesi: sık karıştırılan karakterler rakama çevrilir
    # Örnek: "16/12/201)" → "16/12/2017" (parantez yedi olarak okunur)
    date_ocr = (
        ocr_text
        .replace(")", "7")   # ) → 7
        .replace("|", "1")   # | → 1
        .replace("O", "0")   # O → 0 (büyük O harfi sıfır olarak)
        .replace("l", "1")   # küçük L → 1 (sadece rakam bağlamında işe yarar)
    )

    date_patterns = [
        # DD/MM/YYYY veya MM/DD/YYYY (4 haneli yıl)
        r"(\d{2})[/.\-](\d{2})[/.\-](\d{4})",
        # DD/MM/YY veya MM/DD/YY (2 haneli yıl)
        r"(\d{2})[/.\-](\d{2})[/.\-](\d{2})\b",
    ]
    for pattern in date_patterns:
        match = re.search(pattern, date_ocr)
        if match:
            g1, g2, g3 = match.group(1), match.group(2), match.group(3)
            if len(g3) == 2:
                g3 = "20" + g3

            g1_int, g2_int = int(g1), int(g2)
            if g1_int > 12:
                day, month = g1, g2
            elif g2_int > 12:
                day, month = g2, g1
            else:
                # Belirsiz — / ile ayrılmışsa Amerikan (MM/DD), değilse Türk (DD.MM) formatı
                if "/" in match.group(0):
                    day, month = g2, g1
                else:
                    day, month = g1, g2

            result["tarih"] = f"{day}-{month}-{g3}"
            break

    # --- Kategori Tahmini ---
    text_lower = ocr_text.lower()
    category_keywords = {
        "Market & Gıda": [
            "market", "migros", "bim", "a101", "şok", "carrefour", "gıda",
            "süt", "ekmek", "walmart", "grocery", "food", "tesco", "lidl",
            "baby wipes", "pampers", "sock", "items sold",
        ],
        "Ulaşım": [
            "akaryakıt", "benzin", "shell", "opet", "bp", "petrol", "otopark",
            "gas station", "fuel",
        ],
        "Sağlık": [
            "eczane", "ilaç", "hastane", "pharmacy", "sağlık", "hospital",
        ],
        "Eğlence": [
            "sinema", "tiyatro", "cafe", "restoran", "restaurant", "kahve",
            "starbucks", "cinema",
        ],
        "Faturalar": [
            "elektrik", "doğalgaz", "su faturası", "internet", "telefon",
            "utility", "electric", "water bill",
        ],
        "Giyim": [
            "giyim", "moda", "zara", "h&m", "lcw", "defacto", "clothing",
        ],
        "Eğitim": [
            "kitap", "kırtasiye", "okul", "üniversite", "book", "school",
        ],
    }
    for cat, keywords in category_keywords.items():
        if any(kw in text_lower for kw in keywords):
            result["kategori"] = cat
            break

    return result


def _clean_merchant_name(name: str) -> str:
    """
    OCR'dan gelen kurum adını temizler.
    OCR logolar ve sembolleri yanlış okuyabilir:
      "Walmart >i<"  → "Walmart"
      "'MIGROS ®"    → "MIGROS"

    v2: Daha az agresif temizlik — tek harfli kelimeleri artık kaldırmıyor
    çünkü bazı kurum adlarında tek harfli kelimeler var (D&R, H&M, vb.)
    """
    # OCR gürültüsü: >, <, |, *, ®, ©, ™ gibi semboller
    cleaned = re.sub(r"[><|*®©™]+", " ", name)
    # Satır başı/sonu gereksiz semboller (tırnak, tire, yıldız vb.)
    cleaned = re.sub(r"^[^a-zA-Z0-9İÇÖÜŞĞıçöüşğ&]+", "", cleaned)
    cleaned = re.sub(r"[^a-zA-Z0-9İÇÖÜŞĞıçöüşğ&.]+$", "", cleaned)
    # Çoklu boşlukları teke indir
    cleaned = re.sub(r"\s+", " ", cleaned).strip()
    # Son kontrol: çok kısa ise orijinal adı döndür
    return cleaned if len(cleaned) >= 2 else name.strip()


def _validate_and_clean(data: dict) -> dict:
    """
    LLM çıktısını doğrular ve eksik alanları varsayılan değerlerle doldurur.
    LLM bazen beklenmedik alan adları veya formatlar kullanabilir.
    """
    defaults = {
        "kurum_adi": "Bilinmiyor",
        "tarih": datetime.now().strftime("%d-%m-%Y"),
        "toplam_tutar": 0.0,
        "kdv_tutari": 0.0,
        "kategori": "Diğer",
        "islem_tipi": "Gider",
    }

    result = {}
    for key, default_val in defaults.items():
        val = data.get(key, default_val)
        if val is None or val == "":
            val = default_val
        result[key] = val

    # Kurum adını temizle
    result["kurum_adi"] = _clean_merchant_name(str(result["kurum_adi"]))

    for num_field in ["toplam_tutar", "kdv_tutari"]:
        try:
            result[num_field] = float(str(result[num_field]).replace(",", "."))
        except (ValueError, TypeError):
            result[num_field] = 0.0

    return result
