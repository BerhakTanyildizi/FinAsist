"""
Görüntü Ön İşleme Servisi (Image Preprocessing Service)
=========================================================
Bu modül, fiş/fatura fotoğraflarını OCR'a hazırlamak için uygulanan
görüntü ön işleme boru hattını (pipeline) içerir.

Neden ön işleme gerekli?
- Telefon kameralarından alınan fotoğraflar genellikle gürültülü, eğik
  ve düşük kontrastlı olur. Bu durumda OCR motorları düşük doğrulukla çalışır.
- Gri tonlama → Gürültü azaltma → Adaptif eşikleme → Morfolojik temizlik
  zinciri, metin bölgelerini arka plandan net bir şekilde ayırır.

Mimari Tercih:
- Tek Sorumluluk İlkesi (SRP): Bu servis SADECE görüntü ön işlemeden sorumlu.
  OCR veya LLM entegrasyonu burada yapılmaz.
- Strateji Deseni: Farklı ön işleme stratejileri (fiş, fatura, dekont) için
  kolayca genişletilebilir.
"""

import cv2
import numpy as np
import base64
from io import BytesIO


def decode_image_from_bytes(image_bytes: bytes) -> np.ndarray:
    """
    Ham byte verisini OpenCV matrisine dönüştürür.
    Multipart/form-data ile gelen dosya içeriği doğrudan buraya verilir.
    """
    nparr = np.frombuffer(image_bytes, np.uint8)
    img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
    if img is None:
        raise ValueError("Geçersiz görüntü formatı. Desteklenen: JPEG, PNG, WEBP")
    return img


def decode_image_from_base64(base64_string: str) -> np.ndarray:
    """
    Base64 kodlanmış string'i OpenCV matrisine dönüştürür.
    Flutter tarafından base64 olarak gönderilen görüntüler için kullanılır.
    """
    # "data:image/jpeg;base64," gibi prefix varsa kaldır
    if "," in base64_string:
        base64_string = base64_string.split(",", 1)[1]

    image_bytes = base64.b64decode(base64_string)
    return decode_image_from_bytes(image_bytes)


def preprocess_for_ocr(img: np.ndarray) -> np.ndarray:
    """
    Fiş/fatura görüntüsüne OCR-optimized ön işleme pipeline'ı uygular.

    Pipeline Adımları:
    1. Gri Tonlama (Grayscale): Renk kanallarını tek kanala indirger.
       OCR motorları genellikle tek kanallı görüntülerde daha iyi çalışır.

    2. CLAHE (Contrast Limited Adaptive Histogram Equalization):
       Lokal kontrast iyileştirmesi. Standart histogram eşitleme yerine
       CLAHE kullanılır çünkü fiş kağıtlarında bölgesel parlaklık
       farklılıkları olur (katlanan kısımlar, gölgeler). CLAHE bunu
       küçük bölgelere (tile) bölerek her bölgeyi ayrı optimize eder.
       clipLimit=2.0 → aşırı kontrast artışını önler (gürültü amplifikasyonu).

    3. Gaussian Blur: Hafif bulanıklaştırma ile yüksek frekanslı gürültü
       (tuz-biber gürültüsü, kamera sensör gürültüsü) bastırılır.
       Kernel (3,3) küçük tutulur ki metin detayları korunsun.

    4. Adaptif Eşikleme (Adaptive Thresholding): Görüntüyü siyah-beyaz
       binary formata çevirir. Neden adaptif? Çünkü fişlerde ışık
       homojen dağılmaz — üst kısım aydınlık, alt kısım karanlık olabilir.
       Gaussian yöntemi komşu piksellerin ağırlıklı ortalamasını alır.
       blockSize=15 → 15x15 piksellik komşuluk penceresi.
       C=8 → eşik değerinden çıkarılan sabit (hassasiyet ayarı).

    5. Morfolojik Açma (Morphological Opening): Küçük gürültü noktalarını
       temizler. Erosion → Dilation sırası ile çok küçük beyaz noktalar
       (gürültü) önce aşındırılır, sonra metin kalınlığı geri kazanılır.
       2x2 kernel çok küçük tutulur ki harfler zarar görmesin.

    6. Ölçekleme (Upscaling): Çözünürlük düşükse 2x büyütme yapılır.
       Tesseract 300+ DPI görüntülerde optimal çalışır. Çoğu telefon
       kamerası yeterli çözünürlük sağlar ama crop edilmiş bölgeler
       düşük çözünürlüklü olabilir.
    """
    # 1. Gri tonlama
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

    # 2. CLAHE ile lokal kontrast iyileştirme
    clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
    enhanced = clahe.apply(gray)

    # 3. Hafif Gaussian bulanıklaştırma (gürültü azaltma)
    blurred = cv2.GaussianBlur(enhanced, (3, 3), 0)

    # 4. Adaptif eşikleme — arka plan ve metin ayrımı
    binary = cv2.adaptiveThreshold(
        blurred, 255,
        cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
        cv2.THRESH_BINARY,
        blockSize=15,
        C=8
    )

    # 5. Morfolojik açma — izole gürültü noktalarını temizle
    kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (2, 2))
    cleaned = cv2.morphologyEx(binary, cv2.MORPH_OPEN, kernel)

    # 6. Düşük çözünürlüklü görüntüleri ölçekle
    height, width = cleaned.shape[:2]
    if width < 1000:
        scale = 2.0
        cleaned = cv2.resize(
            cleaned, None,
            fx=scale, fy=scale,
            interpolation=cv2.INTER_CUBIC
        )

    return cleaned


