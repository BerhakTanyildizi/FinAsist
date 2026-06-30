# Finasist — Proje Dokümantasyonu (CLAUDE.md)

> Tubitak 2209-A Üniversite Öğrencileri Araştırma Projeleri Destek Programı kapsamında geliştirilen yapay zeka destekli kişisel finans yönetimi uygulaması.

---

## 1. Proje Kimliği

- **Ad:** Finasist
- **Amaç:** Türk kullanıcılar (özellikle üniversite öğrencileri) için gelir/gider takibi, fiş tarama ve yapay zeka destekli finansal danışmanlık
- **Program:** TÜBİTAK 2209-A
- **Git Kullanıcısı:** Berhak
- **Ana Branch:** `main`

---

## 2. Teknoloji Yığını

### Backend
| Katman | Teknoloji |
|---|---|
| Framework | FastAPI 0.115.0 |
| Veritabanı | PostgreSQL 16 |
| ORM | SQLAlchemy 2.0.36+ |
| Validasyon | Pydantic 2.7.0 |
| Auth | JWT (python-jose 3.3.0, HS256) |
| Şifreleme | bcrypt (passlib 1.7.4) |
| ASGI Sunucu | Uvicorn 0.30.0 |
| OCR | Tesseract (pytesseract 0.3.13) |
| Görüntü İşleme | OpenCV (opencv-python-headless 4.10.0.84) |
| LLM | Google Gemini 2.0 Flash (httpx 0.28.1) |
| Ortam | python-dotenv 1.0.1 |
| Çok Parçalı Form | python-multipart 0.0.9 |
| Tarih | python-dateutil 2.9.0 |

### Flutter Frontend
| Katman | Teknoloji |
|---|---|
| Framework | Flutter 3.x / Dart 3.9.2+ |
| State Management | Provider 6.1.5+ |
| HTTP İstemci | http 1.6.0 |
| Yerel Depolama | SharedPreferences 2.5.4 |
| Grafikler | fl_chart 1.1.1 |
| Tipografi | Google Fonts 8.0.2 (Inter) |
| Dosya Seçici | file_picker 9.2.1 |
| İkonlar | cupertino_icons 1.0.8 |

---

## 3. Proje Klasör Yapısı

```
Tubitak 2209-A/
├── CLAUDE.md                          ← Bu dosya
├── backend/
│   ├── main.py                        ← FastAPI uygulama girişi, router'lar, CORS
│   ├── database.py                    ← PostgreSQL bağlantı + get_db() bağımlılığı
│   ├── models.py                      ← SQLAlchemy ORM modelleri
│   ├── schemas.py                     ← Pydantic request/response şemaları
│   ├── requirements.txt               ← Python bağımlılıkları
│   ├── .env                           ← Gizli yapılandırma (git-ignore)
│   ├── seed.py                        ← Test verisi (test kullanıcı + kategoriler)
│   ├── seed_data.py                   ← Varsayılan global kategoriler
│   ├── routers/
│   │   ├── auth.py                    ← Kayıt, giriş, JWT
│   │   ├── transactions.py            ← İşlem CRUD
│   │   ├── categories.py             ← Kategori yönetimi
│   │   ├── recurring.py              ← Tekrarlayan işlemler + sync
│   │   └── scan.py                   ← Fiş tarama endpoint'leri [YENİ]
│   └── services/
│       ├── image_processing.py       ← OpenCV ön işleme pipeline'ı [YENİ]
│       ├── ocr_service.py            ← Tesseract OCR wrapper [YENİ]
│       ├── llm_parser.py             ← Gemini API + regex fallback [YENİ]
│       └── receipt_pipeline.py       ← Orchestrator / Facade [YENİ]
│
└── finasist/
    ├── pubspec.yaml                   ← Flutter bağımlılıkları
    ├── lib/
    │   ├── main.dart                  ← Giriş noktası, MultiProvider, routing
    │   ├── providers/
    │   │   ├── auth_provider.dart     ← Kimlik doğrulama state
    │   │   ├── transaction_provider.dart ← İşlem/kategori state + bakiye
    │   │   └── settings_provider.dart ← Tema, döviz, tercihler
    │   ├── models/
    │   │   ├── user.dart
    │   │   ├── transaction.dart
    │   │   └── category.dart
    │   ├── services/
    │   │   └── api_service.dart       ← Tüm HTTP istekleri, token yönetimi
    │   ├── theme/
    │   │   └── app_theme.dart         ← Light/Dark tema tanımları
    │   ├── screens/
    │   │   ├── main_layout.dart       ← 5 sekmeli alt navigasyon
    │   │   ├── auth/
    │   │   │   ├── login_screen.dart
    │   │   │   └── register_screen.dart
    │   │   ├── home/
    │   │   │   └── home_screen.dart
    │   │   ├── add_transaction/
    │   │   │   └── add_transaction_screen.dart
    │   │   ├── transactions/
    │   │   │   └── transactions_screen.dart
    │   │   ├── reports/
    │   │   │   └── reports_screen.dart
    │   │   ├── ai_advisor/
    │   │   │   └── ai_advisor_screen.dart
    │   │   ├── scan/
    │   │   │   └── scan_receipt_screen.dart  ← [YENİ]
    │   │   └── settings/
    │   │       ├── settings_screen.dart
    │   │       └── manage_categories_screen.dart
    │   └── utils/
    │       ├── category_icons.dart            ← 40+ ikon eşlemesi [YENİ]
    │       └── thousand_separator_formatter.dart
    └── test/
```

