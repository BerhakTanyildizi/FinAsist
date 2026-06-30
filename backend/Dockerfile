# Finasist Backend — FastAPI + EasyOCR + Groq/Gemini
FROM python:3.11-slim

WORKDIR /app

# OpenCV / EasyOCR çalışma zamanı için gerekli sistem kütüphaneleri
RUN apt-get update && apt-get install -y --no-install-recommends \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender1 \
    libgomp1 \
    curl \
    && rm -rf /var/lib/apt/lists/*

# PyTorch'un CUDA'lı (çok büyük) sürümü yerine CPU-only sürümünü kur —
# EasyOCR zaten gpu=False ile çalışıyor, CUDA paketlerine hiç gerek yok.
# Bu adım image boyutunu ~3GB'tan ~1GB civarına indirir.
RUN pip install --no-cache-dir torch torchvision --index-url https://download.pytorch.org/whl/cpu

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8000

# Konteyner her başladığında: tabloları oluştur + varsayılan kategorileri
# (idempotent — zaten varsa atlar) ekle + sunucuyu başlat.
CMD ["sh", "-c", "python seed_data.py; uvicorn main:app --host 0.0.0.0 --port 8000"]
