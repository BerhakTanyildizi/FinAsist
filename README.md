# Finasist - Yapay Zeka Destekli Finansal Danışman

**TUBİTAK 2209-A Üniversite Öğrencileri Araştırma Projeleri Destekleme Programı**

Finasist, kullanıcıların gelir ve giderlerini takip etmesini, harcama alışkanlıklarını analiz etmesini ve yapay zeka destekli finansal öneriler almasını sağlayan bir mobil uygulamadır.

---

## Proje Yapısı

```
Tubitak 2209-A/
├── backend/              # FastAPI REST API
│   ├── main.py           # Uygulama giriş noktası
│   ├── database.py       # PostgreSQL bağlantısı
│   ├── models.py         # SQLAlchemy ORM modelleri
│   ├── schemas.py        # Pydantic doğrulama şemaları
│   ├── seed_data.py      # Varsayılan kategori verileri
│   ├── requirements.txt  # Python bağımlılıkları
│   ├── .env              # Ortam değişkenleri (git'e eklenmez)
│   └── routers/
│       ├── auth.py       # Kayıt, giriş, JWT token yönetimi
│       └── transactions.py  # Gelir/gider CRUD işlemleri
│
└── finasist/             # Flutter mobil uygulama
    └── lib/
        ├── main.dart     # Uygulama giriş noktası ve routing
        ├── models/       # Veri modelleri (User, Category, Transaction)
        ├── providers/    # State yönetimi (Auth, Transaction, Theme)
        ├── services/     # API iletişim katmanı
        ├── screens/      # Uygulama ekranları
        └── utils/        # Yardımcı araçlar
```

## Kullanılan Teknolojiler

### Backend
| Teknoloji | Versiyon | Açıklama |
|-----------|----------|----------|
| Python | 3.10+ | Programlama dili |
| FastAPI | 0.115.0 | REST API framework |
| PostgreSQL | 16 | İlişkisel veritabanı |
| SQLAlchemy | 2.0.30 | ORM (Object Relational Mapping) |
| Pydantic | 2.7.0 | Veri doğrulama ve serileştirme |
| python-jose | 3.3.0 | JWT token oluşturma ve doğrulama |
| bcrypt | 5.0.0 | Şifre hashleme |
| Uvicorn | 0.30.0 | ASGI sunucusu |

### Frontend (Mobil)
| Teknoloji | Versiyon | Açıklama |
|-----------|----------|----------|
| Flutter | 3.x | Cross-platform UI framework |
| Dart | 3.9+ | Programlama dili |
| Provider | 6.1.5 | State management |
| GoRouter | 17.1.0 | Sayfa yönlendirme |
| http | 1.6.0 | HTTP istemcisi |
| SharedPreferences | 2.5.4 | Yerel veri saklama (token) |
| fl_chart | 1.1.1 | Grafik ve pasta chart |
| Google Fonts | 8.0.2 | Tipografi (Inter font) |

---

## Kurulum

### Gereksinimler

- **Python 3.10+** - [python.org](https://www.python.org/downloads/)
- **PostgreSQL 16** - [postgresql.org](https://www.postgresql.org/download/)
- **Flutter SDK 3.x** - [flutter.dev](https://docs.flutter.dev/get-started/install)
- **Git** - [git-scm.com](https://git-scm.com/)

### 1. Projeyi Klonlayın

```bash
git clone https://github.com/KULLANICI_ADI/finasist.git
cd finasist
```

### 2. Backend Kurulumu

```bash
cd backend

# Sanal ortam oluştur ve aktif et
python -m venv venv

# Windows:
.\venv\Scripts\activate
# macOS/Linux:
source venv/bin/activate

# Bağımlılıkları yükle
pip install -r requirements.txt
```

### 3. PostgreSQL Veritabanı

pgAdmin veya psql ile veritabanını oluşturun:

```sql
CREATE DATABASE finasist_db;
```

### 4. Ortam Değişkenleri

`backend/` klasöründe `.env` dosyası oluşturun:

```env
DATABASE_URL=postgresql://postgres:SIFRENIZ@localhost:5432/finasist_db
SECRET_KEY=kendi-gizli-anahtariniz
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=60
```

> **Not:** `SIFRENIZ` kısmını kendi PostgreSQL şifrenizle değiştirin.

### 5. Veritabanı Tablolarını Oluştur ve Kategorileri Ekle

```bash
# Tabloları oluşturur (ilk çalıştırmada otomatik)
python -c "from database import engine, Base; from models import *; Base.metadata.create_all(bind=engine)"

# Varsayılan kategorileri ekle
python seed_data.py
```

### 6. Backend'i Başlat

```bash
uvicorn main:app --host 0.0.0.0 --port 8000
```

API dokümantasyonu: [http://localhost:8000/docs](http://localhost:8000/docs)

### 7. Flutter Kurulumu

```bash
cd finasist

# Bağımlılıkları yükle
flutter pub get

# Uygulamayı çalıştır
flutter run
```

> **API Adresi:** `lib/services/api_service.dart` dosyasındaki `_baseUrl` değişkenini ortamınıza göre ayarlayın:
> - Android Emülatör: `http://10.0.2.2:8000`
> - Web (Chrome): `http://localhost:8000`
> - Fiziksel Cihaz: `http://BILGISAYAR_IP:8000`

---

## API Endpoint'leri

### Kimlik Doğrulama
| Metot | Endpoint | Açıklama |
|-------|----------|----------|
| POST | `/auth/register` | Yeni kullanıcı kaydı |
| POST | `/auth/login` | Giriş yap, JWT token al |
| GET | `/auth/me` | Giriş yapan kullanıcı bilgileri |

### İşlemler (JWT gerekli)
| Metot | Endpoint | Açıklama |
|-------|----------|----------|
| GET | `/transactions/` | Tüm işlemleri listele |
| POST | `/transactions/` | Yeni gelir/gider ekle |
| GET | `/transactions/{id}` | Tek işlem detayı |
| PUT | `/transactions/{id}` | İşlemi güncelle |
| DELETE | `/transactions/{id}` | İşlemi sil |

---

## Veritabanı Şeması

```
users                    categories              transactions
├── id (PK)              ├── id (PK)             ├── id (PK)
├── full_name            ├── name                ├── user_id (FK → users)
├── email (UNIQUE)       ├── icon_name           ├── category_id (FK → categories)
├── hashed_password      └── type                ├── amount
└── created_at               (income/expense)    ├── type (income/expense)
                                                 ├── merchant
                                                 ├── description
                                                 ├── transaction_date
                                                 └── created_at
```

---

## Uygulama Ekranları

| Ekran | Açıklama |
|-------|----------|
| Giriş / Kayıt | JWT tabanlı kimlik doğrulama |
| Ana Sayfa (Özet) | Bakiye, gelir/gider özeti, son işlemler, AI tavsiyeleri |
| İşlem Ekle | Gelir veya gider kaydı (kategori, tutar, işyeri, açıklama, tarih) |
| İşlem Detay | Detay görüntüleme, düzenleme ve silme |
| Raporlar | Kategori bazlı pasta grafik, harcama analizi |
| Fiş Tara | Fatura/fiş tarama (yapay zeka entegrasyonu planlanıyor) |
| Profil & Ayarlar | Kullanıcı bilgileri, tema değiştirme, çıkış |

---

## Lisans

Bu proje TUBİTAK 2209-A programı kapsamında geliştirilmiştir.