---

## 4. Ortam Değişkenleri (`backend/.env`)

```env
DATABASE_URL=postgresql://<kullanici>:<sifre>@localhost:5432/finasist_db
SECRET_KEY=<güçlü-rastgele-secret>
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=60
GEMINI_API_KEY=<gemini-api-key>
GEMINI_MODEL=gemini-2.0-flash-lite
GROQ_API_KEY=<groq-api-key>
```

**Önemli:**
- `.env` dosyası `.gitignore`'dadır, commit'lenmez.
- **CLAUDE.md, README veya başka herhangi bir dökümantasyon/commit edilen dosyaya GERÇEK secret
  değerleri (API key, DB şifresi, JWT secret) ASLA yazılmaz** — sadece placeholder/örnek değer
  kullanılır. Gerçek değerler yalnızca `.env` içinde kalır.
- Gerçek değerler için bkz. `backend/.env` (yerel, git dışı).

---

## 5. Backend Mimarisi

### 5.1 FastAPI Uygulama Yapısı (`backend/main.py`)

```
FastAPI(title="Finasist API", version="1.0.0")
├── CORS: allow_origins=["*"], allow_credentials=True
├── /auth      → routers/auth.py
├── /transactions → routers/transactions.py
├── /categories → routers/categories.py
├── /recurring  → routers/recurring.py
└── /scan       → routers/scan.py
```

### 5.2 Veritabanı Modelleri (`backend/models.py`)

#### `users` tablosu
| Sütun | Tip | Açıklama |
|---|---|---|
| id | PK Integer | Otomatik artan |
| full_name | String(100) | Ad soyad |
| email | String(100) UNIQUE | Kullanıcı adı |
| hashed_password | String(255) | bcrypt hash |
| created_at | DateTime | Kayıt tarihi |

#### `categories` tablosu
| Sütun | Tip | Açıklama |
|---|---|---|
| id | PK Integer | |
| user_id | FK → users (nullable) | NULL = global kategori |
| name | String(50) | Kategori adı |
| icon_name | String(50) | İkon adı |
| type | String | 'income' veya 'expense' |

#### `transactions` tablosu
| Sütun | Tip | Açıklama |
|---|---|---|
| id | PK Integer | |
| user_id | FK → users | |
| category_id | FK → categories | |
| amount | Numeric(12,2) | |
| type | String | 'income' veya 'expense' |
| merchant | String(100) | İsteğe bağlı |
| description | Text | İsteğe bağlı |
| transaction_date | Date | |
| created_at | DateTime | |

#### `recurring_transactions` tablosu
| Sütun | Tip | Açıklama |
|---|---|---|
| id | PK Integer | |
| user_id | FK → users | |
| category_id | FK → categories | |
| amount | Numeric(12,2) | |
| type | String | 'income' veya 'expense' |
| frequency | String | 'Aylık', 'Haftalık', 'Yıllık' |
| start_date | Date | Başlangıç |
| end_date | Date nullable | Bitiş (yoksa süresiz) |
| next_date | Date | Sonraki işlem tarihi |
| description | Text | İsteğe bağlı |
| created_at | DateTime | |

### 5.3 Tüm API Endpoint'ler

#### Auth (`/auth`)
| Method | Yol | Auth | Açıklama |
|---|---|---|---|
| POST | `/auth/register` | Yok | Yeni kullanıcı kaydı |
| POST | `/auth/login` | Yok | Giriş → JWT token |
| GET | `/auth/me` | JWT | Mevcut kullanıcı bilgisi |