def crop_header_region(img: np.ndarray, ratio: float = 0.25) -> np.ndarray:
    """
    Fişin üst bölgesini (başlık) kırpar.

    Kurum adları her zaman fişin en üstünde yer alır — genellikle
    ilk %20-25'lik alan. Bu bölgeyi ayrı çıkarıp farklı OCR
    konfigürasyonlarıyla taramak, kurum adı doğruluğunu artırır.

    ratio: Üstten kesilecek oran (0.25 = %25)
    """
    height = img.shape[0]
    cut = int(height * ratio)
    return img[:cut, :]


def preprocess_header_for_ocr(img: np.ndarray) -> list[np.ndarray]:
    """
    Fiş başlık bölgesi için çoklu ön işleme stratejileri üretir.

    Kurum adları genellikle büyük, kalın veya stilize fontlarla yazılır.
    Standart adaptif eşikleme bu tür metinleri bozabilir. Bu yüzden
    birden fazla ön işleme stratejisi denenir ve her biri OCR'a verilir.

    Stratejiler:
    1. Hafif CLAHE + Otsu eşikleme (logo ve büyük yazılar için optimal)
    2. Sadece gri tonlama + kontrast artırma (en minimal müdahale)
    3. Negatif görüntü (koyu arka plan, açık yazı — bazı fişlerde kullanılır)
    4. Güçlü CLAHE + büyük blok adaptif eşikleme (düşük kontrast fişler)
    """
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY) if len(img.shape) == 3 else img.copy()
    results = []

    # ─── Strateji 1: CLAHE + Otsu (en iyi genel strateji) ───
    clahe = cv2.createCLAHE(clipLimit=3.0, tileGridSize=(4, 4))
    enhanced = clahe.apply(gray)
    blurred = cv2.GaussianBlur(enhanced, (3, 3), 0)
    _, otsu = cv2.threshold(blurred, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
    results.append(_upscale_if_small(otsu))

    # ─── Strateji 2: Sadece gri + kontrast germe (minimal müdahale) ───
    # Bazı fişlerde ön işleme fazla agresif olup harfleri bozar.
    # Bu strateji ham görüntüyü neredeyse olduğu gibi verir.
    stretched = cv2.normalize(gray, None, 0, 255, cv2.NORM_MINMAX)
    results.append(_upscale_if_small(stretched))

    # ─── Strateji 3: Negatif (ters çevrilmiş) ───
    # Bazı fişlerde logo alanı koyu arka plan + açık yazı şeklindedir.
    inverted = cv2.bitwise_not(gray)
    clahe_inv = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(4, 4))
    inv_enhanced = clahe_inv.apply(inverted)
    _, inv_otsu = cv2.threshold(inv_enhanced, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
    results.append(_upscale_if_small(inv_otsu))

    # ─── Strateji 4: Güçlü CLAHE + büyük blok adaptif eşikleme ───
    clahe_strong = cv2.createCLAHE(clipLimit=4.0, tileGridSize=(4, 4))
    strong_enhanced = clahe_strong.apply(gray)
    adaptive = cv2.adaptiveThreshold(
        strong_enhanced, 255,
        cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
        cv2.THRESH_BINARY,
        blockSize=31,  # Büyük blok — logo fontları için daha iyi
        C=10
    )
    results.append(_upscale_if_small(adaptive))

    # ─── Strateji 5: Bilaterel filtre + Otsu (kenarları korur) ───
    bilateral = cv2.bilateralFilter(gray, 9, 75, 75)
    clahe_bil = cv2.createCLAHE(clipLimit=2.5, tileGridSize=(8, 8))
    bil_enhanced = clahe_bil.apply(bilateral)
    _, bil_otsu = cv2.threshold(bil_enhanced, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
    results.append(_upscale_if_small(bil_otsu))

    return results


def preprocess_gentle_for_ocr(img: np.ndarray) -> np.ndarray:
    """
    Tüm fiş için daha hafif bir ön işleme pipeline'ı.

    Standart pipeline (preprocess_for_ocr) agresif adaptif eşikleme
    kullanır ve bu bazen başlık bölgesindeki büyük fontları bozar.
    Bu fonksiyon Otsu eşikleme kullanarak daha genel bir yaklaşım sağlar.
    """
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY) if len(img.shape) == 3 else img.copy()

    # Bilaterel filtre — kenarları koruyarak gürültü azaltır
    denoised = cv2.bilateralFilter(gray, 9, 75, 75)

    # CLAHE
    clahe = cv2.createCLAHE(clipLimit=2.5, tileGridSize=(8, 8))
    enhanced = clahe.apply(denoised)

    # Otsu — global eşik, büyük fontlar için daha uygun
    _, binary = cv2.threshold(enhanced, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)

    return _upscale_if_small(binary)


def _upscale_if_small(img: np.ndarray, min_width: int = 1000) -> np.ndarray:
    """Düşük çözünürlüklü görüntüleri 2x büyütür."""
    height, width = img.shape[:2]
    if width < min_width:
        img = cv2.resize(img, None, fx=2.0, fy=2.0, interpolation=cv2.INTER_CUBIC)
    return img
