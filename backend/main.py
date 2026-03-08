from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from database import engine, Base
from routers import auth, transactions

# Tabloları oluştur (ilk çalıştırmada)
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Finasist API",
    description="Yapay Zeka Destekli Finansal Danışman – Backend API",
    version="1.0.0",
)

# CORS — Flutter'dan gelen isteklere izin ver
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Router'ları ekle
app.include_router(auth.router)
app.include_router(transactions.router)


@app.get("/", tags=["Genel"])
def root():
    return {
        "mesaj": "Finasist API çalışıyor 🚀",
        "docs": "/docs",
        "version": "1.0.0",
    }
