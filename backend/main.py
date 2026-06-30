import logging
import os

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import JSONResponse
from dotenv import load_dotenv

from database import engine, Base
from routers import auth, transactions, categories, recurring, scan, advisor

load_dotenv()
logging.basicConfig(level=logging.INFO)

Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Finasist API",
    description="Yapay Zeka Destekli Finansal Danışman – Backend API",
    version="1.0.0",
)

# ─── Güvenlik: İstek Gövdesi Boyut Sınırı ───
# Content-Length header'ı erkenden kontrol edilir; aşırı büyük istekler
# (DoS amaçlı) gövde tamamen okunmadan reddedilir.
MAX_REQUEST_BODY_SIZE = 15 * 1024 * 1024  # 15 MB (10MB dosya + JSON/base64 ek yükü)


class MaxBodySizeMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        content_length = request.headers.get("content-length")
        if content_length and content_length.isdigit() and int(content_length) > MAX_REQUEST_BODY_SIZE:
            return JSONResponse(
                status_code=413,
                content={"detail": "İstek gövdesi çok büyük."},
            )
        return await call_next(request)


app.add_middleware(MaxBodySizeMiddleware)

# ─── Güvenlik: CORS ───
# Varsayılan olarak sadece localhost/127.0.0.1 (herhangi bir port) kabul edilir
# — Flutter web'in geliştirme sırasında kullandığı port her seferinde değişir.
# Üretimde gerçek domain'i ALLOWED_ORIGIN_REGEX ortam değişkeniyle belirtin.
ALLOWED_ORIGIN_REGEX = os.getenv(
    "ALLOWED_ORIGIN_REGEX",
    r"^https?://(localhost|127\.0\.0\.1)(:\d+)?$",
)

app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=ALLOWED_ORIGIN_REGEX,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Router'ları ekle
app.include_router(auth.router)
app.include_router(transactions.router)
app.include_router(categories.router)
app.include_router(recurring.router)
app.include_router(scan.router)
app.include_router(advisor.router)


@app.get("/", tags=["Genel"])
def root():
    return {
        "mesaj": "Finasist API çalışıyor 🚀",
        "docs": "/docs",
        "version": "1.0.0",
    }
