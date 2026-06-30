# Finasist - Yapay Zeka Destekli Finansal Danışman

**TÜBİTAK 2209-A Üniversite Öğrencileri Araştırma Projeleri Destekleme Programı**

Finasist; gelir/gider takibi, fiş/fatura tarama (OCR + LLM), yapay zeka destekli finansal danışmanlık ve PDF raporlama sunan, Flutter (mobil/web/masaüstü) + FastAPI tabanlı bir kişisel finans uygulamasıdır.

---

## Özellikler

- **Gelir/Gider Takibi** — kategori bazlı işlem kaydı, düzenli (tekrarlayan) işlemler, taksitler
- **Fiş Tarama** — Görseli doğrudan bir görsel-dil modeline (Groq Vision) göndererek OCR'sız, yüksek doğrulukta kurum adı/tarih/tutar/KDV/kategori çıkarımı; model erişilemezse EasyOCR + LLM metin ayrıştırma + regex tabanlı yedek katmanlara otomatik düşer
- **AI Finansal Danışman** — kullanıcının son 30 günlük gerçek gelir/gider verilerine dayanan, Groq (Llama 3.3 70B) destekli sohbet; kategori bazlı tasarruf önerileri, aksiyon planları
- **PDF Rapor** — gelir/gider özeti, kategori dağılım grafiği ve işlem geçmişini PDF olarak indirme (dönemsel veya tüm zamanlar)
- **Finansal Raporlar** — günlük/haftalık/aylık trend grafikleri, dönemsel karşılaştırma
- **Uygulama Kilidi** — 4 haneli PIN ile yerel uygulama kilidi
- **Açık/Koyu Tema** — tüm ekranlarda tema-duyarlı renk şeması
- **Veri Dışa Aktarma** — tüm işlem geçmişini PDF olarak dışa aktarma

---

## Proje Yapısı

```
Tubitak 2209-A/
├── backend/                    # FastAPI REST API
│   ├── main.py                 # Uygulama girişi, CORS, istek boyutu sınırı
│   ├── database.py             # PostgreSQL bağlantısı
│   ├── models.py                # SQLAlchemy ORM modelleri
│   ├── schemas.py               # Pydantic doğrulama şemaları
│   ├── seed.py / seed_data.py   # Test kullanıcısı / varsayılan kategoriler
│   ├── requirements.txt
│   ├── .env.example             # Ortam değişkeni şablonu (gerçek .env git'e eklenmez)
│   ├── routers/
│   │   ├── auth.py              # Kayıt, giriş, JWT (rate limit korumalı)
│   │   ├── transactions.py      # Gelir/gider CRUD
│   │   ├── categories.py        # Kategori yönetimi
│   │   ├── recurring.py         # Tekrarlayan işlemler
│   │   ├── scan.py              # Fiş tarama
│   │   └── advisor.py           # AI finansal danışman sohbeti
│   └── services/
│       ├── receipt_pipeline.py  # Fiş tarama orkestratörü (Facade)
│       ├── llm_parser.py        # Groq/Gemini Vision + metin ayrıştırma
│       ├── ocr_service.py       # EasyOCR yedek katmanı
│       ├── image_processing.py  # Görüntü ön işleme
│       ├── advisor_service.py   # Finansal özet + AI sohbet
│       └── rate_limiter.py      # Bellek-içi istek sınırlama
│
└── finasist/                    # Flutter uygulaması (mobil/web/masaüstü)
    └── lib/
        ├── main.dart             # Giriş noktası, tema, kilit ekranı yönlendirmesi
        ├── models/                # User, Category, Transaction
        ├── providers/             # Auth, Transaction, Settings state
        ├── services/              # api_service.dart, pdf_report_service.dart
        ├── theme/                 # AppTheme (açık/koyu, context-duyarlı)
        ├── screens/               # auth, home, scan, ai_advisor, reports, settings, ...
        └── utils/
```

---

## Kullanılan Teknolojiler

### Backend
| Teknoloji | Açıklama |
|-----------|----------|
| FastAPI | REST API framework |
| PostgreSQL + SQLAlchemy 2.x | Veritabanı / ORM |
| Pydantic v2 | Veri doğrulama (uzunluk/aralık kısıtları dahil) |
| python-jose + bcrypt | JWT kimlik doğrulama, parola hashleme |
| EasyOCR + OpenCV | Yedek OCR pipeline'ı |
| Groq API (Llama 3.3 70B / Llama 4 Scout Vision) | Fiş ayrıştırma + AI danışman |
| httpx | Asenkron HTTP istemcisi |

### Frontend
| Teknoloji | Açıklama |
|-----------|----------|
| Flutter / Dart | Cross-platform UI |
| Provider | State management |
| http | API iletişimi |
| fl_chart | Grafikler |
| pdf + printing | PDF rapor oluşturma/indirme |
| file_picker | Fiş görseli seçimi |
| Google Fonts (Inter) | Tipografi |