**JWT Formatı:** `Authorization: Bearer <token>`  
**Token payload:** `{sub: user_id, exp: şu_an + 60dk}`

#### İşlemler (`/transactions`)
| Method | Yol | Açıklama |
|---|---|---|
| POST | `/transactions/` | Yeni işlem oluştur |
| GET | `/transactions/` | Kullanıcının tüm işlemleri (son → eski) + tekrarlayan sync |
| GET | `/transactions/{id}` | Tek işlem detayı |
| PUT | `/transactions/{id}` | İşlem güncelle (PATCH semantiği) |
| DELETE | `/transactions/{id}` | İşlem sil |

#### Kategoriler (`/categories`)
| Method | Yol | Açıklama |
|---|---|---|
| GET | `/categories/` | Global + kullanıcı kategorileri |
| POST | `/categories/` | Yeni özel kategori oluştur |
| DELETE | `/categories/{id}` | Özel kategori sil |

#### Tekrarlayan İşlemler (`/recurring`)
| Method | Yol | Açıklama |
|---|---|---|
| POST | `/recurring/` | Tekrarlayan işlem oluştur |
| GET | `/recurring/` | Listele |
| DELETE | `/recurring/{id}` | İptal et |

#### Fiş Tarama (`/scan`) — YENİ
| Method | Yol | Açıklama |
|---|---|---|
| POST | `/scan/upload` | Multipart dosya yükleme (max 10MB, JPEG/PNG/WEBP) |
| POST | `/scan/base64` | JSON body ile base64 görsel |

**Yanıt Şeması (`ReceiptScanResponse`):**
```json
{
  "kurum_adi": "BİM Market",
  "tarih": "25-06-2026",
  "toplam_tutar": 156.90,
  "kdv_tutari": 12.50,
  "kategori": "Market & Gıda",
  "islem_tipi": "Gider",
  "ocr_text": "Ham OCR metni..."
}
```

### 5.4 Pydantic Şemaları (`backend/schemas.py`)

```python
# Auth
UserCreate(email, full_name, password)
UserResponse(id, full_name, email, created_at)
LoginRequest(email, password)
Token(access_token, token_type)

# Kategori
CategoryCreate(name, icon_name?, type)
CategoryResponse(id, user_id?, name, icon_name?, type)

# İşlem
TransactionCreate(category_id, amount, type, merchant?, description?, transaction_date)
TransactionUpdate(category_id?, amount?, type?, merchant?, description?, transaction_date?)
TransactionResponse(id, user_id, category_id, amount, type, merchant?, description?, transaction_date, created_at, category)

# Tekrarlayan
RecurringTransactionCreate(category_id, amount, type, frequency, start_date, end_date?, description?)
RecurringTransactionResponse(id, user_id, category_id, amount, type, frequency, start_date, end_date?, next_date, description?, created_at, category)

# Fiş Tarama
ReceiptScanBase64Request(image_base64)
ReceiptScanResponse(kurum_adi?, tarih?, toplam_tutar?, kdv_tutari?, kategori?, islem_tipi?, ocr_text?)
```

### 5.5 Fiş Tarama Pipeline'ı (YENİ)

**Mimari Desen:** Facade (receipt_pipeline.py tüm servisleri orkestre eder)

```
POST /scan/upload veya /scan/base64
       │
       ▼
receipt_pipeline.py
  ├── 1. Görsel Çözümleme
  │     ├── decode_image_from_bytes()   ← multipart yükleme
  │     └── decode_image_from_base64()  ← base64 JSON
  │
  ├── 2. Görüntü Ön İşleme (image_processing.py)
  │     ├── Standart Pipeline:
  │     │   Gri → CLAHE (clip=2.0, 8x8) → Gaussian Blur (3,3)
  │     │   → Adaptif Threshold (blok=15, C=8)
  │     │   → Morfolojik Açma (2,2) → 2x Ölçekleme (<1000px ise)
  │     ├── Nazik Pipeline (gentle):
  │     │   İki taraflı filtre + CLAHE + Otsu
  │     └── Başlık Pipeline (5 strateji × 3 kırpma oranı):
  │         %15, %25, %35 üstten kırp → 5 farklı ön işleme
  │
  ├── 3. OCR (ocr_service.py — Tesseract)
  │     ├── Tam fiş: PSM 6, 4, 3 dene → en uzun sonucu al
  │     ├── Türkçe + İngilizce (tur+eng)
  │     ├── Hem işlenmiş hem orijinal görseli dene
  │     └── Başlık OCR: PSM 6, 7, 13, 4, 3 × 5 strateji
  │
  └── 4. LLM Ayrıştırma (llm_parser.py)
        ├── Gemini 2.0 Flash API (birincil)
        │   ├── JSON yanıt modu zorunlu
        │   └── Yeniden deneme: max 4, üstel geri çekilme (2^n sn)
        └── Regex Fallback (Gemini yoksa)
            ├── 200+ Türkçe mağaza adı sözlüğü (bulanık eşleme)
            ├── TOPLAM/TUTAR/TOTAL regex kalıpları
            ├── KDV/TAX kalıpları
            ├── Çoklu tarih formatı (MM/DD/YYYY, DD.MM.YYYY)
            └── 50+ anahtar kelime ile kategori tespiti
```

