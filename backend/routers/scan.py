"""
Fiş/Fatura Tarama Router'ı
============================
Fiş görüntüsünü alıp OCR + LLM pipeline'ından geçiren API endpoint'leri.

İki farklı endpoint sunulur:
1. POST /scan/upload  → Multipart/form-data (mobil kamera, dosya seçici)
2. POST /scan/base64  → JSON body ile base64 string (Flutter web)

Her iki endpoint de aynı pipeline'ı çağırır, sadece girdi formatı farklıdır.
Kullanıcı kimlik doğrulaması (JWT) zorunludur — sadece giriş yapmış
kullanıcılar fiş tarayabilir.

Güvenlik Notları:
- Dosya boyutu, TÜM içerik belleğe okunmadan ÖNCE sınırlanır (DoS koruması).
- Hata mesajlarında ham exception metni (str(e)) İSTEMCİYE döndürülmez —
  iç sistem detayları (dosya yolları, kütüphane sürümleri, olası API
  yanıtları) sızdırmamak için sadece sunucu loguna yazılır.
"""

import logging

from fastapi import APIRouter, Depends, UploadFile, File, HTTPException
from sqlalchemy.orm import Session

from database import get_db
from models import User
from schemas import ReceiptScanBase64Request, ReceiptScanResponse
from routers.auth import get_current_user
from services.receipt_pipeline import process_receipt_image, process_receipt_base64

logger = logging.getLogger("scan_router")

router = APIRouter(prefix="/scan", tags=["Fiş Tarama"])

# Maksimum dosya boyutu: 10 MB
MAX_FILE_SIZE = 10 * 1024 * 1024
# base64 kodlaması binary boyuttan ~%33 daha büyük olur; üst sınırı buna göre belirle
MAX_BASE64_LENGTH = int(MAX_FILE_SIZE * 4 / 3) + 1024


@router.post("/upload", response_model=ReceiptScanResponse)
async def scan_receipt_upload(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
):
    """
    Multipart/form-data ile fiş görüntüsü yükler ve analiz eder.

    Desteklenen formatlar: JPEG, PNG, WEBP
    Maksimum boyut: 10 MB

    Dönen JSON:
    {
        "kurum_adi": "Migros",
        "tarih": "18-03-2026",
        "toplam_tutar": 156.90,
        "kdv_tutari": 12.50,
        "kategori": "Market & Gıda",
        "islem_tipi": "Gider",
        "ocr_text": "... ham OCR metni ..."
    }
    """
    # Dosya tipi kontrolü — content_type boş gelirse uzantıdan belirle
    allowed_types = {"image/jpeg", "image/png", "image/webp"}
    ext_map = {".jpg": "image/jpeg", ".jpeg": "image/jpeg", ".png": "image/png", ".webp": "image/webp"}

    content_type = file.content_type
    if not content_type or content_type == "application/octet-stream":
        ext = "." + file.filename.rsplit(".", 1)[-1].lower() if file.filename and "." in file.filename else ""
        content_type = ext_map.get(ext)

    if content_type not in allowed_types:
        raise HTTPException(
            status_code=400,
            detail="Desteklenmeyen dosya formatı. JPEG, PNG veya WEBP yükleyin."
        )

    # Güvenlik: dosyayı MAX_FILE_SIZE+1 byte ile SINIRLI oku — Content-Length
    # header'ı yanlış/eksik olsa bile sunucunun belleği taşırılamaz (DoS koruması).
    contents = await file.read(MAX_FILE_SIZE + 1)
    if len(contents) > MAX_FILE_SIZE:
        raise HTTPException(
            status_code=400,
            detail="Dosya boyutu 10 MB'ı aşamaz."
        )

    try:
        result = await process_receipt_image(contents)
        return ReceiptScanResponse(**result)
    except ValueError:
        logger.warning("Geçersiz görüntü verisi yüklendi (user_id=%s).", current_user.id)
        raise HTTPException(
            status_code=400,
            detail="Görüntü işlenemedi. Lütfen geçerli bir fiş fotoğrafı yükleyin."
        )
    except Exception:
        # Ham exception metni istemciye DÖNDÜRÜLMEZ — iç detaylar (API URL'leri,
        # kütüphane hataları vb.) sızdırmamak için sadece sunucu logunda tutulur.
        logger.exception("Fiş işleme sırasında beklenmeyen hata (user_id=%s).", current_user.id)
        raise HTTPException(
            status_code=500,
            detail="Fiş işlenirken bir hata oluştu. Lütfen tekrar deneyin."
        )


@router.post("/base64", response_model=ReceiptScanResponse)
async def scan_receipt_base64(
    data: ReceiptScanBase64Request,
    current_user: User = Depends(get_current_user),
):
    """
    Base64 kodlanmış fiş görüntüsünü analiz eder.
    Flutter web veya JSON API istemcileri için uygundur.

    Request Body:
    { "image_base64": "data:image/jpeg;base64,/9j/4AAQ..." }
    veya
    { "image_base64": "/9j/4AAQ..." }
    """
    if not data.image_base64 or len(data.image_base64) < 100:
        raise HTTPException(
            status_code=400,
            detail="Geçersiz base64 verisi."
        )

    if len(data.image_base64) > MAX_BASE64_LENGTH:
        raise HTTPException(
            status_code=400,
            detail="Görüntü verisi 10 MB sınırını aşıyor."
        )

    try:
        result = await process_receipt_base64(data.image_base64)
        return ReceiptScanResponse(**result)
    except ValueError:
        logger.warning("Geçersiz base64 görüntü verisi (user_id=%s).", current_user.id)
        raise HTTPException(
            status_code=400,
            detail="Görüntü işlenemedi. Lütfen geçerli bir fiş fotoğrafı yükleyin."
        )
    except Exception:
        logger.exception("Fiş işleme sırasında beklenmeyen hata (user_id=%s).", current_user.id)
        raise HTTPException(
            status_code=500,
            detail="Fiş işlenirken bir hata oluştu. Lütfen tekrar deneyin."
        )