---

## Kurulum

### Gereksinimler
- **Python 3.10+**
- **PostgreSQL 16**
- **Flutter SDK 3.x**

### 1. Projeyi Klonlayın

```bash
git clone https://github.com/BerhakTanyildizi/FinAsist.git
cd FinAsist
```

### 2. Backend Kurulumu

```bash
cd backend
python -m venv venv

# Windows:
.\venv\Scripts\activate
# macOS/Linux:
source venv/bin/activate

pip install -r requirements.txt
```

### 3. PostgreSQL Veritabanı

```sql
CREATE DATABASE finasist_db;
```

### 4. Ortam Değişkenleri

`backend/.env.example` dosyasını `backend/.env` olarak kopyalayın ve gerçek değerlerle doldurun:

```bash
cp .env.example .env   # Windows: copy .env.example .env
```

```env
DATABASE_URL=postgresql://<kullanici>:<sifre>@localhost:5432/finasist_db
SECRET_KEY=               # python -c "import secrets; print(secrets.token_hex(32))"
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=60
GEMINI_API_KEY=           # aistudio.google.com (opsiyonel)
GEMINI_MODEL=gemini-2.0-flash-lite
GROQ_API_KEY=              # console.groq.com (fiş tarama + AI danışman için gerekli)
ALLOWED_ORIGIN_REGEX=      # opsiyonel; boşsa sadece localhost/127.0.0.1 kabul edilir
```

> **Güvenlik:** `SECRET_KEY` tanımlı değilse uygulama başlamayı reddeder (fail-fast). `.env` dosyasını ASLA commit etmeyin veya başka dökümantasyon dosyalarına (README, CLAUDE.md vb.) yapıştırmayın — sadece placeholder kullanın.

### 5. Veritabanı Tabloları ve Varsayılan Veriler

```bash
python seed_data.py   # Global kategoriler
python seed.py        # (opsiyonel) Test kullanıcısı
```

### 6. Backend'i Başlat

```bash
uvicorn main:app --reload
```

API dokümantasyonu: [http://127.0.0.1:8000/docs](http://127.0.0.1:8000/docs)

### 7. Flutter Kurulumu

```bash
cd finasist
flutter pub get
flutter run -d chrome   # veya: flutter run (masaüstü/mobil)
```

API adresi `lib/services/api_service.dart` içinde `baseUrl` sabitiyle tanımlıdır (varsayılan: `http://127.0.0.1:8000`).

---

## API Endpoint'leri

| Grup | Endpoint | Açıklama |
|------|----------|----------|
| Auth | `POST /auth/register` | Kayıt (rate limit: 5/dk) — parola min. 8 karakter |
| Auth | `POST /auth/login` | Giriş, JWT token (rate limit: 10/dk) |
| Auth | `GET /auth/me` | Giriş yapan kullanıcı bilgisi |
| İşlemler | `GET\|POST /transactions/`, `GET\|PUT\|DELETE /transactions/{id}` | Gelir/gider CRUD |
| Kategoriler | `GET\|POST /categories/`, `DELETE /categories/{id}` | Kategori yönetimi |
| Düzenli İşlemler | `GET\|POST /recurring/`, `DELETE /recurring/{id}` | Tekrarlayan işlemler |
| Fiş Tarama | `POST /scan/upload`, `POST /scan/base64` | Görsel → yapılandırılmış veri (max 10MB) |
| AI Danışman | `POST /advisor/chat` | Finansal veriye dayalı sohbet |

Tüm endpoint'ler (auth hariç) `Authorization: Bearer <token>` ister.

---

## Güvenlik

- JWT (HS256), bcrypt parola hash'leme, kullanıcı bazlı veri izolasyonu (her sorgu `user_id` filtreli)
- Parola politikası: minimum 8 karakter (backend + frontend doğrulaması eşleşir)
- `/auth/login` ve `/auth/register` için IP başına istek sınırlama (rate limiting)
- CORS varsayılan olarak `localhost`/`127.0.0.1` ile sınırlı; üretimde `ALLOWED_ORIGIN_REGEX` ile yapılandırılır
- İstek/dosya boyutu sınırları (global 15MB, fiş yükleme 10MB) — DoS koruması
- Hata yanıtlarında iç sistem detayları (stack trace, API URL'leri) istemciye sızdırılmaz, sadece sunucu logunda tutulur
- Dış servis API anahtarları (Gemini/Groq) yalnızca HTTP header üzerinden gönderilir, URL/log'a yazılmaz

---

## Lisans

Bu proje TÜBİTAK 2209-A programı kapsamında geliştirilmiştir.