**Tesseract Yolu (Windows):** `C:\Program Files\Tesseract-OCR\tesseract.exe`

**Desteklenen Kategoriler (LLM çıktısı):**
- Market & Gıda
- Faturalar & Ödemeler
- Ulaşım
- Eğlence & Restoran
- Sağlık & Eczane
- Giyim & Aksesuar
- Elektronik & Teknoloji
- Diğer Giderler

### 5.6 Tekrarlayan İşlem Senkronizasyonu

`sync_recurring_transactions(db, user_id)` — `GET /transactions/` çağrıldığında otomatik çalışır:
1. `next_date <= bugün` olan tüm tekrarlayan işlemleri bul
2. `end_date` geçmişse atla
3. Otomatik `Transaction` kaydı oluştur (merchant="Sistem", description="[Oto-Kayıt]")
4. `next_date` güncelle: Aylık → +1 ay, Haftalık → +7 gün, Yıllık → +1 yıl (dateutil.relativedelta)

### 5.7 Varsayılan Global Kategoriler (`seed_data.py`)

**Gider:**
- Market & Gıda (shopping_cart)
- Faturalar (receipt_long)
- Ulaşım (directions_car)
- Eğlence (movie)
- Sağlık (local_hospital)
- Eğitim (school)
- Giyim (checkroom)
- Diğer (more_horiz)

**Gelir:**
- Maaş (account_balance)
- Freelance (laptop)
- Yatırım (trending_up)
- Hediye (card_giftcard)
- Diğer (more_horiz)

---

## 6. Flutter Frontend Mimarisi

### 6.1 Giriş Noktası (`lib/main.dart`)

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(AuthProvider)
    ChangeNotifierProvider(TransactionProvider)
    ChangeNotifierProvider(SettingsProvider)
  ]
)
→ FinasistApp (tema + Google Inter font)
  → AuthWrapper (tryAutoLogin() → LoginScreen veya MainLayoutScreen)
```

### 6.2 State Management — Provider'lar

#### `AuthProvider`
- **State:** `_user (User?)`, `_isLoading`, `_error`
- **Metotlar:**
  - `tryAutoLogin()` — SharedPreferences'tan token oku, `/auth/me` çağır
  - `login(email, password)` — Giriş, token kaydet
  - `register(fullName, email, password)` — Kayıt + otomatik giriş
  - `logout()` — Token ve kullanıcı temizle
- **Getter'lar:** `user`, `isLoading`, `isLoggedIn`, `error`

#### `TransactionProvider`
- **State:** `_transactions[]`, `_categories[]`, `_totalBalance`, `_isLoading`
- **Metotlar:**
  - `loadData()` — İşlemler + kategorileri yükle, bakiye hesapla
  - `addTransaction(...)` — Tek işlem ekle → yeniden yükle
  - `addRecurringTransaction(...)` — Tekrarlayan/taksit
  - `updateTransaction(id, data)` — Güncelle
  - `deleteTransaction(id)` — Optimistik silme (hata olursa geri yükle)
  - `createCategory(...)` / `deleteCategory(id)`
  - `_calculateTotalBalance()` — Gelir - gider (yerel hesaplama)
- **Getter'lar:** `transactions`, `categories`, `totalBalance`, `isLoading`

#### `SettingsProvider`
- **State:** `_isAppLocked`, `_useTraditionalCalendar`, `_currency`, `_themeMode`
- **Metotlar:** `toggleAppLock`, `setTraditionalCalendar`, `setCurrency`, `setThemeMode`
- **Desteklenen Dövizler:** TRY (₺), USD ($), EUR (€)
- **Kalıcılık:** Tüm ayarlar SharedPreferences'e kaydedilir

### 6.3 API Service (`lib/services/api_service.dart`)

**Base URL:** `http://127.0.0.1:8000` (geliştirme — localhost)

**Token Yönetimi:**
- SharedPreferences key: `auth_token`
- Her istek: `Authorization: Bearer <token>` başlığı
- `hasToken()` / `clearToken()` yardımcı metotları

**Önemli Detaylar:**
- Yanıtlar `utf8.decode(response.bodyBytes)` ile decode edilir (Türkçe karakter desteği)
- 204 ve 200 HTTP kodları için DELETE başarı sayılır
- Hata durumunda özel `ApiException` fırlatılır
- Tarih formatı: ISO 8601 (`YYYY-MM-DDTHH:mm:ss`), 'T' karakterinden bölünür

### 6.4 Tema (`lib/theme/app_theme.dart`)

**Renk Paleti:**
| Amaç | Renk | Hex |
|---|---|---|
| Ana renk | Mor | `#8B5CF6` |
| Gelir | Yeşil | `#34D399` |
| Gider | Kırmızı | `#FF4D4D` |
| Vurgu | Altın sarısı | `#FBBF24` |
| Koyu arkaplan | | `#14141E` |
| Koyu kart | | `#1B1E2B` |
| Açık arkaplan | | `#F2F4FA` |
| Açık kart | | `#FFFFFF` |

**Tasarım Dili:** Koyu tema öncelikli, glassmorphism kartlar, 16-20px köşe yuvarlama, Google Inter yazı tipi

### 6.5 Navigasyon (`lib/screens/main_layout.dart`)

5 sekmeli alt navigasyon (BottomNavigationBar):
| İndeks | Ekran | İkon |
|---|---|---|
| 0 | Home | home |
| 1 | AI Advisor | psychology/stars |
| 2 | Add Transaction | add (FAB, orta konumlu) |
| 3 | Reports | bar_chart |
| 4 | Settings | settings |

**Tab değiştirme:** `MainLayoutScreen.changeTab(context, index)`

### 6.6 Ekranlar (Detay)

#### `home_screen.dart`
- Toplam bakiye kartı (büyük, renkli)
- Hızlı işlemler (son 5 işlem)
- Trend analizi (fl_chart çizgi grafik)
- RefreshIndicator (aşağı çekerek yenile)

#### `add_transaction_screen.dart`
- 4 işlem tipi: Gider / Gelir / Alacak / Borç
- Tutar girişi (nokta ile binlik ayraç)
- Kategori seçici (türe göre filtreli)
- Tarih/saat seçici
- İsteğe bağlı not
- Tekrarlayan toggle → Aylık/Haftalık/Yıllık + bitiş tarihi

#### `transactions_screen.dart`
- Tüm işlemler listesi (en yeni üstte)
- Türe göre filtre (Tümü / Gelir / Gider)
- Uzun basmak → düzenleme modalı
- Silme butonu

#### `reports_screen.dart`
- Günlük/Haftalık çubuk grafik (fl_chart BarChart)
- Ay karşılaştırması (yüzdelik değişim)
- Gelir vs. gider görselleştirmesi

#### `ai_advisor_screen.dart`
- Sohbet arayüzü
- Anahtar kelime eşleme tabanlı yanıtlar (simüle)
- Hesap istatistiklerini gösterir (toplam gelir/gider/bakiye)
- Hızlı soru çipleri

#### `scan_receipt_screen.dart` — YENİ
- file_picker ile dosya seçimi (JPG/PNG/WEBP)
- Dosya önizleme + yükleme durumu
- Backend'den gelen ayrıştırılmış veriyi düzenlenebilir alanlarda göster:
  - Kurum adı, tarih, toplam tutar, KDV, kategori, işlem tipi
- Onay → İşlem olarak kaydet
- `ApiService.scanReceiptFile()` çağrısı

#### `settings_screen.dart`
- Tema seçici (Açık / Koyu / Sistem)
- Döviz seçici (TRY / USD / EUR)
- Çıkış yap

#### `manage_categories_screen.dart`
- Özel kategori ekleme (ad, ikon, tür)
- Kategori silme

### 6.7 Modeller

```dart
// User
User { int id, String fullName, String email, DateTime createdAt }

// Transaction
Transaction {
  int id, userId, categoryId
  double amount
  String type  // 'income' | 'expense'
  String? merchant, description
  DateTime transactionDate, createdAt
  Category category
  // Computed: bool isExpense, isIncome, String formattedAmount (TR format)
}

// Category
Category {
  int id
  String name
  String? iconName
  String type  // 'income' | 'expense'
}
```

### 6.8 Yardımcı Araçlar

#### `category_icons.dart`
40+ kategori → CupertinoIcon eşlemesi. `getCategoryIcon(String?)` → varsayılan tag ikonu

#### `thousand_separator_formatter.dart`
`ThousandSeparatorFormatter` (TextInputFormatter): `1234567` → `1.234.567`

---

## 7. Kritik İş Mantığı

### 7.1 Kimlik Doğrulama Akışı
1. Uygulama açılır → `tryAutoLogin()` → SharedPreferences'tan token
2. Token varsa → `/auth/me` çağır → `AuthProvider._user` doldur
3. Token yoksa → `LoginScreen` göster
4. Başarılı girişte → token kaydet → `TransactionProvider.loadData()` → `MainLayoutScreen`

### 7.2 Sayısal Format (Türkçe)
- Binlik ayraç: nokta (.)
- Ondalık ayraç: virgül (,)
- Örnek: `₺ 1.234,56`

### 7.3 Tekrarlayan İşlem Frekans Değerleri
Backend ve Flutter'da birebir eşleşmeli: `'Aylık'`, `'Haftalık'`, `'Yıllık'`

### 7.4 İşlem Tipleri
Backend'de sadece `'income'` ve `'expense'` var. Flutter'daki "Alacak" ve "Borç" tipleri frontend tarafında işlenir.

---

## 8. Yeni Eklenen Özellikler (Git Durumu)

Aşağıdaki dosyalar son commit sonrası eklendi (`git status`: untracked/modified):

### Yeni Backend Dosyaları
- `backend/routers/scan.py` — `/scan/upload` ve `/scan/base64` endpoint'leri
- `backend/services/image_processing.py` — OpenCV ön işleme
- `backend/services/ocr_service.py` — Tesseract OCR
- `backend/services/llm_parser.py` — Gemini + regex fallback
- `backend/services/receipt_pipeline.py` — Orchestrator

### Yeni Flutter Dosyaları
- `finasist/lib/screens/scan/scan_receipt_screen.dart` — Fiş tarama UI
- `finasist/lib/utils/category_icons.dart` — İkon eşleme

### Refaktör Edilen Yapı
Ekranlar düz yapıdan alt klasörlere taşındı:
- `screens/home_screen.dart` → `screens/home/home_screen.dart`
- `screens/login_screen.dart` → `screens/auth/login_screen.dart`
- ... (tüm ekranlar için aynı pattern)

---

## 9. Geliştirme Ortamı Kurulumu

### Backend Başlatma
```bash
cd backend
pip install -r requirements.txt
uvicorn main:app --reload
# → http://127.0.0.1:8000
# → Docs: http://127.0.0.1:8000/docs
```

### Gereksinimler
- PostgreSQL 16 çalışıyor olmalı (`finasist_db` veritabanı oluşturulmuş)
- Tesseract-OCR kurulu: `C:\Program Files\Tesseract-OCR\tesseract.exe`
- Tesseract Türkçe dil paketi (`tur.traineddata`)
- `.env` dosyası dolu

### Flutter Başlatma
```bash
cd finasist
flutter pub get
flutter run
```

### Veritabanı Başlangıç Verisi
```bash
cd backend
python seed_data.py   # Global kategoriler
python seed.py        # Test kullanıcısı (test@finasist.com / 123456)
```

---

## 10. Güvenlik Notları

- **JWT:** HS256, 60 dakika geçerlilik
- **CORS:** Şu an `allow_origins=["*"]` — prodüksiyonda kısıtlanmalı
- **Şifre:** bcrypt hash
- **Dosya Yükleme:** Max 10MB, sadece JPEG/PNG/WEBP
- **API Key:** Gemini anahtarı `.env`'de, git-ignore'da
- **Kullanıcı İzolasyonu:** Her sorgu `user_id` filtresi içerir

---

## 11. Mimari Desenler

| Desen | Nerede |
|---|---|
| Facade | `receipt_pipeline.py` — servis karmaşıklığını gizler |
| Strategy | OCR ön işleme — birden fazla strateji denenir, en iyi seçilir |
| Chain of Responsibility | LLM → Regex fallback zinciri |
| Provider (State Mgmt) | Flutter ChangeNotifier tabanlı |
| Repository | Provider'lar veri akışını yönetir |
| Dependency Injection | FastAPI `Depends()` (DB, auth) |
| Factory | `SessionLocal` DB session factory |
